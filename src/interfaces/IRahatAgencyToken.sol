//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRahatAgencyToken is IERC20 {
    event Snapshotcreated(uint256 indexed id);

    ///@notice burns the token owned by address
    function burn(uint256 amount) external;

    ///@notice Creates a new snapshot and returns it's id
    function createSnapshot() external returns (uint256 currentId);

    /// @notice Mints new tokens to given address
    /// @param _address Destination address where token is minted
    /// @param _amount Amount of token to mint
    function mintToken(address _address, uint256 _amount) external;
}
