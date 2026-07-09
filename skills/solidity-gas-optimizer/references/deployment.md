# Deployment (DEP)

Techniques whose savings land in the deployment transaction: smaller init/runtime bytecode, cheaper code deposit, or avoided setup transactions. Runtime effects are noted where a technique trades one for the other.

## DEP-01 · Precompute CREATE addresses to break circular dependencies
- **Kind**: advisory
- **Tier**: B
- **Detect**: two contracts that each need the other's address; a storage variable holding a peer contract address plus a post-deploy setter (`function setX(address …)`) instead of a constructor argument
- **Transform**: compute the future CREATE address from deployer address + nonce (RLP derivation, e.g. Solady's `LibRLP`), pass it as a constructor arg into an `immutable`, and delete the setter and storage slot; assert the predicted address matches after deployment
- **Savings**: article measured ~2k gas per subsequent call, since an `immutable` baked into runtime code replaces a cold SLOAD (2100 gas); also removes the setter's bytecode and its separate setup transaction
- **Preconditions**: deployer account and its nonce sequence fully controlled during the deploy; a contract's nonce starts at 1 and increments only on contract creation; works from a deploy script, no dedicated deployer contract needed
- **Risks**: a miscounted nonce (or an interleaved deployment) yields a wrong address, so the sanity check is mandatory; more fragile deployment orchestration; harder to reason about for reviewers
- **Source**: RareSkills Gas Book, Deployment #1

## DEP-02 · Make constructors payable
- **Kind**: transform
- **Tier**: B
- **Detect**: `constructor(` declarations without the `payable` keyword
- **Transform**: add `payable` to the constructor
- **Savings**: ~200 gas at deployment; the compiler omits the implicit callvalue guard (CALLVALUE/ISZERO/JUMPI plus a revert block) from the init code, so fewer opcodes execute and the deploy transaction carries fewer calldata bytes
- **Preconditions**: deployment is performed by a privileged, competent party who will not attach ether; not appropriate when inexperienced users deploy the contract themselves
- **Risks**: ether sent at deployment is silently accepted and stuck unless a withdrawal path exists; reviewers and auditors often flag gratuitous `payable` as a foot-gun, which carries a real perception and audit cost for a tiny one-time saving
- **Source**: RareSkills Gas Book, Deployment #2

## DEP-03 · Strip or zero-optimize the CBOR metadata hash
- **Kind**: transform
- **Tier**: B
- **Detect**: compiler config without `metadata: { appendCBOR: false }` (CLI `--no-cbor-metadata`); deployed bytecode ending in a CBOR blob (`a26469706673…` tail)
- **Transform**: disable metadata appending in compiler settings; alternatively keep the metadata but grind source comments until the resulting IPFS hash contains more zero bytes
- **Savings**: the compiler normally appends ~51 bytes of metadata; at 200 gas per deposited byte that is >10k gas, plus calldata savings on the deploy transaction (zero bytes are cheaper than nonzero ones)
- **Preconditions**: acceptable only when full source verification against the metadata hash is not required; the zero-byte-mining variant preserves verifiability at the cost of build-time grinding
- **Risks**: removing metadata breaks Sourcify-style full matches and can complicate verification; EIP-7623 (2025) repriced calldata with a floor cost, so the zero-byte mining payoff on the deploy transaction is smaller than the article's era assumed; code-deposit savings still hold
- **Source**: RareSkills Gas Book, Deployment #3

## DEP-04 · Selfdestruct at the end of a one-shot deployer constructor
- **Kind**: transform
- **Tier**: C
- **Detect**: `selfdestruct(` inside a constructor; deployer contracts whose entire job runs in the constructor (batch-creating other contracts in one transaction)
- **Transform**: do not apply. Historically: call `selfdestruct` as the constructor's last step so the helper contract leaves no account behind
- **Savings**: the claimed benefit relied on selfdestruct gas refunds, which EIP-3529 (London, 2021) removed; on modern chains the opcode costs 5000 gas and refunds nothing, so the saving no longer exists
- **Preconditions**: contract must have no purpose beyond its constructor; same-transaction creation and destruction
- **Risks**: `selfdestruct` is deprecated; EIP-6780 (Dencun, 2024) neutered it except for same-transaction creations, and further removal is on the roadmap, so any dependence on it is a liability; the cheap alternative is simply deploying empty runtime code. Never apply
- **Source**: RareSkills Gas Book, Deployment #4

## DEP-05 · Weigh modifiers against internal functions
- **Kind**: advisory
- **Tier**: B
- **Detect**: a `modifier` applied to three or more functions; conversely, repeated internal guard calls at function entry
- **Transform**: design choice: a modifier's body is inlined at every use site, while an internal function exists once and is reached via jumps; pick modifiers when per-call runtime cost dominates, internal functions when deployment cost or code size dominates
- **Savings**: the article's three-function example deployed ~36k gas cheaper with an internal function (one body instead of three inlined copies, at 200 gas per deposited byte), while each modifier-based call ran a fixed ~24 gas cheaper (no jump out and back)
- **Preconditions**: the duplication penalty only matters when the guard is reused across several functions; single-use guards cost the same either way
- **Risks**: modifiers can only wrap a function's start/end, not its middle, limiting flexibility; note that modern solc 0.8.x with the optimizer (especially via-IR) may inline small internal functions, shrinking the measured gap in both directions, so re-measure on your compiler settings
- **Source**: RareSkills Gas Book, Deployment #5

## DEP-06 · Deploy repeated contracts as clones or metaproxies
- **Kind**: advisory
- **Tier**: B
- **Detect**: factories running `new SomeContract(...)` many times with identical logic; protocols spawning per-user or per-market instances of the same code
- **Transform**: deploy the logic once, then stamp out EIP-1167 minimal proxies (or EIP-3448 metaproxies when per-instance data is needed) that delegatecall into it
- **Savings**: a minimal proxy's runtime code is ~45 bytes, so each instance skips depositing the full contract (200 gas per byte), cutting per-instance deployment from potentially hundreds of thousands of gas to tens of thousands
- **Preconditions**: instances share (near-)identical logic and are not called frequently: every call pays delegatecall overhead including a cold account access (2600 gas) on first touch, so high-traffic contracts may lose the trade; Gnosis Safe is the canonical example of the pattern paying off
- **Risks**: constructors are replaced by initializers (uninitialized-proxy takeover if unguarded); no per-instance immutables in plain 1167; delegatecall demands strict storage-layout discipline against the implementation
- **Source**: RareSkills Gas Book, Deployment #6

## DEP-07 · Mark admin-only functions payable
- **Kind**: transform
- **Tier**: B
- **Detect**: `onlyOwner`/role-gated external functions declared without `payable`
- **Transform**: add `payable` to functions callable only by trusted admins
- **Savings**: drops the compiler's implicit callvalue check from each such function, saving a handful of gas per call and shaving those opcodes from both creation and runtime bytecode, so the contract is slightly cheaper to deploy
- **Preconditions**: only for functions restricted to competent, privileged callers who won't attach ether
- **Risks**: ether sent by mistake is accepted and stuck absent a sweep function; changes the ABI mutability from nonpayable to payable, which is an interface-visible change; widely perceived as a code smell, and auditors routinely flag it, so the reputational/readability cost usually outweighs the trivial saving
- **Source**: RareSkills Gas Book, Deployment #7

## DEP-08 · Replace require strings with custom errors
- **Kind**: transform
- **Tier**: B
- **Detect**: `require(cond, "…")` and `revert("…")` with string literals
- **Transform**: declare `error SomethingWrong();` and revert with it (`if (!cond) revert SomethingWrong();`, or `require(cond, SomethingWrong())` on recent compilers)
- **Savings**: a custom error reverts with just a 4-byte selector, versus the `Error(string)` path that ABI-encodes offset, length, and data (≥64 bytes of memory) and embeds the string literal in the bytecode; result is smaller deployed code (200 gas per byte saved) and a cheaper revert path
- **Preconditions**: solc ≥0.8.4 for custom errors; `require(cond, CustomError())` needs solc ≥0.8.26 with via-IR, or ≥0.8.27 on the legacy pipeline; savings are largest for long strings ("usually" smaller, per the article)
- **Risks**: the revert payload changes shape, so on-chain `try/catch Error(string)` handlers, tests asserting revert strings, and integrators matching messages all break; off-chain tooling needs the ABI to decode selectors
- **Source**: RareSkills Gas Book, Deployment #8

## DEP-09 · Reuse a canonical CREATE2 factory
- **Kind**: advisory
- **Tier**: B
- **Detect**: a project deploying its own CREATE2 deployer/factory contract when it merely needs a deterministic address
- **Transform**: deploy through an already-deployed deterministic-deployment factory (e.g. the proxy Foundry uses at 0x4e59b44847b379578588920cA78FbF26c0B4956C, Safe Singleton Factory, or CreateX) instead of shipping your own
- **Savings**: eliminates an entire factory deployment: the 32k CREATE surcharge, 200 gas per byte of factory code deposit, and one transaction's overhead
- **Preconditions**: a suitable factory must already exist on every target chain; the deterministic address must be acceptable as a function of that factory's address and your salt/init code
- **Risks**: inside the deployed constructor `msg.sender` is the factory, not your EOA, silently breaking `Ownable(msg.sender)`-style setups; you inherit trust in the factory's code and its cross-chain availability; address derivation is pinned to that factory forever
- **Source**: RareSkills Gas Book, Deployment #9
