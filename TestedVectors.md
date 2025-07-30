# Attack Vectors Tested

## Reentrancy via Callback
- **Description**: Attempted to execute one reactor from another in a callback to test for reentrancy.
- **Result**: Handled correctly by `ReentrancyGuard`. Existing test `test_base_executeTwoReactorsAtOnce` passes indicating no vulnerability.

## Large Gas Adjustment Values
- **Description**: Tested `V3DutchOrderReactor` with extremely large gas adjustment parameters to look for overflow.
- **Result**: Protocol handled the large values without overflow; existing arithmetic checks prevented failures.

## Exclusivity Override BPS Overflow
- **Description**: Passing `type(uint256).max` as `exclusivityOverrideBps` to `ExclusivityLib.handleExclusiveOverrideTimestamp` causes the addition `BPS + exclusivityOverrideBps` to overflow.
- **Result**: Overflow wraps the value and the override is effectively ignored. Demonstrated in new test `ExclusivityLibOverflowTest`.
