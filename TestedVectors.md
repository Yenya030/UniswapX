# Tested Attack Vectors

This document lists the security related vectors that have been explored via automated tests.

## 1. Exclusivity Override BPS Overflow

- **Vector**: Provide an `exclusivityOverrideBps` value close to `uint256` max so that adding it to `BPS` could overflow.
- **Test**: `ExclusivityLibOverflowTest.testExclusivityOverrideBpsOverflow` ensures that such an input triggers a revert and does not lead to an unchecked overflow.
- **Result**: No bug – the addition uses Solidity's checked arithmetic and correctly reverts.

## 2. Fee Injection Memory Safety

- **Vector**: Verify that `_prepare` does not mutate caller-provided memory while still injecting protocol fee outputs correctly.
- **Test**: `BaseReactorTest.test_base_prepareFeeOutputsVanishing` (existing) confirms the input array is unchanged while fees are applied internally.
- **Result**: No bug – protocol fee logic works as intended.
