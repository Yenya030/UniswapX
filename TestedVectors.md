# Tested Attack Vectors

## OrderQuoter Token Theft Attempt

We tested whether invoking `OrderQuoter.quote` with a fully signed order could transfer tokens from the swapper to the caller since `OrderQuoter.quote` executes `executeWithCallback` on the reactor. The test `testQuoteDoesNotTransferTokens` ensures token balances of both the swapper and the quoter remain unchanged after quoting, confirming the revert prevents any transfer.
