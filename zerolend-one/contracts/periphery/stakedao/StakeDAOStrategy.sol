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

import {INFTPositionManager} from '../../interfaces/INFTPositionManager.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                       CUSTOM ERRORS                        */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The operation failed, as the output exceeds the maximum value of uint256.
  error ExpOverflow();

  /// @dev The operation failed, as the output exceeds the maximum value of uint256.
  error FactorialOverflow();

  /// @dev The operation failed, due to an overflow.
  error RPowOverflow();

  /// @dev The mantissa is too big to fit.
  error MantissaOverflow();

  /// @dev The operation failed, due to an multiplication overflow.
  error MulWadFailed();

  /// @dev The operation failed, due to an multiplication overflow.
  error SMulWadFailed();

  /// @dev The operation failed, either due to a multiplication overflow, or a division by a zero.
  error DivWadFailed();

  /// @dev The operation failed, either due to a multiplication overflow, or a division by a zero.
  error SDivWadFailed();

  /// @dev The operation failed, either due to a multiplication overflow, or a division by a zero.
  error MulDivFailed();

  /// @dev The division failed, as the denominator is zero.
  error DivFailed();

  /// @dev The full precision multiply-divide operation failed, either due
  /// to the result being larger than 256 bits, or a division by a zero.
  error FullMulDivFailed();

  /// @dev The output is undefined, as the input is less-than-or-equal to zero.
  error LnWadUndefined();

  /// @dev The input outside the acceptable domain.
  error OutOfDomain();

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTANTS                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev The scalar of ETH and most ERC20s.
  uint256 internal constant WAD = 1e18;

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*              SIMPLIFIED FIXED POINT OPERATIONS             */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Equivalent to `(x * y) / WAD` rounded down.
  function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
      if mul(y, gt(x, div(not(0), y))) {
        mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
        revert(0x1c, 0x04)
      }
      z := div(mul(x, y), WAD)
    }
  }

  /// @dev Equivalent to `(x * y) / WAD` rounded down.
  function sMulWad(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := mul(x, y)
      // Equivalent to `require((x == 0 || z / x == y) && !(x == -1 && y == type(int256).min))`.
      if iszero(gt(or(iszero(x), eq(sdiv(z, x), y)), lt(not(x), eq(y, shl(255, 1))))) {
        mstore(0x00, 0xedcd4dd4) // `SMulWadFailed()`.
        revert(0x1c, 0x04)
      }
      z := sdiv(z, WAD)
    }
  }

  /// @dev Equivalent to `(x * y) / WAD` rounded down, but without overflow checks.
  function rawMulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := div(mul(x, y), WAD)
    }
  }

  /// @dev Equivalent to `(x * y) / WAD` rounded down, but without overflow checks.
  function rawSMulWad(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := sdiv(mul(x, y), WAD)
    }
  }

  /// @dev Equivalent to `(x * y) / WAD` rounded up.
  function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
      if mul(y, gt(x, div(not(0), y))) {
        mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
        revert(0x1c, 0x04)
      }
      z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
    }
  }

  /// @dev Equivalent to `(x * y) / WAD` rounded up, but without overflow checks.
  function rawMulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
    }
  }

  /// @dev Equivalent to `(x * WAD) / y` rounded down.
  function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
      if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
        mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
        revert(0x1c, 0x04)
      }
      z := div(mul(x, WAD), y)
    }
  }

  /// @dev Equivalent to `(x * WAD) / y` rounded down.
  function sDivWad(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := mul(x, WAD)
      // Equivalent to `require(y != 0 && ((x * WAD) / WAD == x))`.
      if iszero(and(iszero(iszero(y)), eq(sdiv(z, WAD), x))) {
        mstore(0x00, 0x5c43740d) // `SDivWadFailed()`.
        revert(0x1c, 0x04)
      }
      z := sdiv(mul(x, WAD), y)
    }
  }

  /// @dev Equivalent to `(x * WAD) / y` rounded down, but without overflow and divide by zero checks.
  function rawDivWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := div(mul(x, WAD), y)
    }
  }

  /// @dev Equivalent to `(x * WAD) / y` rounded down, but without overflow and divide by zero checks.
  function rawSDivWad(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := sdiv(mul(x, WAD), y)
    }
  }

  /// @dev Equivalent to `(x * WAD) / y` rounded up.
  function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
      if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
        mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
        revert(0x1c, 0x04)
      }
      z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
    }
  }

  /// @dev Equivalent to `(x * WAD) / y` rounded up, but without overflow and divide by zero checks.
  function rawDivWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
    }
  }

  /// @dev Equivalent to `x` to the power of `y`.
  /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
  function powWad(int256 x, int256 y) internal pure returns (int256) {
    // Using `ln(x)` means `x` must be greater than 0.
    return expWad((lnWad(x) * y) / int256(WAD));
  }

  /// @dev Returns `exp(x)`, denominated in `WAD`.
  /// Credit to Remco Bloemen under MIT license: https://2π.com/21/exp-ln
  function expWad(int256 x) internal pure returns (int256 r) {
    unchecked {
      // When the result is less than 0.5 we return zero.
      // This happens when `x <= floor(log(0.5e18) * 1e18) ≈ -42e18`.
      if (x <= -41_446_531_673_892_822_313) return r;

      /// @solidity memory-safe-assembly
      assembly {
        // When the result is greater than `(2**255 - 1) / 1e18` we can not represent it as
        // an int. This happens when `x >= floor(log((2**255 - 1) / 1e18) * 1e18) ≈ 135`.
        if iszero(slt(x, 135305999368893231589)) {
          mstore(0x00, 0xa37bfec9) // `ExpOverflow()`.
          revert(0x1c, 0x04)
        }
      }

      // `x` is now in the range `(-42, 136) * 1e18`. Convert to `(-42, 136) * 2**96`
      // for more intermediate precision and a binary basis. This base conversion
      // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
      x = (x << 78) / 5 ** 18;

      // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
      // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
      // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
      int256 k = ((x << 96) / 54_916_777_467_707_473_351_141_471_128 + 2 ** 95) >> 96;
      x = x - k * 54_916_777_467_707_473_351_141_471_128;

      // `k` is in the range `[-61, 195]`.

      // Evaluate using a (6, 7)-term rational approximation.
      // `p` is made monic, we'll multiply by a scale factor later.
      int256 y = x + 1_346_386_616_545_796_478_920_950_773_328;
      y = ((y * x) >> 96) + 57_155_421_227_552_351_082_224_309_758_442;
      int256 p = y + x - 94_201_549_194_550_492_254_356_042_504_812;
      p = ((p * y) >> 96) + 28_719_021_644_029_726_153_956_944_680_412_240;
      p = p * x + (4_385_272_521_454_847_904_659_076_985_693_276 << 96);

      // We leave `p` in `2**192` basis so we don't need to scale it back up for the division.
      int256 q = x - 2_855_989_394_907_223_263_936_484_059_900;
      q = ((q * x) >> 96) + 50_020_603_652_535_783_019_961_831_881_945;
      q = ((q * x) >> 96) - 533_845_033_583_426_703_283_633_433_725_380;
      q = ((q * x) >> 96) + 3_604_857_256_930_695_427_073_651_918_091_429;
      q = ((q * x) >> 96) - 14_423_608_567_350_463_180_887_372_962_807_573;
      q = ((q * x) >> 96) + 26_449_188_498_355_588_339_934_803_723_976_023;

      /// @solidity memory-safe-assembly
      assembly {
        // Div in assembly because solidity adds a zero check despite the unchecked.
        // The q polynomial won't have zeros in the domain as all its roots are complex.
        // No scaling is necessary because p is already `2**96` too large.
        r := sdiv(p, q)
      }

      // r should be in the range `(0.09, 0.25) * 2**96`.

      // We now need to multiply r by:
      // - The scale factor `s ≈ 6.031367120`.
      // - The `2**k` factor from the range reduction.
      // - The `1e18 / 2**96` factor for base conversion.
      // We do this all at once, with an intermediate result in `2**213`
      // basis, so the final right shift is always by a positive amount.
      r = int256((uint256(r) * 3_822_833_074_963_236_453_042_738_258_902_158_003_155_416_615_667) >> uint256(195 - k));
    }
  }

  /// @dev Returns `ln(x)`, denominated in `WAD`.
  /// Credit to Remco Bloemen under MIT license: https://2π.com/21/exp-ln
  function lnWad(int256 x) internal pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
      // We want to convert `x` from `10**18` fixed point to `2**96` fixed point.
      // We do this by multiplying by `2**96 / 10**18`. But since
      // `ln(x * C) = ln(x) + ln(C)`, we can simply do nothing here
      // and add `ln(2**96 / 10**18)` at the end.

      // Compute `k = log2(x) - 96`, `r = 159 - k = 255 - log2(x) = 255 ^ log2(x)`.
      r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
      r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
      r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
      r := or(r, shl(4, lt(0xffff, shr(r, x))))
      r := or(r, shl(3, lt(0xff, shr(r, x))))
      // We place the check here for more optimal stack operations.
      if iszero(sgt(x, 0)) {
        mstore(0x00, 0x1615e638) // `LnWadUndefined()`.
        revert(0x1c, 0x04)
      }
      // forgefmt: disable-next-item
      r := xor(
        r,
        byte(
          and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
          0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff
        )
      )

      // Reduce range of x to (1, 2) * 2**96
      // ln(2^k * x) = k * ln(2) + ln(x)
      x := shr(159, shl(r, x))

      // Evaluate using a (8, 8)-term rational approximation.
      // `p` is made monic, we will multiply by a scale factor later.
      // forgefmt: disable-next-item
      let p := sub(
        // This heavily nested expression is to avoid stack-too-deep for via-ir.
        sar(
          96,
          mul(
            add(
              43456485725739037958740375743393,
              sar(96, mul(add(24828157081833163892658089445524, sar(96, mul(add(3273285459638523848632254066296, x), x))), x))
            ),
            x
          )
        ),
        11111509109440967052023855526967
      )
      p := sub(sar(96, mul(p, x)), 45023709667254063763336534515857)
      p := sub(sar(96, mul(p, x)), 14706773417378608786704636184526)
      p := sub(mul(p, x), shl(96, 795164235651350426258249787498))
      // We leave `p` in `2**192` basis so we don't need to scale it back up for the division.

      // `q` is monic by convention.
      let q := add(5573035233440673466300451813936, x)
      q := add(71694874799317883764090561454958, sar(96, mul(x, q)))
      q := add(283447036172924575727196451306956, sar(96, mul(x, q)))
      q := add(401686690394027663651624208769553, sar(96, mul(x, q)))
      q := add(204048457590392012362485061816622, sar(96, mul(x, q)))
      q := add(31853899698501571402653359427138, sar(96, mul(x, q)))
      q := add(909429971244387300277376558375, sar(96, mul(x, q)))

      // `p / q` is in the range `(0, 0.125) * 2**96`.

      // Finalization, we need to:
      // - Multiply by the scale factor `s = 5.549…`.
      // - Add `ln(2**96 / 10**18)`.
      // - Add `k * ln(2)`.
      // - Multiply by `10**18 / 2**96 = 5**18 >> 78`.

      // The q polynomial is known not to have zeros in the domain.
      // No scaling required because p is already `2**96` too large.
      p := sdiv(p, q)
      // Multiply by the scaling factor: `s * 5**18 * 2**96`, base is now `5**18 * 2**192`.
      p := mul(1677202110996718588342820967067443963516166, p)
      // Add `ln(2) * k * 5**18 * 2**192`.
      // forgefmt: disable-next-item
      p := add(mul(16597577552685614221487285958193947469193820559219878177908093499208371, sub(159, r)), p)
      // Add `ln(2**96 / 10**18) * 5**18 * 2**192`.
      p := add(600920179829731861736702779321621459595472258049074101567377883020018308, p)
      // Base conversion: mul `2**18 / 2**192`.
      r := sar(174, p)
    }
  }

  /// @dev Returns `W_0(x)`, denominated in `WAD`.
  /// See: https://en.wikipedia.org/wiki/Lambert_W_function
  /// a.k.a. Product log function. This is an approximation of the principal branch.
  function lambertW0Wad(int256 x) internal pure returns (int256 w) {
    // forgefmt: disable-next-item
    unchecked {
      if ((w = x) <= -367879441171442322) revert OutOfDomain(); // `x` less than `-1/e`.
      int256 wad = int256(WAD);
      int256 p = x;
      uint256 c; // Whether we need to avoid catastrophic cancellation.
      uint256 i = 4; // Number of iterations.
      if (w <= 0x1ffffffffffff) {
        if (-0x4000000000000 <= w) {
          i = 1; // Inputs near zero only take one step to converge.
        } else if (w <= -0x3ffffffffffffff) {
          i = 32; // Inputs near `-1/e` take very long to converge.
        }
      } else if (w >> 63 == 0) {
        /// @solidity memory-safe-assembly
        assembly {
          // Inline log2 for more performance, since the range is small.
          let v := shr(49, w)
          let l := shl(3, lt(0xff, v))
          l := add(
            or(
              l,
              byte(
                and(0x1f, shr(shr(l, v), 0x8421084210842108cc6318c6db6d54be)),
                0x0706060506020504060203020504030106050205030304010505030400000000
              )
            ),
            49
          )
          w := sdiv(shl(l, 7), byte(sub(l, 31), 0x0303030303030303040506080c13))
          c := gt(l, 60)
          i := add(2, add(gt(l, 53), c))
        }
      } else {
        int256 ll = lnWad(w = lnWad(w));
        /// @solidity memory-safe-assembly
        assembly {
          // `w = ln(x) - ln(ln(x)) + b * ln(ln(x)) / ln(x)`.
          w := add(sdiv(mul(ll, 1023715080943847266), w), sub(w, ll))
          i := add(3, iszero(shr(68, x)))
          c := iszero(shr(143, x))
        }
        if (c == 0) {
          do {
            // If `x` is big, use Newton's so that intermediate values won't overflow.
            int256 e = expWad(w);
            /// @solidity memory-safe-assembly
            assembly {
              let t := mul(w, div(e, wad))
              w := sub(w, sdiv(sub(t, x), div(add(e, t), wad)))
            }
            if (p <= w) break;
            p = w;
          } while (--i != 0);
          /// @solidity memory-safe-assembly
          assembly {
            w := sub(w, sgt(w, 2))
          }
          return w;
        }
      }
      do {
        // Otherwise, use Halley's for faster convergence.
        int256 e = expWad(w);
        /// @solidity memory-safe-assembly
        assembly {
          let t := add(w, wad)
          let s := sub(mul(w, e), mul(x, wad))
          w := sub(w, sdiv(mul(s, wad), sub(mul(e, t), sdiv(mul(add(t, wad), s), add(t, t)))))
        }
        if (p <= w) break;
        p = w;
      } while (--i != c);
      /// @solidity memory-safe-assembly
      assembly {
        w := sub(w, sgt(w, 2))
      }
      // For certain ranges of `x`, we'll use the quadratic-rate recursive formula of
      // R. Iacono and J.P. Boyd for the last iteration, to avoid catastrophic cancellation.
      if (c != 0) {
        int256 t = w | 1;
        /// @solidity memory-safe-assembly
        assembly {
          x := sdiv(mul(x, wad), t)
        }
        x = (t * (wad + lnWad(x)));
        /// @solidity memory-safe-assembly
        assembly {
          w := sdiv(x, add(wad, t))
        }
      }
    }
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                  GENERAL NUMBER UTILITIES                  */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Calculates `floor(x * y / d)` with full precision.
  /// Throws if result overflows a uint256 or when `d` is zero.
  /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
  function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
    /// @solidity memory-safe-assembly
    assembly {
      for {} 1 {} {
        // 512-bit multiply `[p1 p0] = x * y`.
        // Compute the product mod `2**256` and mod `2**256 - 1`
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that `product = p1 * 2**256 + p0`.

        // Least significant 256 bits of the product.
        result := mul(x, y) // Temporarily use `result` as `p0` to save gas.
        let mm := mulmod(x, y, not(0))
        // Most significant 256 bits of the product.
        let p1 := sub(mm, add(result, lt(mm, result)))

        // Handle non-overflow cases, 256 by 256 division.
        if iszero(p1) {
          if iszero(d) {
            mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
            revert(0x1c, 0x04)
          }
          result := div(result, d)
          break
        }

        // Make sure the result is less than `2**256`. Also prevents `d == 0`.
        if iszero(gt(d, p1)) {
          mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
          revert(0x1c, 0x04)
        }

        /*------------------- 512 by 256 division --------------------*/

        // Make division exact by subtracting the remainder from `[p1 p0]`.
        // Compute remainder using mulmod.
        let r := mulmod(x, y, d)
        // `t` is the least significant bit of `d`.
        // Always greater or equal to 1.
        let t := and(d, sub(0, d))
        // Divide `d` by `t`, which is a power of two.
        d := div(d, t)
        // Invert `d mod 2**256`
        // Now that `d` is an odd number, it has an inverse
        // modulo `2**256` such that `d * inv = 1 mod 2**256`.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, `d * inv = 1 mod 2**4`.
        let inv := xor(2, mul(3, d))
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
        inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
        inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
        inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
        inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
        result :=
          mul(
            // Divide [p1 p0] by the factors of two.
            // Shift in bits from `p1` into `p0`. For this we need
            // to flip `t` such that it is `2**256 / t`.
            or(mul(sub(p1, gt(r, result)), add(div(sub(0, t), t), 1)), div(sub(result, r), t)),
            // inverse mod 2**256
            mul(inv, sub(2, mul(d, inv)))
          )
        break
      }
    }
  }

  /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
  /// Throws if result overflows a uint256 or when `d` is zero.
  /// Credit to Uniswap-v3-core under MIT license:
  /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
  function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
    result = fullMulDiv(x, y, d);
    /// @solidity memory-safe-assembly
    assembly {
      if mulmod(x, y, d) {
        result := add(result, 1)
        if iszero(result) {
          mstore(0x00, 0xae47f702) // `FullMulDivFailed()`.
          revert(0x1c, 0x04)
        }
      }
    }
  }

  /// @dev Returns `floor(x * y / d)`.
  /// Reverts if `x * y` overflows, or `d` is zero.
  function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
      if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
        mstore(0x00, 0xad251c27) // `MulDivFailed()`.
        revert(0x1c, 0x04)
      }
      z := div(mul(x, y), d)
    }
  }

  /// @dev Returns `ceil(x * y / d)`.
  /// Reverts if `x * y` overflows, or `d` is zero.
  function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
      if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
        mstore(0x00, 0xad251c27) // `MulDivFailed()`.
        revert(0x1c, 0x04)
      }
      z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
    }
  }

  /// @dev Returns `ceil(x / d)`.
  /// Reverts if `d` is zero.
  function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      if iszero(d) {
        mstore(0x00, 0x65244e4e) // `DivFailed()`.
        revert(0x1c, 0x04)
      }
      z := add(iszero(iszero(mod(x, d))), div(x, d))
    }
  }

  /// @dev Returns `max(0, x - y)`.
  function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := mul(gt(x, y), sub(x, y))
    }
  }

  /// @dev Exponentiate `x` to `y` by squaring, denominated in base `b`.
  /// Reverts if the computation overflows.
  function rpow(uint256 x, uint256 y, uint256 b) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := mul(b, iszero(y)) // `0 ** 0 = 1`. Otherwise, `0 ** n = 0`.
      if x {
        z := xor(b, mul(xor(b, x), and(y, 1))) // `z = isEven(y) ? scale : x`
        let half := shr(1, b) // Divide `b` by 2.
        // Divide `y` by 2 every iteration.
        for { y := shr(1, y) } y { y := shr(1, y) } {
          let xx := mul(x, x) // Store x squared.
          let xxRound := add(xx, half) // Round to the nearest number.
          // Revert if `xx + half` overflowed, or if `x ** 2` overflows.
          if or(lt(xxRound, xx), shr(128, x)) {
            mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
            revert(0x1c, 0x04)
          }
          x := div(xxRound, b) // Set `x` to scaled `xxRound`.
          // If `y` is odd:
          if and(y, 1) {
            let zx := mul(z, x) // Compute `z * x`.
            let zxRound := add(zx, half) // Round to the nearest number.
            // If `z * x` overflowed or `zx + half` overflowed:
            if or(xor(div(zx, x), z), lt(zxRound, zx)) {
              // Revert if `x` is non-zero.
              if iszero(iszero(x)) {
                mstore(0x00, 0x49f7642b) // `RPowOverflow()`.
                revert(0x1c, 0x04)
              }
            }
            z := div(zxRound, b) // Return properly scaled `zxRound`.
          }
        }
      }
    }
  }

  /// @dev Returns the square root of `x`.
  function sqrt(uint256 x) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
      z := 181 // The "correct" value is 1, but this saves a multiplication later.

      // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
      // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

      // Let `y = x / 2**r`. We check `y >= 2**(k + 8)`
      // but shift right by `k` bits to ensure that if `x >= 256`, then `y >= 256`.
      let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
      r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
      r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
      r := or(r, shl(4, lt(0xffffff, shr(r, x))))
      z := shl(shr(1, r), z)

      // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
      // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
      // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
      // That's not possible if `x < 256` but we can just verify those cases exhaustively.

      // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
      // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
      // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

      // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
      // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
      // with largest error when `s = 1` and when `s = 256` or `1/256`.

      // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
      // Then we can estimate `sqrt(y)` using
      // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

      // There is no overflow risk here since `y < 2**136` after the first branch above.
      z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

      // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))
      z := shr(1, add(z, div(x, z)))

      // If `x+1` is a perfect square, the Babylonian method cycles between
      // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
      // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
      z := sub(z, lt(div(x, z), z))
    }
  }

  /// @dev Returns the cube root of `x`.
  /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
  /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
  function cbrt(uint256 x) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
      r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
      r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
      r := or(r, shl(4, lt(0xffff, shr(r, x))))
      r := or(r, shl(3, lt(0xff, shr(r, x))))

      z := div(shl(div(r, 3), shl(lt(0xf, shr(r, x)), 0xf)), xor(7, mod(r, 3)))

      z := div(add(add(div(x, mul(z, z)), z), z), 3)
      z := div(add(add(div(x, mul(z, z)), z), z), 3)
      z := div(add(add(div(x, mul(z, z)), z), z), 3)
      z := div(add(add(div(x, mul(z, z)), z), z), 3)
      z := div(add(add(div(x, mul(z, z)), z), z), 3)
      z := div(add(add(div(x, mul(z, z)), z), z), 3)
      z := div(add(add(div(x, mul(z, z)), z), z), 3)

      z := sub(z, lt(div(x, mul(z, z)), z))
    }
  }

  /// @dev Returns the square root of `x`, denominated in `WAD`.
  function sqrtWad(uint256 x) internal pure returns (uint256 z) {
    unchecked {
      z = 10 ** 9;
      if (x <= type(uint256).max / 10 ** 36 - 1) {
        x *= 10 ** 18;
        z = 1;
      }
      z *= sqrt(x);
    }
  }

  /// @dev Returns the cube root of `x`, denominated in `WAD`.
  function cbrtWad(uint256 x) internal pure returns (uint256 z) {
    unchecked {
      z = 10 ** 12;
      if (x <= (type(uint256).max / 10 ** 36) * 10 ** 18 - 1) {
        if (x >= type(uint256).max / 10 ** 36) {
          x *= 10 ** 18;
          z = 10 ** 6;
        } else {
          x *= 10 ** 36;
          z = 1;
        }
      }
      z *= cbrt(x);
    }
  }

  /// @dev Returns the factorial of `x`.
  function factorial(uint256 x) internal pure returns (uint256 result) {
    /// @solidity memory-safe-assembly
    assembly {
      if iszero(lt(x, 58)) {
        mstore(0x00, 0xaba0f2a2) // `FactorialOverflow()`.
        revert(0x1c, 0x04)
      }
      for { result := 1 } x { x := sub(x, 1) } { result := mul(result, x) }
    }
  }

  /// @dev Returns the log2 of `x`.
  /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
  /// Returns 0 if `x` is zero.
  function log2(uint256 x) internal pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
      r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
      r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
      r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
      r := or(r, shl(4, lt(0xffff, shr(r, x))))
      r := or(r, shl(3, lt(0xff, shr(r, x))))
      // forgefmt: disable-next-item
      r := or(
        r,
        byte(
          and(0x1f, shr(shr(r, x), 0x8421084210842108cc6318c6db6d54be)),
          0x0706060506020504060203020504030106050205030304010505030400000000
        )
      )
    }
  }

  /// @dev Returns the log2 of `x`, rounded up.
  /// Returns 0 if `x` is zero.
  function log2Up(uint256 x) internal pure returns (uint256 r) {
    r = log2(x);
    /// @solidity memory-safe-assembly
    assembly {
      r := add(r, lt(shl(r, 1), x))
    }
  }

  /// @dev Returns the log10 of `x`.
  /// Returns 0 if `x` is zero.
  function log10(uint256 x) internal pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
      if iszero(lt(x, 100000000000000000000000000000000000000)) {
        x := div(x, 100000000000000000000000000000000000000)
        r := 38
      }
      if iszero(lt(x, 100000000000000000000)) {
        x := div(x, 100000000000000000000)
        r := add(r, 20)
      }
      if iszero(lt(x, 10000000000)) {
        x := div(x, 10000000000)
        r := add(r, 10)
      }
      if iszero(lt(x, 100000)) {
        x := div(x, 100000)
        r := add(r, 5)
      }
      r := add(r, add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999)))))
    }
  }

  /// @dev Returns the log10 of `x`, rounded up.
  /// Returns 0 if `x` is zero.
  function log10Up(uint256 x) internal pure returns (uint256 r) {
    r = log10(x);
    /// @solidity memory-safe-assembly
    assembly {
      r := add(r, lt(exp(10, r), x))
    }
  }

  /// @dev Returns the log256 of `x`.
  /// Returns 0 if `x` is zero.
  function log256(uint256 x) internal pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
      r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
      r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
      r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
      r := or(r, shl(4, lt(0xffff, shr(r, x))))
      r := or(shr(3, r), lt(0xff, shr(r, x)))
    }
  }

  /// @dev Returns the log256 of `x`, rounded up.
  /// Returns 0 if `x` is zero.
  function log256Up(uint256 x) internal pure returns (uint256 r) {
    r = log256(x);
    /// @solidity memory-safe-assembly
    assembly {
      r := add(r, lt(shl(shl(3, r), 1), x))
    }
  }

  /// @dev Returns the scientific notation format `mantissa * 10 ** exponent` of `x`.
  /// Useful for compressing prices (e.g. using 25 bit mantissa and 7 bit exponent).
  function sci(uint256 x) internal pure returns (uint256 mantissa, uint256 exponent) {
    /// @solidity memory-safe-assembly
    assembly {
      mantissa := x
      if mantissa {
        if iszero(mod(mantissa, 1000000000000000000000000000000000)) {
          mantissa := div(mantissa, 1000000000000000000000000000000000)
          exponent := 33
        }
        if iszero(mod(mantissa, 10000000000000000000)) {
          mantissa := div(mantissa, 10000000000000000000)
          exponent := add(exponent, 19)
        }
        if iszero(mod(mantissa, 1000000000000)) {
          mantissa := div(mantissa, 1000000000000)
          exponent := add(exponent, 12)
        }
        if iszero(mod(mantissa, 1000000)) {
          mantissa := div(mantissa, 1000000)
          exponent := add(exponent, 6)
        }
        if iszero(mod(mantissa, 10000)) {
          mantissa := div(mantissa, 10000)
          exponent := add(exponent, 4)
        }
        if iszero(mod(mantissa, 100)) {
          mantissa := div(mantissa, 100)
          exponent := add(exponent, 2)
        }
        if iszero(mod(mantissa, 10)) {
          mantissa := div(mantissa, 10)
          exponent := add(exponent, 1)
        }
      }
    }
  }

  /// @dev Convenience function for packing `x` into a smaller number using `sci`.
  /// The `mantissa` will be in bits [7..255] (the upper 249 bits).
  /// The `exponent` will be in bits [0..6] (the lower 7 bits).
  /// Use `SafeCastLib` to safely ensure that the `packed` number is small
  /// enough to fit in the desired unsigned integer type:
  /// ```
  ///     uint32 packed = SafeCastLib.toUint32(FixedPointMathLib.packSci(777 ether));
  /// ```
  function packSci(uint256 x) internal pure returns (uint256 packed) {
    (x, packed) = sci(x); // Reuse for `mantissa` and `exponent`.
    /// @solidity memory-safe-assembly
    assembly {
      if shr(249, x) {
        mstore(0x00, 0xce30380c) // `MantissaOverflow()`.
        revert(0x1c, 0x04)
      }
      packed := or(shl(7, x), packed)
    }
  }

  /// @dev Convenience function for unpacking a packed number from `packSci`.
  function unpackSci(uint256 packed) internal pure returns (uint256 unpacked) {
    unchecked {
      unpacked = (packed >> 7) * 10 ** (packed & 0x7f);
    }
  }

  /// @dev Returns the average of `x` and `y`.
  function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      z = (x & y) + ((x ^ y) >> 1);
    }
  }

  /// @dev Returns the average of `x` and `y`.
  function avg(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
    }
  }

  /// @dev Returns the absolute value of `x`.
  function abs(int256 x) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(sub(0, shr(255, x)), add(sub(0, shr(255, x)), x))
    }
  }

  /// @dev Returns the absolute distance between `x` and `y`.
  function dist(int256 x, int256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(mul(xor(sub(y, x), sub(x, y)), sgt(x, y)), sub(y, x))
    }
  }

  /// @dev Returns the minimum of `x` and `y`.
  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), lt(y, x)))
    }
  }

  /// @dev Returns the minimum of `x` and `y`.
  function min(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), slt(y, x)))
    }
  }

  /// @dev Returns the maximum of `x` and `y`.
  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), gt(y, x)))
    }
  }

  /// @dev Returns the maximum of `x` and `y`.
  function max(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, y), sgt(y, x)))
    }
  }

  /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
  function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, minValue), gt(minValue, x)))
      z := xor(z, mul(xor(z, maxValue), lt(maxValue, z)))
    }
  }

  /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
  function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := xor(x, mul(xor(x, minValue), sgt(minValue, x)))
      z := xor(z, mul(xor(z, maxValue), slt(maxValue, z)))
    }
  }

  /// @dev Returns greatest common divisor of `x` and `y`.
  function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      for { z := x } y {} {
        let t := y
        y := mod(z, y)
        z := t
      }
    }
  }

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                   RAW NUMBER OPERATIONS                    */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /// @dev Returns `x + y`, without checking for overflow.
  function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x + y;
    }
  }

  /// @dev Returns `x + y`, without checking for overflow.
  function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      z = x + y;
    }
  }

  /// @dev Returns `x - y`, without checking for underflow.
  function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x - y;
    }
  }

  /// @dev Returns `x - y`, without checking for underflow.
  function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      z = x - y;
    }
  }

  /// @dev Returns `x * y`, without checking for overflow.
  function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      z = x * y;
    }
  }

  /// @dev Returns `x * y`, without checking for overflow.
  function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      z = x * y;
    }
  }

  /// @dev Returns `x / y`, returning 0 if `y` is zero.
  function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := div(x, y)
    }
  }

  /// @dev Returns `x / y`, returning 0 if `y` is zero.
  function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := sdiv(x, y)
    }
  }

  /// @dev Returns `x % y`, returning 0 if `y` is zero.
  function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := mod(x, y)
    }
  }

  /// @dev Returns `x % y`, returning 0 if `y` is zero.
  function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := smod(x, y)
    }
  }

  /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
  function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := addmod(x, y, d)
    }
  }

  /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
  function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      z := mulmod(x, y, d)
    }
  }
}

interface ILocker {
  function acceptGovernance() external;

  function claimRewards(address _rewardToken, address _recipient) external;

  function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);

  function increaseAmount(uint256 _amount) external;

  function increaseUnlockTime(uint256 _time) external;

  function release() external;

  function release(address _recipient) external;

  function setGovernance(address _gov) external;

  function setStrategy(address _strategy) external;

  function transferGovernance(address _governance) external;

  function governance() external view returns (address);
}

interface ICakeNfpm {
  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function positions(uint256)
    external
    view
    returns (uint96, address, address, address, uint24, int24, int24, uint128, uint256, uint256, uint128, uint128);
}

interface IExecutor {
  function callExecuteTo(
    address _executor,
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external returns (bool success_, bytes memory result_);

  function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool success_, bytes memory result_);
}

library SafeExecute {
  error CALL_FAILED();

  function safeExecute(ILocker locker, address to, uint256 value, bytes memory data) internal returns (bool success) {
    (success,) = locker.execute(to, value, data);
  }
}

/// @notice Main access point of Cake Locker.
contract StakeDAOStrategy is ReentrancyGuard, UUPSUpgradeable {
  using FixedPointMathLib for uint256;
  using SafeExecute for ILocker;
  using SafeERC20 for IERC20;

  struct CollectedFees {
    uint256 token0Amount;
    uint256 token1Amount;
  }

  /// @notice Denominator for fixed point math.
  uint256 public constant DENOMINATOR = 10_000;

  /// @notice Address of the locker contract.
  ILocker public immutable locker;

  /// @notice Address of the token being rewarded.
  IERC20 public immutable rewardToken;

  /// @notice PancakeSwap non fungible position manager.
  INFTPositionManager public immutable nonFungiblePositionManager;

  /// @notice Address of the executor contract.
  IExecutor public executor;

  /// @notice Address of the governance.
  address public governance;

  /// @notice Address of the future governance contract.
  address public futureGovernance;

  /// @notice Address accruing protocol fees.
  address public feeReceiver;

  /// @notice Percentage of fees charged on `rewardToken` claimed.
  uint256 public protocolFeesPercent;

  /// @notice Amount of fees charged on `rewardToken` claimed
  uint256 public feesAccrued;

  /// @notice Reward claimer.
  address public rewardClaimer;

  /// @notice Mapping of User -> TokenId
  mapping(uint256 => address) public positionOwner; // tokenId -> user

  ////////////////////////////////////////////////////////////////
  /// --- EVENTS & ERRORS
  ///////////////////////////////////////////////////////////////

  /// @notice Event emitted at every fee collected by stakers.
  /// @param token0 Address of token0.
  /// @param token1 Address of token1.
  /// @param token0Collected Amount of token0 collected.
  /// @param token1Collected Amount of token1 collected.
  event FeeCollected(address indexed token0, address indexed token1, uint256 token0Collected, uint256 token1Collected);

  /// @notice Event emitted when governance is changed.
  /// @param newGovernance Address of the new governance.
  event GovernanceChanged(address newGovernance);

  /// @notice Event emitted when the fees are claimed
  /// @param feeReceiver fee receiver
  /// @param feeClaimed amount of fees claimed
  event ProtocolFeeClaimed(address indexed feeReceiver, uint256 feeClaimed);

  /// @notice Event emitted at every harvest
  /// @param tokenId nft id harvested for
  /// @param amount amount harvested
  /// @param recipient reward recipient
  event Harvest(uint256 indexed tokenId, uint256 amount, address recipient);

  /// @notice Error emitted when input address is null
  error AddressNull();

  /// @notice Error emitted when call failed
  error CallFailed();

  /// @notice Error emitted when auth failed
  error Governance();

  /// @notice Error emitted when sum of fees is above 100%
  error FeeTooHigh();

  /// @notice throwed when the ERC721 hook has not called by cake nfpm
  error NotPancakeNFT();

  /// @notice Error emitted when auth failed
  error Unauthorized();

  //////////////////////////////////////////////////////
  /// --- MODIFIERS
  //////////////////////////////////////////////////////

  modifier onlyPositionOwner(uint256 tokenId) {
    if (msg.sender != positionOwner[tokenId]) revert Unauthorized();
    _;
  }

  modifier onlyPositionOwnerOrClaimer(uint256[] memory tokenIds) {
    if (msg.sender != rewardClaimer) {
      for (uint256 i; i < tokenIds.length;) {
        if (msg.sender != positionOwner[tokenIds[i]]) revert Unauthorized();
        unchecked {
          ++i;
        }
      }
    }
    _;
  }

  modifier onlyGovernance() {
    if (msg.sender != governance) revert Unauthorized();
    _;
  }

  /// @notice Constructor.
  /// @param _governance Address of the strategy governance.
  /// @param _locker Address of the locker.
  /// @param _rewardToken Address of the reward token.
  /// @param _manager Address of the nft position manager
  constructor(address _governance, address _locker, address _rewardToken, address _manager) {
    governance = _governance;
    locker = ILocker(_locker);
    rewardToken = IERC20(_rewardToken);
    nonFungiblePositionManager = INFTPositionManager(_manager);
  }

  /// @notice Initialize function.
  /// @param _governance Address of the governance.
  /// @param _executor Address of the executor.
  function initialize(address _governance, address _executor) external {
    if (governance != address(0)) revert AddressNull();
    governance = _governance;
    executor = IExecutor(_executor);
  }

  /// @notice Harvest reward for NFTs.
  /// @param _tokenIds NFT ids to harvest.
  /// @param _recipient Address of the recipient.
  function harvestRewards(
    uint256[] memory _tokenIds,
    address _recipient
  ) external nonReentrant onlyPositionOwnerOrClaimer(_tokenIds) returns (uint256[] memory) {
    uint256 tokensLength = _tokenIds.length;
    uint256[] memory rewards = new uint256[](tokensLength);
    for (uint256 i; i < tokensLength;) {
      rewards[i] = _harvestReward(_tokenIds[i], 0x0, _recipient);
      unchecked {
        ++i;
      }
    }
    return rewards;
  }

  /// @notice Harvest fees for NFTs.
  /// @param _tokenIds NFT ids to harvest fees for.
  /// @param _recipient Address of the recipient.
  function collectFees(
    uint256[] memory _tokenIds,
    address _recipient
  ) external nonReentrant onlyPositionOwnerOrClaimer(_tokenIds) returns (CollectedFees[] memory _collected) {
    uint256 tokensLength = _tokenIds.length;
    _collected = new CollectedFees[](tokensLength);

    uint256 token0Collected;
    uint256 token1Collected;
    for (uint256 i; i < tokensLength;) {
      (token0Collected, token1Collected) = (_collectFee(_tokenIds[i], _recipient));
      _collected[i] = CollectedFees(token0Collected, token1Collected);

      unchecked {
        i++;
      }
    }
  }

  /// @notice Harvest both reward and fees for NFTs.
  /// @param _tokenIds NFT ids to harvest.
  function harvestAndCollectFees(
    uint256[] memory _tokenIds,
    address _recipient
  ) external nonReentrant onlyPositionOwnerOrClaimer(_tokenIds) returns (uint256[] memory _rewards, CollectedFees[] memory _collected) {
    uint256 tokenLength = _tokenIds.length;
    _rewards = new uint256[](tokenLength);
    _collected = new CollectedFees[](tokenLength);

    uint256 token0Collected;
    uint256 token1Collected;

    for (uint256 i; i < tokenLength;) {
      _rewards[i] = _harvestReward(_tokenIds[i], 0x0, _recipient);
      (token0Collected, token1Collected) = _collectFee(_tokenIds[i], _recipient);
      _collected[i] = CollectedFees(token0Collected, token1Collected);
      unchecked {
        i++;
      }
    }
  }

  /// @notice Withdraw the NFT sending it to the recipient.
  /// @param _tokenId NFT id to withdraw.
  function withdraw(uint256 _tokenId) external nonReentrant returns (uint256 reward) {
    reward = _withdraw(_tokenId, 0x0, msg.sender);
  }

  /// @notice Withdraw the NFT sending it to the recipient.
  /// @param _tokenId NFT id to withdraw.
  /// @param _recipient NFT receiver.
  function withdraw(uint256 _tokenId, address _recipient) external nonReentrant returns (uint256 reward) {
    reward = _withdraw(_tokenId, 0x0, _recipient);
  }

  /// @notice Hook triggered within safe function calls.
  /// @param _from NFT sender.
  /// @param _tokenId NFT id received
  function onERC721Received(address, address _from, uint256 _tokenId, bytes calldata) external returns (bytes4) {
    if (msg.sender != address(nonFungiblePositionManager)) revert NotPancakeNFT();
    if (_from == address(nonFungiblePositionManager)) return this.onERC721Received.selector;

    // store the owner's tokenId
    positionOwner[_tokenId] = _from;

    // transfer the NFT to the cake locker using the non safe transfer to not trigger the hook
    nonFungiblePositionManager.transferFrom(address(this), address(locker), _tokenId);

    return this.onERC721Received.selector;
  }

  //////////////////////////////////////////////////////
  /// --- INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////

  /// @notice Internal function to harvest reward for an NFT.
  /// @param _tokenId NFT id to harvest.
  /// @param _recipient reward recipient
  function _harvestReward(uint256 _tokenId, bytes32 _assetHash, address _recipient) internal returns (uint256 reward) {
    reward = nonFungiblePositionManager.getReward(_tokenId, _assetHash);

    if (reward != 0) {
      // charge fee
      reward -= _chargeProtocolFees(reward);

      // send the reward - fees to the recipient
      SafeERC20.safeTransfer(rewardToken, _recipient, reward);

      emit Harvest(_tokenId, reward, _recipient);
    }
  }

  /// @notice Internal function to withdraw the NFT sending it to the recipient.
  /// @param _tokenId NFT id to withdraw.
  /// @param _recipient NFT recipient
  function _withdraw(
    uint256 _tokenId,
    bytes32 _assetHash,
    address _recipient
  ) internal onlyPositionOwner(_tokenId) returns (uint256 reward) {
    reward = _harvestReward(_tokenId, _assetHash, _recipient);
    nonFungiblePositionManager.safeTransferFrom(address(this), _recipient, _tokenId);
    delete positionOwner[_tokenId];
  }

  //////////////////////////////////////////////////////
  /// --- PROTOCOL FEES ACCOUNTING
  //////////////////////////////////////////////////////

  /// @notice Claim protocol fees and send them to the fee receiver.
  function claimProtocolFees() external {
    if (feesAccrued == 0) return;
    if (feeReceiver == address(0)) revert AddressNull();

    uint256 _feesAccrued = feesAccrued;
    feesAccrued = 0;

    SafeERC20.safeTransfer(rewardToken, feeReceiver, _feesAccrued);

    emit ProtocolFeeClaimed(feeReceiver, _feesAccrued);
  }

  /// @notice Internal function to charge protocol fees from `rewardToken` claimed by the locker.
  /// @return _amount Amount left after charging protocol fees.
  function _chargeProtocolFees(uint256 amount) internal returns (uint256) {
    if (amount == 0 || protocolFeesPercent == 0) return 0;

    uint256 _feeAccrued = amount.mulDiv(protocolFeesPercent, DENOMINATOR);
    feesAccrued += _feeAccrued;

    return _feeAccrued;
  }

  //////////////////////////////////////////////////////
  /// --- GOVERNANCE STRATEGY SETTERS
  //////////////////////////////////////////////////////

  /// @notice Transfer the governance to a new address.
  /// @param _governance Address of the new governance.
  function transferGovernance(address _governance) external onlyGovernance {
    futureGovernance = _governance;
  }

  /// @notice Accept the governance transfer.
  function acceptGovernance() external {
    if (msg.sender != futureGovernance) revert Governance();

    governance = msg.sender;
    futureGovernance = address(0);

    emit GovernanceChanged(msg.sender);
  }

  /// @notice Set FeeReceiver new address.
  /// @param _feeReceiver Address of new FeeReceiver.
  function setFeeReceiver(address _feeReceiver) external onlyGovernance {
    if (_feeReceiver == address(0)) revert AddressNull();
    feeReceiver = _feeReceiver;
  }

  /// @notice Set Executor new address.
  /// @param _executor Address of new executor.
  function setExecutor(address _executor) external onlyGovernance {
    executor = IExecutor(_executor);
  }

  /// @notice Set reward claimer.
  /// @param _rewardClaimer Address of the claimer.
  function setRewardClaimer(address _rewardClaimer) external onlyGovernance {
    rewardClaimer = _rewardClaimer;
  }

  /// @notice Update protocol fees.
  /// @param protocolFee New protocol fee.
  function updateProtocolFee(uint256 protocolFee) external onlyGovernance {
    if (protocolFee > DENOMINATOR) revert FeeTooHigh();
    protocolFeesPercent = protocolFee;
  }

  //////////////////////////////////////////////////////
  /// --- GOVERNANCE OR ALLOWED FUNCTIONS
  //////////////////////////////////////////////////////

  /// @notice Execute a function.
  /// @param to Address of the contract to execute.
  /// @param value Value to send to the contract.
  /// @param data Data to send to the contract.
  /// @return success_ Boolean indicating if the execution was successful.
  /// @return result_ Bytes containing the result of the execution.
  function execute(address to, uint256 value, bytes calldata data) external onlyGovernance returns (bool, bytes memory) {
    (bool success, bytes memory result) = to.call{value: value}(data);
    return (success, result);
  }

  /// UUPS Upgradeability.
  function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}

  function _collectFee(uint256 _tokenId, address _recipient) internal returns (uint256, uint256) {
    // // fetch underlying tokens
    // (, , address token0, address token1, , , , , , , , ) = ICakeNfpm(nonFungiblePositionManager).positions(_tokenId);

    // // collect fees if there is any and transfer here
    // bytes memory harvestData = abi.encodeWithSignature(
    //   'collect((uint256,address,uint128,uint128))',
    //   _tokenId,
    //   address(this),
    //   type(uint128).max,
    //   type(uint128).max
    // );
    // (bool success, bytes memory result) = executor.callExecuteTo(address(locker), masterchef, 0, harvestData);
    // if (!success) revert CallFailed();

    // (uint256 token0Collected, uint256 token1Collected) = abi.decode(result, (uint256, uint256));

    // // transfer token0 collected to the recipient
    // if (token0Collected != 0) {
    //   SafeTransferLib.safeTransfer(token0, _recipient, token0Collected);
    // }

    // // transfer token1 collected to the recipient
    // if (token1Collected != 0) {
    //   SafeTransferLib.safeTransfer(token1, _recipient, token1Collected);
    // }

    // emit FeeCollected(token0, token1, token0Collected, token1Collected);

    return (0, 0);
  }

  receive() external payable {}
}
