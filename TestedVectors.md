# Tested Attack Vectors

This document tracks the security vectors evaluated via unit tests.

## Limit Order With No Outputs
- **Vector:** Execute a `LimitOrder` where the `outputs` array is empty.
- **Result:** Order executes successfully, transferring the swapper's input tokens to the filler without providing any output tokens. The absence of validation allows trivial token theft.
- **Status:** **Bug discovered** – see `testExecuteNoOutputs` in `LimitOrderReactorZeroOutputs.t.sol`.
