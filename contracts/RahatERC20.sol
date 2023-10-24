//SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.7;

//ERC20 Tokens
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

//Utils
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RahatERC20 is ERC20, ERC20Snapshot, ERC20Burnable {
    ///@dev owner of the ERC20 contract
    mapping(address => bool) public owner;

    modifier OnlyOwner() {
        require(owner[msg.sender], "Only Admin can execute this transaction");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _admin
    ) ERC20(_name, _symbol) {
        owner[msg.sender] = true;
        owner[_admin] = true;
        _mint(msg.sender, 10000);
    }

    ///@dev Mint x amount of ERC20 token to given address
    ///@param _address Address to which ERC20 token will be minted
    ///@param _amount Amount of token to be minted
    function mintERC20(
        address _address,
        uint256 _amount
    ) public OnlyOwner returns (uint256) {
        _mint(_address, _amount);
        return _amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function addOwner(address _account) public OnlyOwner {
        owner[_account] = true;
    }
}
