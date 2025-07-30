# Tested Attack Vectors

This document tracks attack vectors that have been tested in this repository.

## 1. Leftover ETH Drain
- **Description**: If any Ether is sent directly to a reactor contract, the next call to `execute` refunds the contract balance to the caller. A malicious filler could therefore claim Ether that was mistakenly sent to the reactor.
- **Test**: `testLeftoverEthRefundedToFiller` in `test/base/EthOutput.t.sol` deposits 1 ETH from a third party into the reactor, then executes an order. The filler receives the leftover ETH and the reactor balance returns to zero.
- **Result**: No reverts occurred; the filler successfully drained the deposited ETH. This is an expected behavior of the contract but could allow opportunistic actors to collect accidental deposits.

## 2. Reentrancy via Nested Execution
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

## 1. Leftover ETH Drain
- **Description**: If any Ether is sent directly to a reactor contract, the next call to `execute` refunds the contract balance to the caller. A malicious filler could therefore claim Ether that was mistakenly sent to the reactor.
- **Test**: `testLeftoverEthRefundedToFiller` in `test/base/EthOutput.t.sol` deposits 1 ETH from a third party into the reactor, then executes an order. The filler receives the leftover ETH and the reactor balance returns to zero.
- **Result**: No reverts occurred; the filler successfully drained the deposited ETH. This is an expected behavior of the contract but could allow opportunistic actors to collect accidental deposits.

## 2. Reentrancy via Nested Execution
- **Description**: A fill contract might attempt to execute another order during the callback to cause reentrancy.
- **Test**: `test_base_executeTwoReactorsAtOnce` in `test/base/BaseReactor.t.sol` uses `MockFillContractDoubleExecution` to trigger a nested execution across two reactors.
- **Result**: Both orders execute once without reentrancy issues, confirming the `nonReentrant` guard is effective.
