//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

//ERC20 Tokens
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
//import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/token/ERC20/extensions/ERC20Pausable.sol';


//Utils
import '@openzeppelin/contracts/access/AccessControl.sol';

contract RahatERC20 is ERC20,ERC20Snapshot,ERC20Burnable{    
    
	mapping(address => bool) public owner;

	modifier OnlyOwner {
		require(owner[tx.origin], 'Only Admin can execute this transaction');
		_;
	}

	constructor(
		string memory _name,
		string memory _symbol,
		address _admin
	)  ERC20(_name, _symbol) {
		owner[msg.sender] = true;
		owner[_admin] = true;
		_mint(msg.sender, 10000);
	}
	

	function mintToken(address _address, uint256 _amount) public OnlyOwner returns (uint256) {
		_mint(_address, _amount);
		return _amount;
	}


	function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    

}
