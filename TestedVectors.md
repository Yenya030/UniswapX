# Tested Attack Vectors

## 1. Mismatched Nonlinear Dutch Decay arrays

- **Description**: Craft a `NonlinearDutchDecay` struct where `relativeBlocks` encodes more block points than provided in `relativeAmounts`.
- **Expectation**: The order decoding should revert with `InvalidDecayCurve` instead of silently misbehaving.
- **Result**: Before patch the library allowed this mismatch and the provided test `NonlinearDutchDecayLibBugTest` failed. After introducing a length check the test passes confirming the bug is fixed.

