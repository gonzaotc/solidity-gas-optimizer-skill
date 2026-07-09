# External calls (XC)

Techniques that change how contracts call each other: replacing pull-based flows with hooks, batching, caching, transaction-level warming, and architectural consolidation. Most entries here are design decisions rather than local diffs.

## XC-01 · Prefer token transfer hooks over pull-based deposits
- **Kind**: advisory
- **Tier**: B
- **Detect**: deposit flows built on `approve` followed by `transferFrom(msg.sender, address(this), ...)`; a receiving contract that itself initiates the token transfer and then handles the resulting receive callback.
- **Transform**: have the user call the token directly with a hook-capable transfer (ERC-1155 transfers, ERC-721 `safeTransferFrom`/`safeMint`, ERC-1363 `transferAndCall`) so the receiving contract reacts inside its `onXReceived` hook; pass any extra parameters through the transfer's `data` bytes and decode them in the hook.
- **Savings**: removes an entire approval transaction (21k base + allowance SSTORE) and collapses a multi-hop call chain (user → A → token → A callback → return) into a single user → token → A hook path, cutting CALL and ABI round-trip overhead.
- **Preconditions**: the token standard must expose a transfer hook. ERC-1155 always does; ERC-721 only via the `safe*` variants; fungible tokens need ERC-1363 (or ERC-1155). Plain ERC-20 has no hook, so this cannot apply there.
- **Risks**: hook entry points are reentrancy surface and must be guarded and sender-validated (anyone can call the hook directly unless you check `msg.sender` is the token). ERC-777 also has hooks but is deprecated; do not adopt it. Changes the user-facing flow, so it is an interface/UX decision, not a drop-in diff.
- **Source**: RareSkills Gas Book, Cross-contract calls #1

## XC-02 · Accept plain ETH via receive/fallback instead of a deposit function
- **Kind**: advisory
- **Tier**: B
- **Detect**: `function deposit() external payable` (or similar) whose body only reacts to incoming ETH; integrations that call it with no arguments.
- **Transform**: move the reaction logic into `receive()` so senders can transfer ETH directly with empty calldata; if parameters are needed, accept them as raw bytes in `fallback()` and decode with `abi.decode`.
- **Savings**: drops the 4-byte selector and function-dispatch step; the caller sends a bare value transfer instead of an ABI-encoded call. Small absolute saving, mostly calldata and dispatch overhead.
- **Preconditions**: only viable when the surrounding architecture allows it, per the article's own caveat; the contract must be able to act meaningfully on a bare transfer without named parameters.
- **Risks**: senders using `.transfer()`/`.send()` forward only 2300 gas, which will revert if the receive logic makes further calls; accidental ETH sends now trigger business logic; raw-bytes fallback interfaces lose ABI type safety, tooling, and explorer decoding. Under EIP-7623 (calldata repricing) trimming calldata still helps but the marginal saving on 4 bytes is tiny.
- **Source**: RareSkills Gas Book, Cross-contract calls #2

## XC-03 · Use EIP-2930 access-list transactions for cross-contract calls
- **Kind**: advisory
- **Tier**: B
- **Detect**: transactions that will touch other contracts, especially proxies and EIP-1167 clones where every call goes through a `delegatecall` (implementation address plus its storage slots are accessed cold); not a source-code pattern, decided at transaction-construction time.
- **Transform**: build the transaction as type-1/2930 with an access list declaring the addresses and storage keys it will touch, prepaying them at the warm-listed rate.
- **Savings**: about 200 gas per correctly listed entry: a listed address costs 2400 vs 2600 for a cold account access, a listed storage key 1900 vs 2100 for a cold SLOAD (EIP-2929 pricing).
- **Preconditions**: every listed entry must actually be accessed cold during execution; requires off-chain support to compute the list (e.g., `eth_createAccessList`). Most valuable when the call path is known and proxy/clone hops are involved.
- **Risks**: wrong or unused entries cost more than they save; `tx.origin` and the transaction target are already warm, so listing them wastes gas. Still valid post-Dencun, but the ceiling is a few hundred gas per entry, so it never rescues an expensive design.
- **Source**: RareSkills Gas Book, Cross-contract calls #3

## XC-04 · Cache repeated external call results locally
- **Kind**: transform
- **Tier**: A
- **Detect**: the same external view call (e.g., an oracle price read like Chainlink's latest answer) issued more than once within one function or execution path.
- **Transform**: call once, store the result in a local variable (or pass it down the call stack), and reuse it for every subsequent computation in that execution.
- **Savings**: each avoided call skips CALL overhead (2600 gas cold, 100 warm under EIP-2929) plus ABI encode/decode and the callee's own SLOADs and logic, which for oracle reads is often thousands of gas.
- **Preconditions**: the value must be needed more than once in a single execution and must not legitimately change between uses.
- **Risks**: if intervening logic (callbacks, reentrant paths, state updates) could alter what a fresh call would return, caching freezes a stale value and changes semantics; verify no such interleaving exists before applying.
- **Source**: RareSkills Gas Book, Cross-contract calls #4

## XC-05 · Add multicall batching to router-style contracts
- **Kind**: advisory
- **Tier**: B
- **Detect**: periphery or router contracts whose users routinely submit several transactions in sequence (approve-then-act flows, multi-step position management) and which expose no `multicall(bytes[] calldata)`-style batch entry point.
- **Transform**: expose a multicall function that loops over encoded call payloads and self-delegatecalls each one, letting users compose a sequence of operations into one transaction, as Uniswap's router and Compound's bulker do.
- **Savings**: amortizes the 21000 base transaction cost, signature verification, and per-transaction nonce/overhead across N operations, and keeps touched accounts and slots warm across the batched steps.
- **Preconditions**: only pays off when users genuinely chain multiple calls; the batched functions must be safe to invoke via self-delegatecall in one context.
- **Risks**: combining multicall with `payable` functions that read `msg.value` is a known double-spend vulnerability class, since `msg.value` persists across the delegated subcalls; also audit permit-style or context-sensitive functions reachable through the batch. Reuse a vetted implementation (e.g., OpenZeppelin `Multicall`) rather than hand-rolling.
- **Source**: RareSkills Gas Book, Cross-contract calls #5

## XC-06 · Consolidate architecture to avoid cross-contract calls
- **Kind**: advisory
- **Tier**: B
- **Detect**: protocols split across many small contracts that call each other on every hot path; per-transaction traces showing repeated intra-protocol CALL hops.
- **Transform**: merge cooperating contracts into a single monolithic contract (or inherit modules into one deployable) so hot-path interactions become internal jumps instead of external calls.
- **Savings**: the cheapest external call is the one never made: each eliminated hop saves CALL cost (2600 cold / 100 warm), ABI encoding/decoding, calldata copying, and the fresh execution context; internal function calls are near-free JUMPs.
- **Preconditions**: the modules must be mergeable, i.e., no requirement for separate upgrade cadences, isolated privileges, or independent deployment; the article itself flags this as a genuine tradeoff, since splitting sometimes adds rather than manages complexity.
- **Risks**: the EIP-170 24 576-byte runtime size cap bounds how monolithic you can go; consolidation reduces modularity, upgrade granularity, and audit isolation, and a bug in one merged module shares storage and privileges with all others.
- **Source**: RareSkills Gas Book, Cross-contract calls #6
