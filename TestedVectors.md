# Tested Attack Vectors

This document tracks manual fuzzing and unit tests exploring potential vulnerabilities in the repository.

## Reentrancy via Callback

*Vector*: A malicious fill contract reenters the same reactor during its `reactorCallback` hook to execute a second order.

*Test*: `testReentrancySameReactor` (added in `LimitOrderReactor.t.sol`) deploys `MockFillContractReentrant` and attempts to perform such reentrancy.

*Result*: The transaction reverts with `"ReentrancyGuard: reentrant call"`, demonstrating the built‑in guard prevents this attack.

No other new issues were discovered while examining this vector.
