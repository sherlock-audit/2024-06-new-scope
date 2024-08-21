// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz
// Telegram: https://t.me/zerolendxyz

import {IWETH} from './../interfaces/IWETH.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract WETH9Mocked is IWETH, ERC20 {
  function mint(uint256 value) public returns (bool) {
    _mint(msg.sender, value);
    return true;
  }

  constructor() ERC20('WETH Mock', 'WETH') {}

  receive() external payable {
    _mint(msg.sender, msg.value);
  }

  function mint(address account, uint256 value) public returns (bool) {
    _mint(account, value);
    return true;
  }

  function deposit() external payable {
    _mint(msg.sender, msg.value);
  }

  function withdraw(uint256 value) external {
    _burn(msg.sender, value);
    payable(msg.sender).transfer(value);
  }
}
