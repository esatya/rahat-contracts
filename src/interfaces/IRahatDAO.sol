//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

interface IRahatDAO {
  event VendorAdded(address indexed vendorAddress);

  event VendorRemoved(address indexed vendorAddress);

  ///@notice grant a role to given account
  function checkRole(string memory _role, address _addr)
    external
    view
    returns (bool);

  ///@notice check whether the account is admin
  function isManager(address _address) external view returns (bool);

  ///@notice check whether the account is vendor
  function isVendor(address _address) external view returns (bool);

  ///@notice check whether the account is system
  function isSystem(address _address) external view returns (bool);

  ///@notice check whether the address is beneficiary
  function isBeneficiary(address _address) external view returns (bool);

  ///@notice lookup beneficiary address using phone number
  function getAddressFromPhone(bytes32 _phone) external view returns (address);

  ///@notice lookup beneficiary phone using address (identifier)
  function getPhonefromAddress(address _beneficiary)
    external
    view
    returns (bytes32);

  function getBeneficiaryHash(address _beneficiary)
    external
    view
    returns (bytes32);

  function registerTokenManagementContract(
    uint256 _contractType,
    address _tokenMgmtAddress
  ) external;

  function depositERC20(address _token, uint256 _amount) external;
}
