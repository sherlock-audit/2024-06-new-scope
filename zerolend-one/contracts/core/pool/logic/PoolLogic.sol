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

import {PoolErrorsLib} from '../../../interfaces/errors/PoolErrorsLib.sol';
import {DataTypes} from '../configuration/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';

import {PoolEventsLib} from '../../../interfaces/events/PoolEventsLib.sol';
import {PercentageMath} from '../utils/PercentageMath.sol';
import {WadRayMath} from '../utils/WadRayMath.sol';
import {GenericLogic} from './GenericLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title PoolLogic library
 * @notice Implements the logic for Pool specific functions
 */
library PoolLogic {
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @notice Initialize an asset reserve and add the reserve to the list of reserves
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param params Additional parameters needed for initiation
   */
  function executeInitReserve(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.InitReserveParams memory params
  ) external {
    require(Address.isContract(params.asset), PoolErrorsLib.NOT_CONTRACT);
    require(Address.isContract(params.interestRateStrategyAddress), PoolErrorsLib.NOT_CONTRACT);
    require(Address.isContract(params.oracle), PoolErrorsLib.NOT_CONTRACT);

    DataTypes.ReserveConfigurationMap memory config;
    config.setLtv(params.configuration.ltv);
    config.setLiquidationThreshold(params.configuration.liquidationThreshold);
    config.setLiquidationBonus(params.configuration.liquidationBonus);
    config.setDecimals(params.configuration.decimals);
    config.setFrozen(params.configuration.frozen);
    config.setBorrowingEnabled(params.configuration.borrowable);
    config.setBorrowCap(params.configuration.borrowCap);
    config.setSupplyCap(params.configuration.supplyCap);

    setReserveConfiguration(reservesData, params.asset, params.interestRateStrategyAddress, params.oracle, config);

    reservesData[params.asset].init(params.interestRateStrategyAddress);

    bool reserveAlreadyAdded = reservesData[params.asset].id != 0 || reservesList[0] == params.asset;
    require(!reserveAlreadyAdded, PoolErrorsLib.RESERVE_ALREADY_ADDED);

    reservesData[params.asset].id = params.reservesCount;
    reservesList[params.reservesCount] = params.asset;

    emit PoolEventsLib.ReserveInitialized(params.asset, params.interestRateStrategyAddress, params.oracle);
  }

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param reservesData The state of all the reserves
   * @param asset The reserves for which the minting needs to be executed
   */
  function executeMintToTreasury(
    DataTypes.ReserveSupplies storage totalSupply,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address treasury,
    address asset
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[asset];

    uint256 accruedToTreasuryShares = reserve.accruedToTreasuryShares;

    if (accruedToTreasuryShares != 0) {
      reserve.accruedToTreasuryShares = 0;
      uint256 normalizedIncome = reserve.getNormalizedIncome();
      uint256 amountToMint = accruedToTreasuryShares.rayMul(normalizedIncome);

      IERC20(asset).safeTransfer(treasury, amountToMint);
      totalSupply.supplyShares -= accruedToTreasuryShares;

      emit PoolEventsLib.MintedToTreasury(asset, amountToMint);
    }
  }

  /**
   * @notice Returns the user account data across all the reserves
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param params Additional params needed for the calculation
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   */
  function executeGetUserAccountData(
    mapping(address => mapping(bytes32 => DataTypes.PositionBalance)) storage _balances,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.CalculateUserAccountDataParams memory params
  )
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (totalCollateralBase, totalDebtBase, ltv, currentLiquidationThreshold, healthFactor,) =
      GenericLogic.calculateUserAccountData(_balances, reservesData, reservesList, params);
    availableBorrowsBase = GenericLogic.calculateAvailableBorrows(totalCollateralBase, totalDebtBase, ltv);
  }

  function setReserveConfiguration(
    mapping(address => DataTypes.ReserveData) storage _reserves,
    address asset,
    address rateStrategyAddress,
    address source,
    DataTypes.ReserveConfigurationMap memory config
  ) public {
    require(asset != address(0), PoolErrorsLib.ZERO_ADDRESS_NOT_VALID);
    _reserves[asset].configuration = config;

    // set if values are non-0
    if (rateStrategyAddress != address(0)) _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    if (source != address(0)) _reserves[asset].oracle = source;

    require(config.getDecimals() >= 6, 'not enough decimals');

    // validation of the parameters: the LTV can
    // only be lower or equal than the liquidation threshold
    // (otherwise a loan against the asset would cause instantaneous liquidation)
    require(config.getLtv() <= config.getLiquidationThreshold(), PoolErrorsLib.INVALID_RESERVE_PARAMS);

    if (config.getLiquidationThreshold() != 0) {
      // liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
      // collateral than needed to cover the debt
      require(config.getLiquidationBonus() > PercentageMath.PERCENTAGE_FACTOR, PoolErrorsLib.INVALID_RESERVE_PARAMS);

      // if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
      // a loan is taken there is enough collateral available to cover the liquidation bonus
      require(
        config.getLiquidationThreshold().percentMul(config.getLiquidationBonus()) <= PercentageMath.PERCENTAGE_FACTOR,
        PoolErrorsLib.INVALID_RESERVE_PARAMS
      );

      emit PoolEventsLib.CollateralConfigurationChanged(
        asset, config.getLtv(), config.getLiquidationThreshold(), config.getLiquidationThreshold()
      );
    }
  }
}
