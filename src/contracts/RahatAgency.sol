//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.16;

import "../interfaces/IRahatAgencyERC20.sol";

contract RahatAgency {

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
}