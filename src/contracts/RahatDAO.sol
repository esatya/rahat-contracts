//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IRahatDAO.sol";
import "../interfaces/IRahatDAO_ERC20.sol";

contract RahatDAO is AccessControl, IRahatDAO, ReentrancyGuard {
  mapping(address => address) public verifiedBeneficiaries;

  mapping(address => bool) public vendors;
  mapping(uint256 => address) public tokenManagementContracts;

  // Lookup collections
  mapping(address => bytes32) internal _addressToPhone;
  mapping(bytes32 => address) internal _phoneToAddress;

  // Contract Roles
  bytes32 public constant VENDOR = keccak256("VENDOR");
  bytes32 public constant VERIFIER = keccak256("VERIFIER");
  bytes32 public constant SYSTEM = keccak256("SYSTEM");

  //#region Modifiers
  modifier notNull(address _address) {
    require(_address != address(0), "RahatDAO: Address cannot be null.");
    _;
  }

  modifier OnlyManager() {
    require(this.isManager(msg.sender), "RahatDAO: Must be admin.");
    _;
  }

  modifier OnlySystem() {
    require(this.isSystem(msg.sender), "RahatDAO: Need system role.");
    _;
  }

  modifier IsBeneficiary(address _address) {
    require(
      this.isBeneficiary(_address),
      "RahatDAO: beneficiary is not verified."
    );
    _;
  }

  modifier OnlyVerifier() {
    require(
      hasRole(VERIFIER, msg.sender),
      "RahatDAO: Must be an registered verifier."
    );
    _;
  }

  //#endregion

  constructor(address _admin, address _system) {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setRoleAdmin(VENDOR, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(SYSTEM, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(VERIFIER, DEFAULT_ADMIN_ROLE);
    grantRole(SYSTEM, _system);
  }

  function registerTokenManagementContract(
    uint256 _contractType,
    address _tokenMgmtAddress
  ) public OnlyManager {
    grantRole(SYSTEM, _tokenMgmtAddress);
    tokenManagementContracts[_contractType] = _tokenMgmtAddress;
  }

  function depositERC20(address _token, uint256 _amount) public {
    address _tokenMgrAddress = tokenManagementContracts[20];
    require(_tokenMgrAddress != address(0));

    //Get token from sender and transfer it to the ERC20Manager contract
    IERC20 token = IERC20(_token);
    token.transferFrom(msg.sender, address(this), _amount);
    token.approve(_tokenMgrAddress, _amount);
    IRahatDAO_ERC20 tokenMgr = IRahatDAO_ERC20(_tokenMgrAddress);
    tokenMgr.deposit(_token, _amount);
    emit Deposit(msg.sender, _token, _amount);
  }

  //#region Lookup functions
  function addPhoneAddressMapping(address _beneficiary, bytes32 _phone)
    public
    OnlySystem
  {
    _addressToPhone[_beneficiary] = _phone;
    _phoneToAddress[_phone] = _beneficiary;
  }

  function getAddressFromPhone(bytes32 _phone)
    public
    view
    OnlySystem
    returns (address)
  {
    return _phoneToAddress[_phone];
  }

  function getPhonefromAddress(address _beneficiary)
    public
    view
    OnlySystem
    returns (bytes32)
  {
    return _addressToPhone[_beneficiary];
  }

  //#endregion

  //#region ACL functions
  function verifyBeneficiary(address _address) public OnlyVerifier {
    verifiedBeneficiaries[_address] = msg.sender;
  }

  function addVendor(address _vendorAddress) public OnlyManager {
    grantRole(VENDOR, _vendorAddress);
  }

  function addVerifier(address _verifierAddress) public OnlyManager {
    grantRole(VERIFIER, _verifierAddress);
  }

  function addSystem(address _systemAddress) public OnlyManager {
    grantRole(SYSTEM, _systemAddress);
  }

  ///@notice grant a role to given account
  function checkRole(string memory _role, address _addr)
    external
    view
    returns (bool)
  {
    return hasRole(findHash(_role), _addr);
  }

  ///@notice check whether the account is admin
  function isManager(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  ///@notice check whether the account is vendor
  function isVendor(address _address) public view returns (bool) {
    return hasRole(VENDOR, _address);
  }

  ///@notice check whether the address is system
  function isSystem(address _address) public view returns (bool) {
    return hasRole(SYSTEM, _address);
  }

  ///@notice check whether the address is beneficiary
  function isBeneficiary(address _address) public view returns (bool) {
    return verifiedBeneficiaries[_address] != address(0);
  }

  //#endregion

  //Utils
  function findHash(string memory _data) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_data));
  }
}
