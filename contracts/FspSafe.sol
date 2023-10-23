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
    constructor() {}

    function transferERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) public onlyOwner {
        bool success = IERC20(tokenAddress).transfer(to, amount);
        require(success, "Transfer Failed");
    }

    function transferERC1155(
        address tokenAddress,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public onlyOwner {
        IERC1155(tokenAddress).safeTransferFrom(
            address(this),
            to,
            id,
            value,
            data
        );
    }

    function transferERC1155Batch(
        address tokenAddress,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data
    ) public onlyOwner {
        IERC1155(tokenAddress).safeBatchTransferFrom(
            address(this),
            to,
            ids,
            values,
            data
        );
    }
}
