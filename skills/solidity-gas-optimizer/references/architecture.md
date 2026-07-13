# Architecture (ARC)

System-level design decisions: which contracts, token standards, execution layers, and upgrade patterns exist at all. These are settled at design time and cannot be applied as safe local diffs.

## ARC-01 · Batch operations behind a self-delegatecall multicall
- **Kind**: advisory
- **Tier**: B
- **Detect**: frontends or users issuing several sequential transactions to one contract (approve-then-act flows, multi-step config); no batch entry point in the ABI.
- **Hint**: multiple sequential txs to one contract
- **Transform**: expose a `multicall(bytes[] calldata)` that loops over payloads and delegatecalls each into the contract itself, so N operations share one transaction while keeping the original `msg.sender` and `msg.value`.
- **Savings**: each merged call avoids the 21,000-gas intrinsic transaction cost, and later sub-calls hit already-warm storage and account slots (EIP-2929 warm vs cold pricing).
- **Preconditions**: every reachable function must be safe under self-delegatecall; the batch composition is decided by callers, so all combinations must be safe.
- **Risks**: `msg.value` is not consumed per sub-call; any payable function that reads it can count the same ETH multiple times within one batch (a well-known exploit class). Restrict or forbid payable functions in the batch, or account value explicitly.
- **Source**: RareSkills Gas Book, Design patterns #1

## ARC-02 · Prefer signer-issued signatures over Merkle proofs for allowlists
- **Kind**: advisory
- **Tier**: B
- **Detect**: claim/mint functions taking `bytes32[] proof` parameters; proof length (and calldata cost) growing with participant count.
- **Hint**: claim functions taking bytes32[] proof
- **Transform**: have an off-chain signer authorize each address; the claimant submits a fixed ~65-byte signature checked with `ecrecover` instead of a proof of 32 bytes per tree level.
- **Savings**: calldata shrinks from 32·⌈log2 n⌉ bytes to a constant 65, and log2(n) keccak rounds are replaced by one 3,000-gas ecrecover precompile call; the advantage widens with list size. EIP-7623 (2025) raised the calldata floor price, which strengthens this advice for data-heavy claims.
- **Preconditions**: you can operate and secure a signing key/service; replay protection is added (claimed bitmap or nonce, EIP-712 domain separation).
- **Risks**: introduces a trusted key whose compromise authorizes arbitrary claims; the allowlist is no longer independently verifiable from a public on-chain root.
- **Source**: RareSkills Gas Book, Design patterns #2

## ARC-03 · Use ERC20Permit to fuse approval and spend into one transaction
- **Kind**: advisory
- **Tier**: B
- **Detect**: two-transaction UX where users call `approve` and then a contract calls `transferFrom`; protocols requiring pre-set allowances.
- **Hint**: separate approve then transferFrom transactions
- **Transform**: support EIP-2612: the holder signs an approval off-chain and the spender (or any relayer) submits `permit` plus the spend in a single transaction.
- **Savings**: removes one full transaction (21,000 intrinsic gas plus call overhead) and shifts gas payment from the token holder to the submitter; the allowance SSTORE itself is still paid.
- **Preconditions**: the token implements EIP-2612 (many older tokens do not); the integrating contract batches `permit` with the spend.
- **Risks**: permit signatures are phishable off-chain with no gas cost to the attacker; a front-run `permit` makes the batched call revert unless wrapped (try/catch or allowance check); partial token support forces dual code paths.
- **Source**: RareSkills Gas Book, Design patterns #3

## ARC-04 · Move high-frequency, low-value activity to an L2
- **Kind**: advisory
- **Tier**: B
- **Detect**: games, ticketing, or micro-transactions executing frequent small state changes directly on L1; per-action fees exceeding the value moved.
- **Hint**: frequent low-value state changes on L1
- **Transform**: keep canonical assets on L1, bridge them via message passing to a rollup or sidechain, run the interaction loop there, and settle final outcomes or withdrawals back.
- **Savings**: orders of magnitude, because execution buys cheap L2 gas instead of L1 gas; since EIP-4844 (Dencun, 2024) rollups post data as blobs, pushing typical L2 fees to cents or below, which makes this pattern stronger than when the article was written.
- **Preconditions**: the application tolerates bridging latency and the target chain's trust model; user value per action is low.
- **Risks**: bridge and sequencer trust plus censorship exposure; liquidity and asset fragmentation; optimistic-rollup withdrawal delays; sidechains offer weaker guarantees than rollups.
- **Source**: RareSkills Gas Book, Design patterns #4

## ARC-05 · Use state channels for repeated interactions between fixed parties
- **Kind**: advisory
- **Tier**: B
- **Detect**: a small, known participant set exchanging many rapid moves (turn-based games, streaming micropayments) as individual on-chain transactions.
- **Hint**: fixed parties exchanging many on-chain moves
- **Transform**: participants escrow assets in a channel contract, exchange mutually signed state updates off-chain, and post only the final state; a dishonest party's own latest signature lets the honest side force settlement on-chain.
- **Savings**: on-chain cost collapses to open + close (+ optional dispute), independent of how many intermediate state transitions occur.
- **Preconditions**: counterparties known at channel open; bounded session length; participants or watchtowers remain online to challenge stale-state submissions.
- **Risks**: large implementation and audit surface (challenge games, timeouts); capital locked for the channel's lifetime; griefing via forced challenge periods; post-EIP-4844 L2 fees remove the economic case for most applications, so weigh against a plain L2 deployment.
- **Source**: RareSkills Gas Book, Design patterns #5

## ARC-06 · Reduce governance transactions through vote delegation
- **Kind**: advisory
- **Tier**: B
- **Detect**: governance where each holder casts an on-chain vote per proposal; ERC20Votes-style tokens with checkpointing on transfer.
- **Hint**: every holder votes on-chain per proposal
- **Transform**: adopt delegation (ERC20Votes / ERC-5805): holders assign voting power once and only delegates submit vote transactions, shrinking the total number of votes cast per proposal.
- **Savings**: every merged vote avoids a full `castVote` transaction; additionally, accounts that never delegate skip checkpoint SSTOREs on token transfers, since undelegated balances are not checkpointed.
- **Preconditions**: the governance design accepts representative voting; holders actually delegate.
- **Risks**: concentrates voting power in few delegates; the delegation transaction itself writes checkpoints and costs gas; low delegation rates undermine quorum legitimacy.
- **Source**: RareSkills Gas Book, Design patterns #6

## ARC-07 · Model NFTs as ERC-1155 ids instead of ERC-721
- **Kind**: advisory
- **Tier**: B
- **Detect**: ERC-721 collections whose `balanceOf` is never consumed on-chain; mint- or transfer-heavy drops paying double storage writes.
- **Hint**: ERC-721 with unused balanceOf
- **Transform**: issue tokens as ERC-1155 ids capped at supply one; a single `balances[id][owner]` slot then encodes both ownership and balance, whereas ERC-721 writes a per-token owner slot and a per-owner balance slot on every mint and transfer.
- **Savings**: one storage write fewer per mint/transfer (up to 20,000 gas for a cold zero-to-nonzero SSTORE at mint; 2,900–5,000 for updates).
- **Preconditions**: nothing on-chain needs `ownerOf` or the ERC-721 interface; target marketplaces and indexers handle ERC-1155.
- **Risks**: no on-chain `ownerOf`; some tooling treats 1155 as semi-fungible (quantity offers); mandatory `onERC1155Received` callbacks on contract recipients add reentrancy surface; if 721 compatibility is required, ERC-721A already amortizes batch-mint costs.
- **Source**: RareSkills Gas Book, Design patterns #7

## ARC-08 · Deploy one multi-token contract instead of many ERC-20s
- **Kind**: advisory
- **Tier**: B
- **Detect**: a factory spawning an ERC-20 contract per market, vault share, or series.
- **Hint**: factory deploying ERC-20 per market
- **Transform**: hold every token class as an id inside a single ERC-1155, or ERC-6909 when the mandatory receiver callbacks are unwanted (ERC-6909, used by Uniswap v4, drops them); each id behaves as an independent fungible balance.
- **Savings**: eliminates repeated deployments (32,000-gas CREATE plus 200 gas per byte of deployed code, commonly over 1M gas per token); cross-token operations touch one warm account instead of several cold ones (2,600 gas per cold account access under EIP-2929).
- **Preconditions**: token classes do not need standalone contract addresses.
- **Risks**: incompatible with ERC-20-only infrastructure (AMMs, lending markets, wallet balance displays); ERC-1155 callbacks add reentrancy surface; ERC-6909 tooling and integration support is still thin.
- **Source**: RareSkills Gas Book, Design patterns #8

## ARC-09 · Choose UUPS over Transparent proxies to shift gas off users
- **Kind**: advisory
- **Tier**: B
- **Detect**: TransparentUpgradeableProxy in front of contracts with frequent user calls; upgradeability pattern still undecided.
- **Hint**: Transparent proxy with frequent user calls
- **Transform**: with a Transparent proxy, every incoming call must first test whether the caller is the admin before routing, so all users pay that check on every transaction forever; with UUPS the proxy fallback is a bare delegatecall and the admin check lives only inside the access-controlled upgrade function, so the deployer pays a slightly larger implementation once and only upgrade transactions pay the check.
- **Savings**: historically ~2,100 gas per user call for the admin-slot SLOAD. Since OpenZeppelin Contracts 5.0 the Transparent proxy stores the admin as an immutable in bytecode, so the residual per-call overhead is a cheap comparison and the article's figure overstates the modern gap.
- **Preconditions**: team can maintain the upgrade logic inside the implementation across versions.
- **Risks**: UUPS is more security-critical: `_authorizeUpgrade` must be restricted in every implementation, constructors must call `_disableInitializers()`, and an upgrade to an implementation lacking upgrade logic permanently freezes the proxy.
- **Source**: RareSkills Gas Book, Design patterns #9
