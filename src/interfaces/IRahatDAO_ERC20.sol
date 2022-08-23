//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface IRahatDAO_ERC20 {
  struct Claim {
    bytes32 otpHash;
    address token;
    uint256 amount;
    uint256 expireOn;
    bool isApproved;
  }

  //#region Events
  event ClaimCreated(
    address indexed vendor,
    address indexed beneficiary,
    uint256 amount
  );

  event ClaimApproved(
    address indexed vendor,
    address indexed beneficiary,
    uint256 amount
  );

  event ClaimProcessed(
    address indexed vendor,
    address indexed beneficiary,
    uint256 amount
  );

  event TokenTransferred(
    address indexed vendor,
    address indexed beneficiary,
    uint256 amount
  );

  event Deposit(address indexed from, address indexed token, uint256 amount);

  //#endregion

  function deposit(address _token, uint256 _amount) external;

  // function getTokenBalanceByPhone(address _token, bytes32 _phone)
  //   external
  //   view
  //   returns (uint256);

  // function getTokenBalance(address _token, address _address)
  //   external
  //   view
  //   returns (uint256);
}
