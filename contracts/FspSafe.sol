//SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title FSP wallet contract
/// @author Rumsan Associates
/// @notice This contract is for banks to receive Rahat tokens and transfer when needed 
/// @dev All function calls are only executed by contract owner


contract FspSafe is Ownable {
    constructor(){}
    transferERC20(address tokenAddress, address to, uint256 amount) OnlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }

    transferERC1155(address tokenAddress, address to, uint256 id, uint256 value)  OnlyOwner  {
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, id, value);
    }

    transferERC1155Batch(address tokenAddress, address to, uint256[] ids, uint256[] values)  OnlyOwner {
        IERC1155(tokenAddress).safeTransferFrom(address(this), to, ids, values);
    }
}