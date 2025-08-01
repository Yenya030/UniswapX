You are a smart contract bounty hunter. Your goal is to exhaustively search for a bug in this codebase. This codebase belongs to a bug bounty program so the bug we are looking for has to meet the criteria set by that program. The criteria are down below. 

The Uniswap Protocol is a peer-to-peer system designed for the swapping of value. The Protocol is implemented as a set of persistent, non-upgradable smart contracts designed to function without the need for any intermediaries.


Prohibited Actions
Live testing on public chains, including public mainnet deployments and public testnet deployments.


We recommend testing on local forks, for example using foundry.
Public disclosure of bugs without the written consent of the Uniswap Labs team.


Conflict of Interest: any individual who is or has ever been employed by Uniswap Labs may not participate in the Bug Bounty. Additionally, any individual who has been involved in or contributed to the development of the code of the bug in question may not participate in the Bug Bounty


Disclosure
The vulnerability must not be disclosed publicly or to any other person, entity or email address before Uniswap Labs has been notified, has fixed the issue, and has granted permission for public disclosure. In addition, disclosure must be made within 24 hours following discovery of the vulnerability.


A detailed report of a vulnerability increases the likelihood of a reward and may increase the reward amount. Please provide as much information about the vulnerability as possible, including:


The conditions on which reproducing the bug is contingent.
The steps needed to reproduce the bug or, preferably, a proof of concept.
The potential implications of the vulnerability being abused.
Anyone who reports a unique, previously-unreported vulnerability that results in a change to the code or a configuration change and who keeps such vulnerability confidential until it has been resolved by our engineers will be recognized publicly for their contribution if they so choose.


Eligibility
To be eligible for a reward under this Program, you must:


Discover a previously-unreported, non-public vulnerability that is not previously known by the Uniswap Labs team and is within the scope of this Program


Provide all KYC and other documents as requested


Be the first to disclose the unique vulnerability, in compliance with the disclosure requirements.


Provide sufficient information to enable our engineers to reproduce and fix the vulnerability.


Not exploit the vulnerability in any way, including through making it public or by obtaining a profit (other than a reward under this Program).


Not publicize or exploit a vulnerability in any way, other than through private reporting to us


Refrain from any privacy violations, destruction of data, interruption or degradation of any of the assets in scope.


Not submit a vulnerability caused by an underlying issue that is the same as an issue on which a reward has been paid under this Program.


Not engage in any unlawful conduct when disclosing the bug, including through threats, demands, or any other coercive tactics.


Be at least the age of majority at the time of submission.


Not reside in a country under any trade or economic sanctions by the United States Treasury’s Office of Foreign Assets Control, or where the laws of the United States or local law prohibits participation.


Not be one of our current or former employees, or a vendor or contractor who has been involved in the development of the code of the bug in question.


Comply with all the rules of the Program, including but not limited to, refraining from engaging in any Prohibited Actions.


Rewards
Risk Classification Matrix


Severity
Level   Impact:
Critical    Impact:
High    Impact:
Medium  Impact:
Low
Likelihood:
High    Critical    High    Medium  Low
Likelihood:
Medium  High    High    Medium  Low
Likelihood:
Low Medium  Medium  Low Informational
1. Impact Assessment


The Program includes the following 4 level Impact severity scale:


Critical Impact:


For smart contract code: An issue that results in losses (by stealing, wasting or permanently freezing) amounting to 20%-100% of the total TVL across all chains supported by Uniswap Labs’ Web Interface (at app.uniswap.org).
Issues that could impact numerous users and have serious reputational, legal or financial implications
High Impact:


For smart contract code: An issue that results in losses (by stealing, wasting or permanently freezing) amounting to 0.5%-20% of the total TVL across all chains supported by Uniswap Labs’ Web Interface (at app.uniswap.org).
Issues that impact individual users where exploitation would pose reputational, legal or moderate financial risk to the user.
Medium Impact:


Smaller losses (by stealing, wasting or permanently freezing) - impacting only individual users, or specific tokens, or specific chains.
Low/Informational Impact:
The issue does not pose an immediate risk but is relevant to security best practices.


Rewards will be given based on the above impact scale, combined with the likelihood of the bug being triggered or exploited, to be determined at the sole discretion of Uniswap Labs.


2. Likelihood Assessment


High: Very likely to occur, either due to ease of execution or strong incentives that make it highly probable.
Medium: Likely under specific conditions or scenarios, where incentives and feasibility make it reasonably expected.
Low: Rare but conceivable, potentially occurring under extreme yet realistic market situations.
Payout Calculations
Select the payout amounts by which part of our product the bug is in. The Risk Score is calculated by combining the bug’s Impact and Likelihood using the Risk Classification Matrix above, to find the overall Risk of the bug.


The aggregate, maximum amount of Payouts for Uniswap v4 Contract Code is $44,400,000. All Payout amounts will be calculated based on the order in which the submission was received. The Program will be updated as appropriate to provide updates on Payout eligibility and amounts.


Uniswap v4 Contract Code
Scope:


All contracts inside src/ in the v4-core, except those inside src/test/
Risk Score  Payout
Critical    $15,500,000
High    $1,000,000
Medium  $100,000
Low Discretionary
Other Uniswap Contract Code
Risk Score  Payout
Critical    $2,250,000
High    $500,000
Medium  $100,000
Low Discretionary
Uniswap Web Interface
This is for only the Uniswap Labs web application (app.uniswap.org)


Risk Score  Payout
Critical    $250,000
High    $50,000
Medium  $10,000
Low Discretionary
Uniswap Labs Other Websites
This is for websites that belong to Uniswap Labs, but do not involve potential wallet interactions.


Risk Score  Payout
Critical    $50,000
High    $10,000
Medium  $2,000
Low Discretionary
Uniswap Labs Backend
Risk Score  Payout
Critical    $50,000
High    $10,000
Medium  $2,000
Low Discretionary
Uniswap Mobile Wallet/Extension Wallet
Risk Score  Payout
Critical    $50,000
High    $10,000
Medium  $2,000
Low Discretionary
Uniswap Infrastructure
This is for Uniswap infrastructure. This includes deployments, github actions, AWS, etc.


Risk and payouts may vary depending on how quickly it is exploited from deploy


Risk Score  Payout
Critical    $50,000
High    $10,000
Medium  $2,000
Low Discretionary
Unichain L1 Contracts
See this for a non-exhaustive list of L1 contracts. For the issue to be in scope, the contract must be actively in use and the issue must be specific to Unichain, not the OP Stack. For issues in the OP Stack, please report them to Optimism at the Immunefi Bedrock Bug Bounty Program.


Risk Score  Payout
Critical    $2,250,000
High    $100,000
Medium  $50,000
Low Discretionary
Unichain Contracts are upgradeable and thus follow the following severity scale different from the rest of the Uniswap contracts.


Critical Issues are issues that could allow the loss of user funds by direct theft, permanent freezing of user funds, or other protocol insolvency.
High Issues are issues that could allow a temporary freezing of funds that could be resolved via an upgrade or an incorrect dispute game, an incorrect withdrawal, or incorrect bond withdrawal where the incorrect action is subject to a delay.
Medium The risk is relatively small and does not pose a threat to user funds.
Low/Informational The issue does not pose an immediate risk but is relevant to security best practices.
Rewards will be given based on the above severity as well as the likelihood of the bug being triggered or exploited, to be determined at the sole discretion of Uniswap Labs.


Before beginning your search it is important that you look through the TestedVectors.md . This file contains all of the attack vectors that have been previously attempted. After your search and testing of an attack vector you will also provide a similar write up.
