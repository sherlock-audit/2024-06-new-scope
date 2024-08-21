// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract OpenZeppelinERC20 is ERC20 {
  constructor(string memory name, string memory symbol, uint256 initialSupply, address deployer) ERC20(name, symbol) {
    _mint(deployer, initialSupply);
  }

  // function setBalance(address account, uint256 amount) public {
  //   uint256 bal = balanceOf(account);
  //   if (amount > bal) _mint(account, amount - bal);
  //   else if (amount < bal) _burn(account, bal - amount);
  // }
}
