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

contract MockPeripheryContractV1 {
  address private _manager;
  uint256 private _value;

  function initialize(address manager, uint256 value) external {
    _manager = manager;
    _value = value;
  }

  function getManager() external view returns (address) {
    return _manager;
  }

  function setManager(address newManager) external {
    _manager = newManager;
  }
}

contract MockPeripheryContractV2 {
  address private _manager;
  uint256 private _value;
  address private _addressesProvider;

  function initialize(address addressesProvider) external {
    _addressesProvider = addressesProvider;
  }

  function getManager() external view returns (address) {
    return _manager;
  }

  function setManager(address newManager) external {
    _manager = newManager;
  }

  function getAddressesProvider() external view returns (address) {
    return _addressesProvider;
  }
}
