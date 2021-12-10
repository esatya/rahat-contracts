//SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.7;

import './RahatERC20.sol';
import './RahatERC1155.sol';
import './Rahat.sol';

/// @title Rahat Admin contract - owns all the tokens initially minted
/// @author Rumsan Associates
/// @notice You can use this contract to manage Rahat tokens and projects
/// @dev All function calls are only executed by contract owner
contract RahatAdmin is ERC1155Holder {
    
    using EnumerableSet for EnumerableSet.UintSet;
    
	event ProjectERC20BudgetUpdated(bytes32 indexed projectId, uint256 projectCapital,string tag);
	event ProjectERC1155BudgetUpdated(bytes32 indexed projectId, uint256 indexed tokenId, uint256 projectCapital,string tag);
	event Minted(bool success);

	// uint256 public mintData ;
	// bool public mintSuccess =false;

    RahatERC20 public erc20;
    RahatERC1155 public erc1155;
	Rahat public rahatContract;
	mapping(address => bool) public owner;
	//EnumerableSet.UintSet private tokenIds;

	/// @notice list of projects
	bytes32[] public projectId;
	
	//NFTs minted for each project
    mapping(bytes32 => EnumerableSet.UintSet) ERC1155InProject;

	/// @notice check if projectId exists or not;
	mapping(bytes32 => bool) public projectExists;

	/// @notice assign budgets to project
	mapping(bytes32 => uint256) public projectERC20Capital;
	mapping(bytes32 => mapping(uint256 => uint256)) public projectERC1155Capital; // projectId => tokenId => balance

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
		erc20.mintERC20(address(this), _intitialSupply);
		//(bool success, bytes memory result) = address(_tokenContract).call(abi.encodeWithSignature("mintERC20(address, uint256)", address(this), _intitialSupply));
		//mintSuccess = success;
		//mintData = abi.decode(result,(uint256));

		owner[_admin] = true;
	}

    
	/// @notice allocate token to projects
	/// @dev Allocates token to the given projectId, Creates project and transfer tokens to Rahat contract.
	/// @param _projectId Unique Id of Project
	/// @param _projectCapital Budget Allocated to project
	function setProjectBudget_ERC20(string memory _projectId, uint256 _projectCapital)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
		bytes32 _id = findHash(_projectId);
		projectERC20Capital[_id] += _projectCapital;
		erc20.transfer(address(rahatContract), _projectCapital);
		rahatContract.updateProjectBudget(_id, _projectCapital);

		emit ProjectERC20BudgetUpdated(_id, _projectCapital,'add');
	}
	
	/// @notice allocate ERC1155 tokens to projects
	/// @dev Allocates token to the given projectId, Creates project and transfer tokens to Rahat contract.
	/// @param _projectId Unique Id of Project
	/// @param _projectCapital amount of ERC1155 token with _tokenId allocated to project
	/// @param tokenId ERC1155 token ID
		function setProjectBudget_ERC1155(string memory _projectId, uint256 _projectCapital,uint256 tokenId)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
	    require(erc1155.exists(tokenId),"RahatAdmin: Token with given id doesn't exists");
	    bytes32 _id = findHash(_projectId);
	    if(!ERC1155InProject[_id].contains(tokenId)){
	        ERC1155InProject[_id].add(tokenId);
	    }
	    
		erc1155.mintExistingERC1155(tokenId,_projectCapital);
		projectERC1155Capital[_id][tokenId] += _projectCapital;
		erc1155.safeTransferFrom(address(this),address(rahatContract),tokenId, _projectCapital,'');
		rahatContract.updateProjectBudget(_id, _projectCapital,tokenId);

		emit ProjectERC1155BudgetUpdated(_id,tokenId, _projectCapital,'add');
	}

	/// @notice allocate ERC1155 tokens to projects
	/// @dev create token and allocate them to the given projectId, Creates project and transfer tokens to Rahat contract.
	///@param _name name of NFT
    ///@param _symbol symbol of NFT
	/// @param _projectId Unique Id of Project
	/// @param _projectCapital amount of ERC1155 token with _tokenId allocated to project
	/// @param _projectCapital ERC1155 token ID
	function createAndsetProjectBudget_ERC1155(string memory _name, string memory _symbol, string memory _projectId, uint256 _projectCapital)
		public
		OnlyOwner
		CheckProject(_projectId)
	{
	    bytes32 _id = findHash(_projectId);
	    uint256 tokenId = erc1155.mintERC1155(_name,_symbol,_projectCapital);
	    
	    ERC1155InProject[_id].add(tokenId);
		projectERC1155Capital[_id][tokenId] += _projectCapital;
		erc1155.safeTransferFrom(address(this),address(rahatContract),tokenId, _projectCapital,'');
		rahatContract.updateProjectBudget(_id, _projectCapital,tokenId);

		emit ProjectERC1155BudgetUpdated(_id,tokenId, _projectCapital,'add');
	}
	
	

	// 	function revokeProjectBudget(string memory _projectId, uint256 _projectCapital)
	// 	public
	// 	OnlyOwner
	// 	CheckProject(_projectId)
	// {
	// 	bytes32 _id = findHash(_projectId);
	// 	projectERC20Capital[_id] -= _projectCapital;
	// //	tokenContract.transfer(address(rahatContract), _projectCapital);
	// 	//rahatContract.updateProjectBudget(_id, _projectCapital);

	// 	emit ProjectERC20BudgetUpdated(_id, _projectCapital,'deduct');
	// }
	
	// 	function revokeProjectBudget(string memory _projectId, uint256 _projectCapital,uint256 tokenId)
	// 	public
	// 	OnlyOwner
	// 	CheckProject(_projectId)
	// {
	//     require(erc1155.exists(tokenId),"RahatAdmin: Token with given id doesn't exists");
	    
	// 	bytes32 _id = findHash(_projectId);
	// 	projectERC1155Capital[_id][tokenId] += _projectCapital;
	// //	tokenContract.safeTransferFrom(address(this),address(rahatContract),tokenId, _projectCapital,'');
	// //	rahatContract.updateProjectBudget(_id, _projectCapital,tokenId);

	// 	emit ProjectERC1155BudgetUpdated(_id,tokenId, _projectCapital,'deduct');
	// }
	
	// function suspendProject(string memory _projectId) public OnlyOwner CheckProject(_projectId){
	    
	// }

	/// @notice get the current balance of project
	/// @param _projectId Unique Id of project
	function getProjecERC20Balance(string memory _projectId) public view returns (uint256 _balance) {
		bytes32 _id = findHash(_projectId);
		require(projectExists[_id], 'RAHAT_ADMIN: Invalid ProjectID');
		return (rahatContract.getProjectBalance(_id));
	}

	
	/// @notice get the current ERC1155 amount of given tokenId in the project
	/// @param _projectId Unique Id of project
	/// @param tokenId ERC1155 tokenID
	function getProjectERC1155Balance(string memory _projectId,uint256 tokenId) public view returns (uint256 _balance) {
		bytes32 _id = findHash(_projectId);
		require(projectExists[_id], 'RAHAT_ADMIN: Invalid ProjectID');
		return (rahatContract.getProjectBalance(_id,tokenId));
	}
	
	function getProjectERC1155Balances(string memory _projectId) public view returns(uint256[] memory tokenIds, uint256[] memory balances){
	    bytes32 _id = findHash(_projectId);
        uint256 i;
        uint256 _totalERC1155 = ERC1155InProject[_id].length();
        uint256[] memory _tokenIds = new uint256[](_totalERC1155);
        uint256[] memory _balances = new uint256[](_totalERC1155);
        
        for (i=0;i<_totalERC1155;i++){
            uint256 _tokenId = ERC1155InProject[_id].at(i);
            uint256 _balance = getProjectERC1155Balance(_projectId,_tokenId);
            _tokenIds[i] = _tokenId;
            _balances[i] = _balance;
        }
        
        return (_tokenIds,_balances);
	    
	}
	
	function getAllTokenIdsOfProject(string memory _projectId) public view returns (uint256[] memory tokenIds){
	     bytes32 _id = findHash(_projectId);
	    return ERC1155InProject[_id].values();
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
	function mintERC20(address _address, uint256 _amount) public OnlyOwner {
		erc20.mintERC20(_address, _amount);
	}
	
	/// @dev mint new tokens
    ///@param _name name of NFT
    ///@param _symbol symbol of NFT
    ///@param _amount amount of NFT
	function mintERC1155(string memory _name,
		string memory _symbol,uint256 _amount) public OnlyOwner {
		    erc1155.mintERC1155(_name,_symbol,_amount);
		}

	/// @notice Add an account to the owner role. Restricted to owners.
	/// @param _account address of new owner
	function addOwner(address _account) public OnlyOwner {
		owner[_account] = true;
	}

	/// @notice generates the hash of the given string
	/// @param _data String of which hash is to be generated
	function findHash(string memory _data) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
	}
}
