//SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IRahatAgencyToken.sol";
import "../interfaces/IRahatDAO.sol";

contract RahatAgency {
  using EnumerableSet for EnumerableSet.AddressSet;
  IRahatAgencyToken AgencyToken;

  mapping(address => uint256) public totalProjectToken; // Project > Token (after transfer)
  mapping(address => uint256) public totalDaoToken; // DAO > Token (after transfer)
  mapping(address => mapping(address => uint256)) public totalProjectDaoToken; // Project > DAO > Token (after transfer)
  mapping(address => mapping(address => uint256))
    public currentProjectAllocation; // Project > DAO > Token (before transfer)

  uint128 public requiredConfirmations;
  mapping(bytes32 => mapping(address => bool)) public transferConfirmations; //TxHash > Admin > bool
  EnumerableSet.AddressSet internal _adminSet;
  mapping(address => bool) public isAdmin;

  //Modifiers
  modifier OnlyAdmin() {
    require(
      isAdmin[msg.sender],
      "RAHAT_ADMIN: Only Admin can execute this transaction"
    );
    _;
  }

  constructor(
    address _agencyToken,
    address _adminAddress,
    uint128 _requiredConfirmations
  ) {
    AgencyToken = IRahatAgencyToken(_agencyToken);
    addAdmin(_adminAddress);
    requiredConfirmations = _requiredConfirmations;
  }

  // Admin manage
  function addAdmin(address _adminAddress) public OnlyAdmin {
    _adminSet.add(_adminAddress);
    isAdmin[_adminAddress] = true;
  }

  function removeAdmin(address _adminAddress) public OnlyAdmin {
    _adminSet.remove(_adminAddress);
    isAdmin[_adminAddress] = false;
  }

  function isConfirmed(bytes32 _hash) public view returns (bool _confirmed) {
    _confirmed = false;
    uint256 count = 0;
    for (uint256 i = 0; i < _adminSet.length(); i++) {
      if (transferConfirmations[_hash][_adminSet.at(i)]) count += 1;
      if (count == requiredConfirmations) _confirmed = true;
    }
  }

  // Token allocation manage
  function allocateToken(
    address _project,
    address _dao,
    uint256 _amount
  ) public OnlyAdmin {
    currentProjectAllocation[_project][_dao] = _amount;
  }

  function transferToDao(address _project, address _dao) public OnlyAdmin {
    require(_dao != address(0));
    bytes32 _hash = keccak256(abi.encodePacked(_project, _dao));
    transferConfirmations[_hash][msg.sender] = true;
    //TODO: need to response something
    if (!this.isConfirmed(_hash)) return;

    uint256 _currentDaoBalance = currentProjectAllocation[_project][_dao];

    IRahatDAO dao = IRahatDAO(_dao);
    AgencyToken.mintToken(address(this), _currentDaoBalance);
    AgencyToken.approve(_dao, _currentDaoBalance);
    dao.depositERC20(address(AgencyToken), _currentDaoBalance);

    totalProjectToken[_project] =
      totalProjectToken[_project] +
      _currentDaoBalance;
    totalDaoToken[_dao] = totalDaoToken[_dao] + _currentDaoBalance;
    totalProjectDaoToken[_project][_dao] =
      totalProjectDaoToken[_project][_dao] +
      _currentDaoBalance;

    currentProjectAllocation[_project][_dao] = 0;
  }

  // Misc token manage

  function burnToken(uint256 _amount) public OnlyAdmin {
    AgencyToken.burn(_amount);
  }

  function transferToken(
    address _tokenAddress,
    address _destAddress,
    uint256 _amount
  ) public OnlyAdmin {
    IRahatAgencyToken(_tokenAddress).transfer(_destAddress, _amount);
  }

  function transferEther(address payable _destAddress, uint256 _amount)
    public
    returns (bool)
  {
    (bool success, ) = _destAddress.call{ value: _amount }("");
    return success;
  }

  function createTokenSnapshot() public OnlyAdmin returns (uint256 cid) {
    return AgencyToken.createSnapshot();
  }

  receive() external payable {}
}
