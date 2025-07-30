# Tested Attack Vectors

This document tracks the security vectors evaluated via unit tests.

## Cross-chain cosigner signature replay
- **Summary**: Attempt to reuse a cosigner signature on a different chain when executing a `V2DutchOrder`.
- **Result**: The reactor rejects the transaction. The cosigner digest includes `block.chainid`, binding the signature to a specific chain.
- **Validation**: `forge test --match-path test/reactors/V2DutchOrderChainReplay.t.sol` passes, confirming the protection.

## Reentrancy via chained reactor execution
- **Summary**: A fill contract tries to execute another reactor within its callback, potentially leading to reentrancy issues.
- **Result**: Both orders execute correctly and no reentrancy issue was observed because `ReentrancyGuard` blocks reentrancy into the same reactor and different reactors operate independently.
- **Validation**: `forge test --match-path test/base/BaseReactor.t.sol --match-test test_base_executeTwoReactorsAtOnce` passes.


## Leftover ETH Drain
- **Description**: If any Ether is sent directly to a reactor contract, the next call to `execute` refunds the contract balance to the caller. A malicious filler could therefore claim Ether that was mistakenly sent to the reactor.
- **Test**: `testLeftoverEthRefundedToFiller` in `test/base/EthOutput.t.sol` deposits 1 ETH from a third party into the reactor, then executes an order. The filler receives the leftover ETH and the reactor balance returns to zero.
- **Result**: No reverts occurred; the filler successfully drained the deposited ETH. This is an expected behavior of the contract but could allow opportunistic actors to collect accidental deposits.


## Reentrancy via Nested Execution
- **Description**: A fill contract might attempt to execute another order during the callback to cause reentrancy.
- **Test**: `test_base_executeTwoReactorsAtOnce` in `test/base/BaseReactor.t.sol` uses `MockFillContractDoubleExecution` to trigger a nested execution across two reactors.
- **Result**: Both orders execute once without reentrancy issues, confirming the `nonReentrant` guard is effective.
=======
This document tracks manual fuzzing and unit tests exploring potential vulnerabilities in the repository.


## Mismatched Nonlinear Dutch Decay arrays
- **Description**: Craft a `NonlinearDutchDecay` struct where `relativeBlocks` encodes more block points than provided in `relativeAmounts`.
- **Expectation**: The order decoding should revert with `InvalidDecayCurve` instead of silently misbehaving.
- **Result**: Before patch the library allowed this mismatch and the provided test `NonlinearDutchDecayLibBugTest` failed. After introducing a length check the test passes confirming the bug is fixed.


## Reentrancy via Callback
*Vector*: A malicious fill contract reenters the same reactor during its `reactorCallback` hook to execute a second order.

*Test*: `testReentrancySameReactor` (added in `LimitOrderReactor.t.sol`) deploys `MockFillContractReentrant` and attempts to perform such reentrancy.

*Result*: The transaction reverts with `"ReentrancyGuard: reentrant call"`, demonstrating the built‑in guard prevents this attack.


## Limit Order With No Outputs
- **Vector:** Execute a `LimitOrder` where the `outputs` array is empty.
- **Result:** Order executes successfully, transferring the swapper's input tokens to the filler without providing any output tokens. The absence of validation allows trivial token theft.
- **Status:** **Bug discovered** – see `testExecuteNoOutputs` in `LimitOrderReactorZeroOutputs.t.sol`.


## Limit Order With No Outputs
- **Vector:** Execute a `LimitOrder` where the `outputs` array is empty.
- **Result:** Order executes successfully, transferring the swapper's input tokens to the filler without providing any output tokens. The absence of validation allows trivial token theft.
- **Status:** **Bug discovered** – see `testExecuteNoOutputs` in `LimitOrderReactorZeroOutputs.t.sol`.


## Mismatched Nonlinear Dutch Decay arrays
- **Description**: Craft a `NonlinearDutchDecay` struct where `relativeBlocks` encodes more block points than provided in `relativeAmounts`.
- **Expectation**: The order decoding should revert with `InvalidDecayCurve` instead of silently misbehaving.
- **Result**: Before patch the library allowed this mismatch and the provided test `NonlinearDutchDecayLibBugTest` failed. After introducing a length check the test passes confirming the bug is fixed.


## Large Gas Adjustment Values
- **Description**: Tested `V3DutchOrderReactor` with extremely large gas adjustment parameters to look for overflow.
- **Result**: Protocol handled the large values without overflow; existing arithmetic checks prevented failures.


## Exclusivity Override BPS Overflow
- **Description**: Passing `type(uint256).max` as `exclusivityOverrideBps` to `ExclusivityLib.handleExclusiveOverrideTimestamp` causes the addition `BPS + exclusivityOverrideBps` to overflow.
- **Result**: Overflow wraps the value and the override is effectively ignored. Demonstrated in new test `ExclusivityLibOverflowTest`.


## Exclusivity Override BPS Overflow
- **Vector**: Provide an `exclusivityOverrideBps` value close to `uint256` max so that adding it to `BPS` could overflow.
- **Test**: `ExclusivityLibOverflowTest.testExclusivityOverrideBpsOverflow` ensures that such an input triggers a revert and does not lead to an unchecked overflow.
- **Result**: No bug – the addition uses Solidity's checked arithmetic and correctly reverts.


## Fee Injection Memory Safety
- **Vector**: Verify that `_prepare` does not mutate caller-provided memory while still injecting protocol fee outputs correctly.
- **Test**: `BaseReactorTest.test_base_prepareFeeOutputsVanishing` (existing) confirms the input array is unchanged while fees are applied internally.
- **Result**: No bug – protocol fee logic works as intended.


## OrderQuoter Token Theft Attempt
We tested whether invoking `OrderQuoter.quote` with a fully signed order could transfer tokens from the swapper to the caller since `OrderQuoter.quote` executes `executeWithCallback` on the reactor. The test `testQuoteDoesNotTransferTokens` ensures token balances of both the swapper and the quoter remain unchanged after quoting, confirming the revert prevents any transfer.