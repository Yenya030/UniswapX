# Tested Attack Vectors

## Cross-chain cosigner signature replay
- **Summary**: Attempt to reuse a cosigner signature on a different chain when executing a `V2DutchOrder`.
- **Result**: The reactor rejects the transaction. The cosigner digest includes `block.chainid`, binding the signature to a specific chain.
- **Validation**: `forge test --match-path test/reactors/V2DutchOrderChainReplay.t.sol` passes, confirming the protection.

## Reentrancy via chained reactor execution
- **Summary**: A fill contract tries to execute another reactor within its callback, potentially leading to reentrancy issues.
- **Result**: Both orders execute correctly and no reentrancy issue was observed because `ReentrancyGuard` blocks reentrancy into the same reactor and different reactors operate independently.
- **Validation**: `forge test --match-path test/base/BaseReactor.t.sol --match-test test_base_executeTwoReactorsAtOnce` passes.
