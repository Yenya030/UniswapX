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
