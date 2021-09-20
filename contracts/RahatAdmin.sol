//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import './RahatERC20.sol';
import './RahatERC1155.sol';
import './Rahat.sol';

/// @title Rahat Admin contract - owns all the tokens initially minted
/// @author Rumsan Associates
/// @notice You can use this contract to manage Rahat tokens and projects
/// @dev All function calls are only executed by contract owner
contract RahatAdmin is ERC1155Holder {
	event ProjectBudgetUpdated(bytes32 indexed projectId, uint256 projectCapital,string tag);
	event Minted(bool success);

	// uint256 public mintData ;
	// bool public mintSuccess =false;

    RahatERC20 public erc20;
    RahatERC1155 public erc1155;
	Rahat public rahatContract;
	mapping(address => bool) public owner;

	/// @notice list of projects
	bytes32[] public projectId;

	/// @notice check if projectId exists or not;
	mapping(bytes32 => bool) public projectExists;

	/// @notice assign budgets to project
	mapping(bytes32 => uint256) public projectCapital;
	mapping(bytes32 => mapping(uint256 => uint256)) projectItemCapital; // projectId => tokenId => balance

	modifier OnlyOwner {
		require(owner[msg.sender], 'RAHAT_ADMIN: Only Admin can execute this transaction');
		_;
	}

	modifier CheckProject(string memory _projectId) {
		bytes32 _id = findHash(_projectId);
		if (projectExists[_id]) {
			_;
		} else {
			projectId.push(_id);
			projectExists[_id] = true;
			_;
		}
	}
	
	
	
	

	/// @notice All the supply is allocated to this contract
	/// @dev deploys AidToken and Rahat contract by sending supply to this contract

	constructor(
	    RahatERC20 _erc20, 
	    RahatERC1155 _erc1155,
		Rahat _rahatContract,
		uint256 _intitialSupply,
		address _admin
	) {
		erc20 = _erc20;
		erc1155 = _erc1155;
		rahatContract = _rahatContract;
		erc20.mintToken(address(this), _intitialSupply);
		//(bool success, bytes memory result) = address(_tokenContract).call(abi.encodeWithSignature("mintToken(address, uint256)", address(this), _intitialSupply));
		//mintSuccess = success;
		//mintData = abi.decode(result,(uint256));

		owner[_admin] = true;
	}

    
	/// @notice allocate token to projects
	/// @dev Allocates token to the given projectId, Creates project and transfer tokens to Rahat contract.
	/// @param _projectId Unique Id of Project
	/// @param _projectCapital Budget Allocated to project
	function setProjectBudget(string memory _projectId, uint256 _projectCapital)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
		bytes32 _id = findHash(_projectId);
		projectCapital[_id] += _projectCapital;
		erc20.transfer(address(rahatContract), _projectCapital);
		rahatContract.updateProjectBudget(_id, _projectCapital);

		emit ProjectBudgetUpdated(_id, _projectCapital,'add');
	}
	
		function setProjectBudget(string memory _projectId, uint256 _projectCapital,uint256 tokenId)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
	    require(erc1155.exists(tokenId),"RahatAdmin: Token with given id doesn't exists");
	    
		bytes32 _id = findHash(_projectId);
		projectItemCapital[_id][tokenId] += _projectCapital;
		erc1155.safeTransferFrom(address(this),address(rahatContract),tokenId, _projectCapital,'');
		rahatContract.updateProjectBudget(_id, _projectCapital,tokenId);

		emit ProjectBudgetUpdated(_id, _projectCapital,'add');
	}
	
		function revokeProjectBudget(string memory _projectId, uint256 _projectCapital)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
		bytes32 _id = findHash(_projectId);
		projectCapital[_id] -= _projectCapital;
	//	tokenContract.transfer(address(rahatContract), _projectCapital);
		//rahatContract.updateProjectBudget(_id, _projectCapital);

		emit ProjectBudgetUpdated(_id, _projectCapital,'deduct');
	}
	
		function revokeProjectBudget(string memory _projectId, uint256 _projectCapital,uint256 tokenId)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
	    require(erc1155.exists(tokenId),"RahatAdmin: Token with given id doesn't exists");
	    
		bytes32 _id = findHash(_projectId);
		projectItemCapital[_id][tokenId] += _projectCapital;
	//	tokenContract.safeTransferFrom(address(this),address(rahatContract),tokenId, _projectCapital,'');
	//	rahatContract.updateProjectBudget(_id, _projectCapital,tokenId);

		emit ProjectBudgetUpdated(_id, _projectCapital,'deduct');
	}
	
	function suspendProject(string memory _projectId) public OnlyOwner CheckProject(_projectId){
	    
	}

	/// @notice get the current balance of project
	/// @param _projectId Unique Id of project
	function getProjectBalance(string memory _projectId) public view OnlyOwner returns (uint256 _balance) {
		bytes32 _id = findHash(_projectId);
		require(projectExists[_id], 'RAHAT_ADMIN: Invalid ProjectID');
		return (rahatContract.getProjectBalance(_id));
	}
	function getProjectBalance(string memory _projectId,uint256 tokenId) public view OnlyOwner returns (uint256 _balance) {
		bytes32 _id = findHash(_projectId);
		require(projectExists[_id], 'RAHAT_ADMIN: Invalid ProjectID');
		return (rahatContract.getProjectBalance(_id,tokenId));
	}

	// TODO:   //SANTOSH - Can't we take default error of transferring?
	/// @notice take out token from this contract
	/// @param _amount Amount to withdraw token from this contract
	function withdrawToken(uint256 _amount) public OnlyOwner {
		require(erc20.transfer(msg.sender, _amount), 'RAHAT_ADMIN: Error while calling token contract');
	}

	/// @notice mint new tokens
	/// @param _address address to send the minted tokens
	/// @param _amount Amount of token to Mint
	function mintToken(address _address, uint256 _amount) public OnlyOwner {
		erc20.mintToken(_address, _amount);
	}
	
	function mintItem(string memory _name,
		string memory _symbol,uint256 _amount) public OnlyOwner {
		    erc1155.mintItem(_name,_symbol,_amount);
		}

	/// @notice Add an account to the owner role. Restricted to owners.
	function addOwner(address _account) public OnlyOwner {
		owner[_account] = true;
	}

	/// @notice generates the hash of the given string
	/// @param _data String of which hash is to be generated
	function findHash(string memory _data) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
	}
}
