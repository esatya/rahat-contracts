//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;
import './RahatERC20.sol';
import './RahatERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Rahat is AccessControl,ERC1155Holder {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;

	//***** Events *********//
	event Claimed(address indexed vendor, uint256 indexed phone, uint256 amount);
	event ClaimApproved(address indexed vendor, uint256 indexed phone, uint256 amount);
	event Issued(bytes32 indexed projectId, uint256 indexed phone, uint256 amount);
	event ClaimAcquired(address indexed vendor, uint256 indexed beneficiary,uint256 amount);
	event ClaimAcquired(uint256 indexed tokenId,address indexed vendor, uint256 indexed beneficiary,uint256 amount);
	event InvalidSignature(bytes signature,bytes32 digest, address expectedSigner,address recoveredSigner);

	//event BalanceAdjusted(uint256 indexed phone, uint256 amount, string reason);

	//***** Constant Variables (Roles) *********//
	bytes32 public constant SERVER_ROLE = keccak256('SERVER');
	bytes32 public constant VENDOR_ROLE = keccak256('VENDOR');
	bytes32 public constant MANAGER_ROLE = keccak256('MANAGER');
	bytes32 public constant MOBILIZER_ROLE = keccak256('MOBILIZER');
	bytes32 public constant ISSUE_TOKEN = keccak256("issueToken");
	bytes32 public constant CREATE_CLAIM = keccak256("createClaim");
	bytes32 public constant GET_TOKENS_FROM_CLAIM = keccak256("getTokensFromClaim");



    mapping(address => uint) public nonces; //delegated users nonces


	//***** Variables (State) *********//
	//AidToke public tokenContract;
    RahatERC20 public erc20;
    RahatERC1155 public erc1155;
	/// @notice track balances of each beneficiary phone
	mapping(uint256 => uint256) public erc20Balance;
	mapping(uint256 =>mapping(uint256 => uint256)) public erc1155Balance;


	/// @notice track projectBalances
	//bytes32[] public projectId;
	EnumerableSet.Bytes32Set private projectId;
	mapping(bytes32 => uint256) remainingProjectErc20Balances;
	mapping(bytes32 =>mapping(uint256 => uint256)) remainingProjectErc1155Balances;
	mapping(bytes32 => EnumerableSet.AddressSet) projectMobilizers;
  mapping(address => EnumerableSet.Bytes32Set) mobilizerProjects;



	struct claim {
		uint256 amount;
		bytes32 otpHash;
		bool isReleased;
		uint256 date;
	}
	/// @dev vendorAddress => phone => claim
	mapping(address => mapping(bytes32 => claim)) public recentERC20Claims;
	mapping(address => mapping(bytes32 => mapping(uint256 => claim))) public recentERC1155Claims;

	//***** Constructor *********//
	constructor(RahatERC20 _erc20, RahatERC1155 _erc1155, address _admin) {
		_setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
		_setRoleAdmin(SERVER_ROLE, DEFAULT_ADMIN_ROLE);
		_setRoleAdmin(VENDOR_ROLE, DEFAULT_ADMIN_ROLE);
		grantRole(SERVER_ROLE, msg.sender);
		erc20 = _erc20;
		erc1155 = _erc1155;
	}
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,ERC1155Receiver) returns (bool) {
    return super.supportsInterface(interfaceId);
}


	//***** Modifiers *********//
	modifier OnlyServer() {
		require(hasRole(SERVER_ROLE, msg.sender), 'RAHAT: Sender must be an authorized server');
		_;
	}
	modifier OnlyAdmin {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'RAHAT: Sender must be an admin.');
		_;
	}
	modifier IsBeneficiary(uint256 _phone) {
	    bytes32 _benId = findHash(_phone);
		require(erc20Balance[_phone] != 0, 'RAHAT: No any token was issued to this number');
		_;
	}
	modifier OnlyVendor {
		require(hasRole(VENDOR_ROLE, msg.sender), 'RAHAT: Sender Must be a registered vendor.');
		_;
	}
	modifier OnlyAdminOrMobilizer {
	    require((hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MOBILIZER_ROLE, msg.sender)), 'RAHAT: Sender Must be a registered Admin Or Mobilizer.');
      _;
	}

	//***** Methods *********//
	//Access Control Management
	/// @notice add admin of the this contract
	/// @param _account address of the new admin
	function addAdmin(address _account) public {
		grantRole(DEFAULT_ADMIN_ROLE, _account);
	}

	/// @notice add server account for this contract
	/// @param _account address of the new server account
	function addServer(address _account) public {
		grantRole(SERVER_ROLE, _account);
	}

	/// @notice add vendors
	/// @param _account address of the new vendor
	function addVendor(address _account) public {
		grantRole(VENDOR_ROLE, _account);
	}

    	/// @notice add vendors
	/// @param _account address of the new vendor
	function addMobilizer(address _account,bytes32 _projectId) public {
		grantRole(MOBILIZER_ROLE, _account);
		projectMobilizers[_projectId].add(_account);
		mobilizerProjects[_account].add(_projectId);
	}

	function suspendMobilizer() public {

	}
	function suspendVendor() public {
		
	}
	//Beneficiary Management
	/// @notice suspend the benficiary by deducting all the balance beneficiary owns
	/// @param _phone phone number of the Beneficiary
	/// @param _projectId projectId of the beneficiary
	function suspendBeneficiary(uint256 _phone , bytes32 _projectId) public OnlyServer IsBeneficiary(_phone) {
	  //  bytes32 _benId = findHash(_phone);

		uint256 _balance = erc20Balance[_phone];
		remainingProjectErc20Balances[_projectId] += _balance;
		adjustTokenDeduct(_phone, _balance);
	}

	/// @notice adds the token from beneficiary
	function adjustTokenAdd(uint256 _phone, uint256 _amount) public OnlyAdmin {
	   // bytes32 _benId = findHash(_phone);
		erc20Balance[_phone] = erc20Balance[_phone] + _amount;
		//emit BalanceAdjusted(_phone, _amount, _reason);
	}

	/// @notice deducts the token from beneficiary
	function adjustTokenDeduct(uint256 _phone, uint256 _amount) public OnlyAdmin IsBeneficiary(_phone) {
	    //bytes32 _benId = findHash(_phone);
		erc20Balance[_phone] = erc20Balance[_phone] - _amount;
		//emit BalanceAdjusted(_phone, _amount, _reason);
	}
	
	
	
	/// @notice adds the token from beneficiary
	function adjustTokenAdd(uint256 _phone, uint256 _amount,uint256 _tokenId) public OnlyAdmin {
	   // bytes32 _benId = findHash(_phone);
		erc1155Balance[_phone][_tokenId] += _amount;
		//emit BalanceAdjusted(_phone, _amount, _reason);
	}

	/// @notice deducts the token from beneficiary
	function adjustTokenDeduct(uint256 _phone, uint256 _amount,uint256 _tokenId) public OnlyAdmin IsBeneficiary(_phone) {
	  //  bytes32 _benId = findHash(_phone);
		erc1155Balance[_phone][_tokenId] -= _amount;
		//emit BalanceAdjusted(_phone, _amount, _reason);
	}

	/// @notice creates a project.
	/// @notice called by rahatdmin contract
	/// @param _projectId Id of the project to assign budget
	/// @param _projectCapital amount of budget to be assigned to project
	function addProject(bytes32 _projectId, uint256 _projectCapital) external {
		projectId.add(_projectId);
		remainingProjectErc20Balances[_projectId] = _projectCapital;
	}

	/// @notice update a project balance.
	/// @notice called by rahatdmin contract
	/// @param _projectId Id of the project to assign budget
	/// @param _projectCapital amount of budget to be added to project
	function updateProjectBudget(bytes32 _projectId, uint256 _projectCapital) external {
		remainingProjectErc20Balances[_projectId] += _projectCapital;
	}
	
	/// @notice update a project balance.
	/// @notice called by rahatdmin contract
	/// @param _projectId Id of the project to assign budget
	/// @param _projectCapital amount of budget to be added to project
	/// @param tokenId ERC1155 token id
	function updateProjectBudget(bytes32 _projectId, uint256 _projectCapital,uint256 tokenId) external {
		remainingProjectErc1155Balances[_projectId][tokenId] += _projectCapital;
	}

	/// @notice get the current balance of project
	function getProjectBalance(bytes32 _projectId) external view returns (uint256 _balance) {
		return remainingProjectErc20Balances[_projectId];
	}
	
		/// @notice get the current balance of project
	function getProjectBalance(bytes32 _projectId, uint256 tokenId) external view returns (uint256 _balance) {
		return remainingProjectErc1155Balances[_projectId][tokenId];
	}
	
	function verifyVendor(bytes32 _hash, bytes memory _signature) internal view returns(address){
	    address _signer = _hash.recover(_signature);
	    require(hasRole(VENDOR_ROLE,_signer),"Signer should be Mobilizer");
	    return _signer;
	}
	
	function verifyMobilizer(bytes32 _hash, bytes memory _signature) internal view returns (address){
	     address _signer = _hash.recover(_signature);
	    require(hasRole(MOBILIZER_ROLE,_signer),"Signer should be Mobilizer");
	    return _signer;

	}

	/// @notice Issue tokens to beneficiary
	/// @param _projectId Id of the project beneficiary is involved in
	/// @param _phone phone number of the beneficiary
	/// @param _amount Amount of token to be assigned to beneficiary
	function issueERC20ToBeneficiary(
		string memory _projectId,
		uint256 _phone,
		uint256 _amount
	) public OnlyAdmin {
		bytes32 _id = findHash(_projectId);
		require(remainingProjectErc20Balances[_id] >= _amount, 'RAHAT: Amount is greater than remaining Project Budget');
		remainingProjectErc20Balances[_id] -= _amount;
		adjustTokenAdd(_phone, _amount);

		emit Issued(_id, _phone, _amount);
	}
	
	/// @notice Issue ERC20 tokens to beneficiary
	/// @param _projectId Id of the project beneficiary is involved in
	/// @param _phone phone number of the beneficiary
	/// @param _amount Amount of token to be assigned to beneficiary
	/// @param _tokenId ERC1155 TokenId
	function issueERC1155ToBeneficiary(
		string memory _projectId,
		uint256 _phone,
		uint256 _amount,
		uint256 _tokenId
	) public OnlyAdmin {
		bytes32 _id = findHash(_projectId);
		require(remainingProjectErc1155Balances[_id][_tokenId] >= _amount, 'RAHAT: Amount is greater than remaining Project Budget');
		remainingProjectErc1155Balances[_id][_tokenId] -= _amount;
		adjustTokenAdd(_phone, _amount,_tokenId);

		emit Issued(_id, _phone, _amount);
	}
	
	/// @notice Issue ERC20 to beneficiary
	/// @param _signer Address of the mobilizer/caller who is issuing tokens
	/// @param _signature Signature generated by signing {to,functionSig,nonce,projectId,phone,amount} through mobilizer/caller wallet
	/// @param _projectId Id of the project beneficiary is involved in
	/// @param _phone phone number of the beneficiary
	/// @param _amount Amount of token to be assigned to beneficiary
	function delegate_issueERC20ToBeneficiary(
	    address _signer,
	    bytes memory _signature,
		string memory _projectId,
		uint256 _phone,
		uint256 _amount
	) public {
	    bytes32 _hash = keccak256(abi.encodePacked(address(this), ISSUE_TOKEN, nonces[_signer], _projectId, _phone,_amount)); //data-hash of toke issuance = {to,functionSig,nonce,projectId,phone,amount}
        address recoveredSigner = verifyMobilizer(_hash,_signature);
        require(recoveredSigner == _signer,'Signature did not matched with signer');
        nonces[_signer]++;

        
		bytes32 _id = findHash(_projectId);
		require(remainingProjectErc20Balances[_id] >= _amount, 'RAHAT: Amount is greater than remaining Project Budget');
		remainingProjectErc20Balances[_id] -= _amount;
		adjustTokenAdd(_phone, _amount);

		emit Issued(_id, _phone, _amount);
	}
	
		
	/// @notice Issue ERC1155 tokens to beneficiary
	/// @param _signer Address of the mobilizer/caller who is issuing tokens
	/// @param _signature Signature generated by signing {to,functionSig,nonce,projectId,phone,amount} through mobilizer/caller wallet
	/// @param _projectId Id of the project beneficiary is involved in
	/// @param _phone phone number of the beneficiary
	/// @param _amount Amount of token to be assigned to beneficiary
	/// @param _tokenId ERC1155 TokenId
	function delegate_issueERC1155ToBeneficiary(
	    address _signer,
	    bytes memory _signature,
		string memory _projectId,
		uint256 _phone,
		uint256 _amount,
		uint256 _tokenId
	) public {
	    bytes32 _hash = keccak256(abi.encodePacked(address(this), ISSUE_TOKEN, nonces[_signer], _projectId, _phone,_amount)); //data-hash of toke issuance = {to,functionSig,nonce,projectId,phone,amount}
        address recoveredSigner = verifyMobilizer(_hash,_signature);
        require(recoveredSigner == _signer,'Signature did not matched with signer');
        nonces[_signer]++;

        
		bytes32 _id = findHash(_projectId);
		require(remainingProjectErc1155Balances[_id][_tokenId] >= _amount, 'RAHAT: Amount is greater than remaining Project Budget');
		remainingProjectErc1155Balances[_id][_tokenId] -= _amount;
		adjustTokenAdd(_phone, _amount,_tokenId);

		emit Issued(_id, _phone, _amount);
	}

	/// @notice Issue tokens to beneficiary in bulk
	/// @param _projectId Id of the project beneficiary is involved in
	/// @param _phone array of phone number of the beneficiary
	/// @param _amount array of Amount of token to be assigned to beneficiary
	function issueBulkToken(
		string memory _projectId,
		uint256[] memory _phone,
		uint256[] memory _amount
	) public OnlyAdmin {
		require(_phone.length == _amount.length, 'RAHAT: Invalid input arrays of Phone and Amount');
		uint256 i;
		uint256 sum = getArraySum(_amount);
		bytes32 _id = findHash(_projectId);

		require(remainingProjectErc20Balances[_id] >= sum, 'RAHAT: Amount is greater than remaining Project Budget');

		for (i = 0; i < _phone.length; i++) {
			issueERC20ToBeneficiary(_projectId, _phone[i], _amount[i]);
		}
	}

	/// @notice request a token to beneficiary by vendor
	/// @param _phone Phone number of beneficiary to whom token is requested
	/// @param _tokens Number of tokens to request
	function createERC20Claim(uint256 _phone, uint256 _tokens) public IsBeneficiary(_phone) OnlyVendor {
	    bytes32 _benId = findHash(_phone);
		require(erc20Balance[_phone] >= _tokens, 'RAHAT: Amount requested is greater than beneficiary balance.');
		claim storage ac = recentERC20Claims[msg.sender][_benId];
		ac.isReleased = false;
		ac.amount = _tokens;
		ac.date = block.timestamp;
		emit Claimed(tx.origin, _phone, _tokens);
	}
	
	///@dev claim tokens from the beneficiary by vendor
	///@param _phone identity of the beneficiary
	///@param _amount amaount of ERC1155 tokens to request
	///@param _tokenId ERC1155 token id
	function createERC1155Claim(uint256 _phone, uint256 _amount, uint256 _tokenId) public OnlyVendor {
	    bytes32 _benId = findHash(_phone);
		require(erc1155Balance[_phone][_tokenId] >= _amount, 'RAHAT: Amount requested is greater than beneficiary balance.');
		claim storage ac = recentERC1155Claims[msg.sender][_benId][_tokenId];
		ac.isReleased = false;
		ac.amount = _amount;
		ac.date = block.timestamp;
		emit Claimed(tx.origin, _phone, _amount);
	}
	
	///@dev delegate a createClaim transaction for ERC20
	///@param _signer address of vendor/caller of createClaim
	/// @param _signature Signature generated by signing {to,functionSig,nonce,projectId,phone,amount} through vendor/caller wallet
	/// @param _phone identity of benficiary
	/// @param _amount amount of token to be claimed
	function delegate_createERC20Claim(address _signer,bytes memory _signature,uint256 _phone, uint256 _amount) public {
	    bytes32 _hash = keccak256(abi.encodePacked(address(this), CREATE_CLAIM, nonces[_signer], _phone,_amount)); //data-hash of toke issuance = {to,functionSig,nonce,projectId,phone,amount}
        address recoveredSigner = verifyVendor(_hash,_signature);
        require(recoveredSigner == _signer,'Signature did not matched with signer');
        nonces[_signer]++;

    bytes32 _benId = findHash(_phone);
		require(erc20Balance[_phone] >= _amount, 'RAHAT: Amount requested is greater than beneficiary balance.');
		claim storage ac = recentERC20Claims[_signer][_benId];
		ac.isReleased = false;
		ac.amount = _amount;
		ac.date = block.timestamp;
		emit Claimed(tx.origin, _phone, _amount);
	    
	}
	

	///@dev delegate a createClaim transaction for ERC20
	///@param _signer address of vendor/caller of createClaim
	/// @param _signature Signature generated by signing {to,functionSig,nonce,projectId,phone,amount} through vendor/caller wallet
	/// @param _phone identity of benficiary
	/// @param _amount amount of token to be claimed
	/// @param _tokenId ERC1155 tokenId
	function delegate_createERC1155Claim(address _signer,bytes memory _signature,uint256 _phone, uint256 _amount, uint256 _tokenId) public {
	     bytes32 _hash = keccak256(abi.encodePacked(address(this), CREATE_CLAIM, nonces[_signer], _phone,_amount,_tokenId)); //data-hash of toke issuance = {to,functionSig,nonce,projectId,phone,amount}
        address recoveredSigner = verifyVendor(_hash,_signature);
        require(recoveredSigner == _signer,'Signature did not matched with signer');
        nonces[_signer]++;
	    
	     bytes32 _benId = findHash(_phone);
		require(erc1155Balance[_phone][_tokenId] >= _amount, 'RAHAT: Amount requested is greater than beneficiary balance.');
		claim storage ac = recentERC1155Claims[_signer][_benId][_tokenId];
		ac.isReleased = false;
		ac.amount = _amount;
		ac.date = block.timestamp;
		emit Claimed(tx.origin, _phone, _amount);
	}
	



	/// @notice Approve the requested claim from serverside and set the otp hash
	/// @param _vendor Address of the vendor who requested the token from beneficiary
	/// @param _phone Phone number of the beneficiary, to whom token request was sent
	/// @param _otpHash Hash of OTP sent to beneficiary by server
	/// @param _timeToLive Validity of OTP in seconds
	function approveERC20Claim(
		address _vendor,
		uint256 _phone,
		bytes32 _otpHash,
		uint256 _timeToLive
	) public IsBeneficiary(_phone) OnlyServer {
	    bytes32 _benId = findHash(_phone);
		claim storage ac = recentERC20Claims[_vendor][_benId];
		require(ac.date != 0, 'RAHAT: Claim has not been created yet');
		require(_timeToLive <= 86400, 'RAHAT:Time To Live should be less than 24 hours');
		require(block.timestamp <= ac.date + 86400, 'RAHAT: Claim is older than 24 hours');
		require(!ac.isReleased, 'RAHAT: Claim has already been released.');
		ac.otpHash = _otpHash;
		ac.isReleased = true;
		ac.date = block.timestamp + _timeToLive;
		emit ClaimApproved(_vendor, _phone, ac.amount);
	}
	
	/// @notice Approve the requested claim from serverside and set the otp hash
	/// @param _vendor Address of the vendor who requested the token from beneficiary
	/// @param _phone Phone number of the beneficiary, to whom token request was sent
	/// @param _otpHash Hash of OTP sent to beneficiary by server
	/// @param _timeToLive Validity of OTP in seconds
	/// @param _tokenId ERC1155 tokenId

	function approveERC1155Claim(
		address _vendor,
		uint256 _phone,
		bytes32 _otpHash,
		uint256 _timeToLive,
		uint256 _tokenId
	) public  OnlyServer {
	    bytes32 _benId = findHash(_phone);
		claim storage ac = recentERC1155Claims[_vendor][_benId][_tokenId];
		require(ac.date != 0, 'RAHAT: Claim has not been created yet');
		require(_timeToLive <= 86400, 'RAHAT:Time To Live should be less than 24 hours');
		require(block.timestamp <= ac.date + 86400, 'RAHAT: Claim is older than 24 hours');
		require(!ac.isReleased, 'RAHAT: Claim has already been released.');
		ac.otpHash = _otpHash;
		ac.isReleased = true;
		ac.date = block.timestamp + _timeToLive;
		emit ClaimApproved(_vendor, _phone, ac.amount);
	}

	/// @notice Retrieve tokens that was requested to beneficiary by entering OTP
	/// @param _phone Phone Number of the beneficiary, to whom token request was sent
	/// @param _otp OTP sent by the server
	function getERC20FromClaim(uint256 _phone, string memory _otp) public IsBeneficiary(_phone) OnlyVendor {
	    bytes32 _benId = findHash(_phone);
		claim storage ac = recentERC20Claims[msg.sender][_benId];
		require(ac.isReleased, 'RAHAT: Claim has not been released.');
		require(ac.date >= block.timestamp, 'RAHAT: Claim has already expired.');
		bytes32 otpHash = findHash(_otp);
		require(recentERC20Claims[msg.sender][_benId].otpHash == otpHash, 'RAHAT: OTP did not match.');
		erc20Balance[_phone] -= ac.amount;
		uint256 amt = ac.amount;
		ac.isReleased = false;
		ac.amount = 0;
		ac.date = 0;
	    erc20.transfer(msg.sender, amt);
	    emit ClaimAcquired(msg.sender,_phone,amt);

	}
	
	/// @notice Retrieve tokens that was requested to beneficiary by entering OTP
	/// @param _phone Phone Number of the beneficiary, to whom token request was sent
	/// @param _otp OTP sent by the server
	/// @param _tokenId ERC1155 tokenId
	function getERC1155FromClaim(uint256 _phone, string memory _otp,uint256 _tokenId) public OnlyVendor {
	    bytes32 _benId = findHash(_phone);
		claim storage ac = recentERC1155Claims[msg.sender][_benId][_tokenId];
		require(ac.isReleased, 'RAHAT: Claim has not been released.');
		require(ac.date >= block.timestamp, 'RAHAT: Claim has already expired.');
		bytes32 otpHash = findHash(_otp);
		require(recentERC1155Claims[msg.sender][_benId][_tokenId].otpHash == otpHash, 'RAHAT: OTP did not match.');
		adjustTokenDeduct(_phone,ac.amount,_tokenId);
		uint256 amt = ac.amount;
		ac.isReleased = false;
		ac.amount = 0;
		ac.date = 0;
		erc1155.safeTransferFrom(address(this),msg.sender,_tokenId, amt,'');
		emit ClaimAcquired(_tokenId,msg.sender,_phone,amt);
	}
	
	
	///@dev delegates getERC20FromClaim for vendors/callers
    ///@param _signer address of vendor/caller of getERC20FromClaim
	/// @param _signature Signature generated by signing {to,functionSig,nonce,projectId,phone,amount} through vendor/caller wallet
	/// @param _phone Phone Number of the beneficiary, to whom token request was sent
	/// @param _otp OTP sent by the server
	function delegate_getERC20FromClaim(address _signer,bytes memory _signature,uint256 _phone, string memory _otp) public IsBeneficiary(_phone) {
	    
	    bytes32 _hash = keccak256(abi.encodePacked(address(this), CREATE_CLAIM, nonces[_signer], _phone,_otp)); //data-hash of toke issuance = {to,functionSig,nonce,projectId,phone,amount}
        address recoveredSigner = verifyVendor(_hash,_signature);
        require(recoveredSigner == _signer,'Signature did not matched with signer');
        nonces[_signer]++;
	    
	    bytes32 _benId = findHash(_phone);
		claim storage ac = recentERC20Claims[msg.sender][_benId];
		require(ac.isReleased, 'RAHAT: Claim has not been released.');
		require(ac.date >= block.timestamp, 'RAHAT: Claim has already expired.');
		bytes32 otpHash = findHash(_otp);
		require(recentERC20Claims[msg.sender][_benId].otpHash == otpHash, 'RAHAT: OTP did not match.');
		erc20Balance[_phone] -= ac.amount;
		uint256 amt = ac.amount;
		ac.isReleased = false;
		ac.amount = 0;
		ac.date = 0;
	    erc20.transfer(msg.sender, amt);
	    emit ClaimAcquired(msg.sender,_phone,amt);

	}
	
	///@dev delegates getERC20FromClaim for vendors/callers
    ///@param _signer address of vendor/caller of getERC1155FromClaim
	/// @param _signature Signature generated by signing {to,functionSig,nonce,projectId,phone,amount} through vendor/caller wallet
	/// @param _phone Phone Number of the beneficiary, to whom token request was sent
	/// @param _otp OTP sent by the server
	/// @param _tokenId ERC1155 tokenId
	function delegate_getTokensFromClaim(address _signer,bytes memory _signature,uint256 _phone, string memory _otp,uint256 _tokenId) public {
	    bytes32 _hash = keccak256(abi.encodePacked(address(this), CREATE_CLAIM, nonces[_signer], _phone,_otp,_tokenId)); //data-hash of toke issuance = {to,functionSig,nonce,projectId,phone,amount}
        address recoveredSigner = verifyVendor(_hash,_signature);
        require(recoveredSigner == _signer,'Signature did not matched with signer');
        nonces[_signer]++;
	    
	    bytes32 _benId = findHash(_phone);
		claim storage ac = recentERC1155Claims[msg.sender][_benId][_tokenId];
		require(ac.isReleased, 'RAHAT: Claim has not been released.');
		require(ac.date >= block.timestamp, 'RAHAT: Claim has already expired.');
		bytes32 otpHash = findHash(_otp);
		require(recentERC1155Claims[msg.sender][_benId][_tokenId].otpHash == otpHash, 'RAHAT: OTP did not match.');
		adjustTokenDeduct(_phone,ac.amount,_tokenId);
		uint256 amt = ac.amount;
		ac.isReleased = false;
		ac.amount = 0;
		ac.date = 0;
		erc1155.safeTransferFrom(address(this),msg.sender,_tokenId, amt,'');
		emit ClaimAcquired(_tokenId,msg.sender,_phone,amt);
	}

	/// @notice generates the hash of the given string
	/// @param _data String of which hash is to be generated
	function findHash(string memory _data) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
	}
	
	/// @notice generates the hash of the given string
	/// @param _data String of which hash is to be generated
	function findHash(uint256 _data) public pure returns (bytes32) {
	    
		return keccak256(abi.encodePacked(_data.toString()));
	}

	/// @notice Generates the sum of all the integers in array
	/// @param _array Array of uint
	function getArraySum(uint256[] memory _array) public pure returns (uint256 sum) {
		sum = 0;
		for (uint256 i = 0; i < _array.length; i++) {
			sum += _array[i];
		}
		return sum;
	}
}
