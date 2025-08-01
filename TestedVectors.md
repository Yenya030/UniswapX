
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

## Dutch Order With No Outputs
- **Vector:** Execute a `DutchOrder` where the `outputs` array is empty.
- **Result:** Order executes successfully, transferring the swapper's input tokens to the filler without providing any output tokens. The absence of validation allows trivial token theft.
- **Status:** **Bug discovered** – see `testExecuteNoOutputs` in `DutchOrderReactorZeroOutputs.t.sol`.


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


## Double Execution Across Reactors
**Description**: Using a custom fill contract to execute an order on one reactor while triggering execution on a second reactor during the callback.
**Result**: Existing tests show this succeeds without violating state, demonstrating the contract safely handles separate reactor calls.

## Nonlinear Dutch Order with Unsorted Blocks
- **Description**: Craft a `NonlinearDutchDecay` curve with `relativeBlocks` that are not strictly increasing.
- **Test**: `NonlinearDutchDecayLibOutOfOrderTest.testOutOfOrderBlocks` executes such a curve and shows the decay increases to an unexpected amount instead of reverting.
- **Result**: **Bug discovered** – library accepts out-of-order curves leading to unintuitive decayed values.


## Callback Order Mutation
- **Description**: `executeWithCallback` hands `ResolvedOrder` data to the fill contract. We tested whether mutating this memory during the callback could redirect tokens.
- **Test**: `LimitOrderReactorTamperTest.testCallbackCanModifyOutputs` uses `MockFillContractTamper` to change the output recipient in-place during the callback.
- **Result**: The modifications do not persist and the order still pays the original recipient, so this vector is safely handled.


## Priority Fee Overflow
- **Description**: Scaling factors in `PriorityFeeLib` multiply `priorityFee` by `mpsPerPriorityFeeWei` without overflow checks. Extremely large values wrap, leaving orders unscaled.
- **Test**: `testScaleInputPriorityFeeOverflow` in `test/lib/PriorityFeeLib.t.sol` uses a huge `priorityFee` that should zero out the input but instead returns the original amount.
- **Result**: **Bug discovered** – unchecked multiplication allows overflow leading to incorrect scaling.

## Priority Fee Output Overflow
- **Description**: Output scaling in `PriorityFeeLib` multiplies `priorityFee` by `mpsPerPriorityFeeWei`. Providing an extremely large priority fee triggers an arithmetic overflow panic.
- **Test**: `testScaleOutputPriorityFeeOverflow` in `test/lib/PriorityFeeLibOutputOverflow.t.sol` uses a huge priority fee and observes the panic.
- **Result**: **Bug discovered** – overflow causes a panic instead of graceful scaling.



## Priority Order With No Outputs
- **Vector:** Execute a `PriorityOrder` where the `outputs` array is empty.
- **Result:** Order executes successfully, transferring the swapper's input tokens to the filler without providing any output tokens. The absence of validation allows trivial token theft.
- **Status:** **Bug discovered** – see `testExecuteNoOutputs` in `PriorityOrderReactorZeroOutputs.t.sol`.


## Leftover ETH refund to non-payable filler
- **Description**: The reactor refunds any ETH balance to the filler after execution. If the filler contract refuses ETH, this refund reverts and halts order execution. An attacker can send ETH to the reactor to block such fillers.
- **Test**: `EthOutputNoReceiveTest.testRefundToNonPayableReverts` deploys a `MockFillContractNoReceive` without a payable fallback. After sending stray ETH to the reactor, executing an order reverts with `NativeTransferFailed`.
- **Result**: **Bug discovered** – leftover ETH can be used to grief non-payable fillers.

## V2DutchOrder cosigner output override ignored
- **Description**: Suspected that `CosignerData.outputAmounts` might not update `baseOutputs` in `V2DutchOrderReactor` because the update function does not explicitly write back to the array.
- **Test**: `V2DutchOrderOutputOverrideBugTest.testOutputOverrideIgnored` signs an order with a higher cosigned output amount. The swapper receives the higher amount, proving the override logic works.
- **Result**: No bug – the memory reference updates the array correctly so cosigner overrides are honored.


## Zero Recipient Output
- **Vector:** Execute a `LimitOrder` where the output recipient is the zero address.
- **Test:** `LimitOrderReactorZeroRecipientTest.testExecuteZeroRecipient` burns the output tokens by sending them to `address(0)`.
- **Result:** Order executes successfully and tokens are irretrievably sent to the zero address, demonstrating missing validation for recipient addresses.


## V3 cross-chain cosigner signature replay
- **Summary**: Attempt to reuse a cosigner signature on a different chain when executing a `V3DutchOrder`.
- **Result**: The reactor rejects the transaction. The cosigner digest includes `block.chainid`, binding the signature to a specific chain.
- **Validation**: `forge test --match-path test/reactors/V3DutchOrderChainReplay.t.sol` passes, confirming the protection.


## Cosigner Output Override
- **Description**: Confirm that cosigner-provided output amounts in `V2DutchOrder` correctly override the swapper signed values.
- **Test**: `V2DutchOrderOutputOverrideTest.test_outputOverrideBug` fills an order where the cosigner specifies a higher output amount.
- **Result**: No bug – the swapper receives the cosigned amount, proving the override logic functions.


## Leftover ETH Drain via Empty Batch
- **Description**: Anyone can reclaim stray ETH by calling `executeBatch` with an empty array, causing the reactor to refund its entire balance to the caller.
- **Test**: `EthOutputTest.testEmptyBatchRefundsLeftoverEth` sends ETH to the reactor then executes an empty batch, receiving the deposit back.
- **Result**: **Bug discovered** – reactor exposes a simple ETH drain even without valid orders.


## Exclusive Dutch Order With No Outputs
- **Vector:** Execute an `ExclusiveDutchOrder` where the `outputs` array is empty.
- **Result:** Order executes successfully, transferring the swapper's input tokens to the filler without providing any output tokens. The absence of validation allows trivial token theft.
- **Status:** **Bug discovered** – see `testExecuteNoOutputs` in `ExclusiveDutchOrderReactorZeroOutputs.t.sol`.

## UniversalRouterExecutor leftover approvals
- **Description**: The `UniversalRouterExecutor` permanently approves Permit2 to spend tokens during `reactorCallback`. A malicious router could later drain tokens via Permit2.
- **Test**: `UniversalRouterExecutorAllowanceAttackTest.testFillerCanDrainApprovedTokens` confirms the approval remains after callback.
- **Result**: **Bug discovered** – allowance to Permit2 persists allowing potential token drain.


## Dutch Order With Zero Recipient
- **Vector:** Execute a `DutchOrder` where an output recipient is the zero address.
- **Test:** `DutchOrderReactorZeroRecipientTest.testExecuteZeroRecipient` burns the output tokens by sending them to `address(0)`.
- **Result:** Order executes successfully and tokens are irretrievably sent to the zero address, showing missing validation.


## Limit Order With Zero Input
- **Vector:** Execute a `LimitOrder` where the input token is the zero address and amount is zero.
- **Result:** Order executes and the filler sends output tokens but receives no input because transferring from the zero address succeeds with no effect.
- **Status:** **Bug discovered** – see `testExecuteZeroInput` in `LimitOrderReactorZeroInput.t.sol`.
## Dutch Order With Zero Input
- **Vector:** Execute a `DutchOrder` where the input token is the zero address and amount is zero.
- **Result:** Order executes successfully, transferring output tokens without receiving any input due to the empty token address transfer succeeding.
- **Status:** **Bug discovered** – see `testExecuteZeroInput` in `DutchOrderReactorZeroInput.t.sol`.

## Permit2 Nonce Reuse Across Reactors
- **Vector:** Reuse the same Permit2 nonce for orders on different reactors.
- **Test:** `test_base_nonceReuseAcrossReactors` in `BaseReactor.t.sol` executes an order on one reactor then attempts to fill another order with the same nonce on a second reactor.
- **Result:** The second fill reverts with `InvalidNonce`, showing nonces are globally enforced.


## Priority Order With Zero Input
- **Vector:** Execute a `PriorityOrder` where the input token is the zero address and amount is zero.
- **Test:** `PriorityOrderReactorZeroInputTest.testExecuteZeroInput` demonstrates that the order executes without transferring any input tokens.
- **Result:** **Bug discovered** – filler provides output tokens while receiving no input due to missing validation.
