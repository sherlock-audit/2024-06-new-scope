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

import {IDefaultInterestRateStrategy} from '../interfaces/IDefaultInterestRateStrategy.sol';

import {DataTypes} from '../core/pool/configuration/DataTypes.sol';
import {WadRayMath} from '../core/pool/utils/WadRayMath.sol';

abstract contract MockReserveInterestRateStrategy is IDefaultInterestRateStrategy {
  uint256 public OPTIMAL_USAGE_RATIO;
  uint256 internal _baseVariableBorrowRate;
  uint256 internal _variableRateSlope1;
  uint256 internal _variableRateSlope2;
  uint256 internal _stableRateSlope1;
  uint256 internal _stableRateSlope2;

  // Not used, only defined for interface compatibility
  uint256 public constant MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = 0;
  uint256 public constant MAX_EXCESS_USAGE_RATIO = 0;
  uint256 public constant OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = 0;

  uint256 internal _liquidityRate;
  uint256 internal _stableBorrowRate;
  uint256 internal _borrowRate;

  constructor(uint256 optimalUsageRatio, uint256 baseVariableBorrowRate, uint256 variableRateSlope1, uint256 variableRateSlope2) {
    OPTIMAL_USAGE_RATIO = optimalUsageRatio;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
  }

  function setLiquidityRate(uint256 liquidityRate) public {
    _liquidityRate = liquidityRate;
  }

  function setStableBorrowRate(uint256 stableBorrowRate) public {
    _stableBorrowRate = stableBorrowRate;
  }

  function setVariableBorrowRate(uint256 borrowRate) public {
    _borrowRate = borrowRate;
  }

  function calculateInterestRates(
    bytes32,
    bytes memory,
    DataTypes.CalculateInterestRatesParams memory
  ) external view override returns (uint256 liquidityRate, uint256 borrowRate) {
    return (_liquidityRate, _borrowRate);
  }

  function getVariableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function getVariableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function getStableRateSlope1() external view returns (uint256) {
    return _stableRateSlope1;
  }

  function getStableRateSlope2() external view returns (uint256) {
    return _stableRateSlope2;
  }

  function getBaseBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }
}
