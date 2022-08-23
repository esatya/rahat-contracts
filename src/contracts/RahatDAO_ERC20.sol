//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IRahatDAO.sol";
import "../interfaces/IRahatDAO_ERC20.sol";

contract RahatDAO_ERC20 is ReentrancyGuard, IRahatDAO_ERC20 {
  IRahatDAO RahatDAO;

  mapping(address => mapping(address => uint256)) public beneficiariesTokens; // beno > token > balance
  mapping(address => uint256) public unallocatedTokenBalance;
  /// @dev vendorAddress => beneficiaryAddress => Claim
  mapping(address => mapping(address => Claim)) public claims;

  //#region Modifiers
  modifier OnlyManager() {
    require(
      RahatDAO.isManager(msg.sender),
      "RahatDAOClaim: Not a DAO manager."
    );
    _;
  }

  modifier OnlySystem() {
    require(RahatDAO.isSystem(msg.sender), "RahatDAOClaim: Need system role.");
    _;
  }

  modifier OnlyVendor() {
    require(RahatDAO.isVendor(msg.sender), "RahatDAOClaim: Not a vendor.");
    _;
  }

  modifier IsBeneficiary(address _address) {
    require(
      RahatDAO.isBeneficiary(_address),
      "RahatDAOClaim: Not a verified beneficiary."
    );
    _;
  }

  //#endregion

  constructor(address _RahatDaoAddress) {
    RahatDAO = IRahatDAO(_RahatDaoAddress);
  }

  //#region Manage Beneficiary Token Balance
  function allocateToken(
    address _token,
    address _beneficiary,
    uint256 _amount
  ) public OnlyManager nonReentrant {
    require(
      unallocatedTokenBalance[_token] > _amount,
      "RAHATDAO_ERC20: not enough unallocated balance to allocate."
    );
    uint256 currBalance = beneficiariesTokens[_beneficiary][_token];
    beneficiariesTokens[_beneficiary][_token] = currBalance + _amount;
    unallocatedTokenBalance[_token] = unallocatedTokenBalance[_token] - _amount;
  }

  function unallocateToken(
    address _token,
    address _beneficiary,
    uint256 _amount
  ) public OnlyManager nonReentrant {
    _deductToken(_token, _beneficiary, _amount);
    unallocatedTokenBalance[_token] = unallocatedTokenBalance[_token] + _amount;
  }

  function transferBeneficiaryToken(
    address _token,
    address _oldAddress,
    address _newAddress
  ) public OnlyManager nonReentrant {
    beneficiariesTokens[_newAddress][_token] = beneficiariesTokens[_oldAddress][_token];
    beneficiariesTokens[_oldAddress][_token] = 0;
  }

  function getTokenBalance(address _token, address _address)
    public
    view
    returns (uint256)
  {
    return beneficiariesTokens[_address][_token];
  }

  function getTokenBalanceByPhone(address _token, bytes32 _phone)
    public
    view
    returns (uint256, address)
  {
    address _address = RahatDAO.getAddressFromPhone(_phone);
    return (beneficiariesTokens[_address][_token], _address);
  }

  //#endregion

  //#region Vendor Function
  function sendToken(
    address _beneficiary,
    address _to,
    address _token,
    uint256 _amount
  ) public IsBeneficiary(_beneficiary) nonReentrant OnlySystem {
    require(
      beneficiariesTokens[_beneficiary][_token] >= _amount,
      "RAHATDAO_ERC20: Amount requested is greater than beneficiary balance."
    );

    _deductToken(_token, _beneficiary, _amount);
    IERC20 token = IERC20(_token);
    token.transfer(_to, _amount);

    emit TokenTransferred(msg.sender, _beneficiary, _amount);
  }

  function createClaim(
    address _token,
    address _address,
    uint256 _amount
  ) public IsBeneficiary(_address) nonReentrant OnlyVendor {
    require(
      beneficiariesTokens[_address][_token] >= _amount,
      "RAHATDAO_ERC20: Amount requested is greater than beneficiary balance."
    );

    Claim storage ac = claims[msg.sender][_address];
    ac.token = _token;
    ac.isApproved = false;
    ac.amount = _amount;
    ac.expireOn = block.timestamp;
    emit ClaimCreated(msg.sender, _address, _amount);
  }

  function approveClaim(
    address _vendor,
    address _address,
    bytes32 _otpHash,
    uint256 _timeToLive
  ) public OnlySystem {
    Claim storage ac = claims[_vendor][_address];
    require(ac.expireOn != 0, "RAHATDAO_ERC20: Claim has not been created yet");
    require(
      _timeToLive <= 3600,
      "RAHATDAO_ERC20: Time To Live should be less than 1 hour"
    );
    require(
      block.timestamp <= ac.expireOn + 3600,
      "RAHATDAO_ERC20: Claim is older than 1 hour"
    );
    require(!ac.isApproved, "RAHATDAO_ERC20: Claim has already been released.");
    ac.otpHash = _otpHash;
    ac.isApproved = true;
    ac.expireOn = block.timestamp + _timeToLive;
    emit ClaimApproved(_vendor, _address, ac.amount);
  }

  function claimToken(address _address, string memory _otp)
    public
    IsBeneficiary(_address)
    OnlyVendor
  {
    Claim storage ac = claims[msg.sender][_address];
    require(ac.expireOn != 0, "RAHATDAO_ERC20: Claim has not been created yet");
    require(ac.isApproved, "RAHATDAO_ERC20: Claim has not been approved.");
    require(
      ac.expireOn >= block.timestamp,
      "RAHATDAO_ERC20: Claim has already expired."
    );
    bytes32 otpHash = findHash(_otp);
    require(ac.otpHash == otpHash, "RAHATDAO_ERC20: OTP did not match.");
    uint256 _amount = ac.amount;

    _deductToken(ac.token, _address, _amount);
    IERC20 token = IERC20(ac.token);
    token.transfer(msg.sender, _amount);

    delete claims[msg.sender][_address];

    emit ClaimProcessed(msg.sender, _address, _amount);
  }

  //#endregion

  function deposit(address _token, uint256 _amount) public nonReentrant {
    IERC20 token = IERC20(_token);
    token.transferFrom(msg.sender, address(this), _amount);

    unallocatedTokenBalance[_token] = unallocatedTokenBalance[_token] + _amount;
    emit Deposit(msg.sender, _token, _amount);
  }

  // Private functions
  function findHash(string memory _data) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_data));
  }

  function _deductToken(
    address _token,
    address _beneficiary,
    uint256 _amount
  ) private {
    uint256 currBalance = beneficiariesTokens[_beneficiary][_token];
    require(
      currBalance > _amount,
      "RAHATDAO_ERC20: Benefiary do not enough balance to deduct."
    );
    beneficiariesTokens[_beneficiary][_token] = currBalance - _amount;
  }
}
