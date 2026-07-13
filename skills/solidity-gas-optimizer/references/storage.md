# Storage (ST)

Techniques that cut the cost of persistent state: fewer SLOAD/SSTORE operations, fewer occupied slots, and cheaper write classes (avoiding zero-to-nonzero transitions). Storage is the most expensive resource in the EVM, so these carry the largest absolute savings.

## ST-01 · Avoid zero-to-nonzero storage writes
- **Kind**: advisory
- **Detect**: storage vars repeatedly reset to 0 and later re-set (`delete x`, `x = 0` on a hot path); `bool` lock flags toggled per call; counters or balances that round-trip through zero.
- **Hint**: flags or counters round-tripping through zero
- **Transform**: encode "empty" as a nonzero sentinel (e.g. lock states 1/2 instead of 0/1) so hot-path writes stay in the nonzero-to-nonzero class; pre-warm slots at deploy where the pattern allows.
- **Savings**: an SSTORE taking a slot from zero to nonzero costs 20,000 gas plus 2,100 for cold access (22,100 total); a nonzero-to-nonzero cold write is about 5,000 (2,900 warm). Keeping slots nonzero avoids the 20,000 component on every reuse.
- **Preconditions**: the slot must be written repeatedly over the contract's life; a one-time write gains nothing. Sentinel encoding must be applied consistently everywhere the value is read.
- **Risks**: sentinel values obscure meaning and invite off-by-one logic bugs. For the reentrancy-lock use case this technique is obsolete on chains with EIP-1153 (Dencun): transient storage (TSTORE/TLOAD, 100 gas, auto-cleared) is strictly better; solc 0.8.24+ supports it. Changing an existing flag encoding on a deployed/upgradeable contract changes stored-state semantics and is breaking.
- **Source**: RareSkills Gas Book, Storage #1

## ST-02 · Cache storage variables in the stack
- **Kind**: transform
- **Detect**: the same state variable read two or more times inside one function body; read-modify-write sequences like `x = x + 1` preceded by a `require` on `x`.
- **Hint**: same state variable read twice per function
- **Transform**: load the variable into a local once, use the local for all checks and arithmetic, and write back at most once.
- **Savings**: each avoided SLOAD saves 100 gas warm (2,100 cold); collapsing multiple writes into one saves a full SSTORE each. Legacy solc codegen does not deduplicate SLOADs; via-IR removes some redundancy but only within limited windows, so the manual cache still measures.
- **Preconditions**: no external call, delegatecall, or other write to the same slot between the cached read and the last use; the local must be the single source of truth for the function's duration.
- **Risks**: caching across an external call freezes a value that reentrant code may have changed, silently altering reentrancy-visible semantics; keep the cache span call-free or re-read after calls. Otherwise none.
- **Source**: RareSkills Gas Book, Storage #2

## ST-03 · Pack related state variables into one slot
- **Kind**: transform
- **Detect**: adjacent declarations of sub-32-byte types (`uint128`, `uint64`, `address`, `bool`) that are read/written together but separated by 32-byte types; pairs of small values always updated in the same transaction.
- **Hint**: adjacent sub-32-byte vars accessed together
- **Transform**: group co-accessed small variables so the compiler packs them into one slot; for maximum effect, merge them manually into a single word with shifts:
```solidity
uint160 private packed; // hi 80 bits: a, lo 80 bits: b
function _store(uint80 a, uint80 b) internal {
    packed = (uint160(a) << 80) | uint160(b);
}
```
- **Savings**: one slot instead of two halves both the cold-access and SSTORE costs when both values touch in one transaction. Manual packing is slightly cheaper than compiler auto-packing because it does one explicit SSTORE instead of letting the EVM mask-and-merge per field.
- **Preconditions**: values must actually be accessed together; packing values used in different transactions adds masking overhead for no benefit. Manual packing only pays when combined width fits one word.
- **Risks**: manual bit-twiddling hurts readability and auditability. Any repacking changes storage layout: on an already-deployed or upgradeable contract this corrupts existing state and is a breaking change.
- **Source**: RareSkills Gas Book, Storage #3

## ST-04 · Order struct members to pack
- **Kind**: transform
- **Detect**: `struct` definitions where small members (`uint64`, `address`, `bool`) are separated by `uint256`/`bytes32` members, forcing extra slots; member order small, big, small.
- **Hint**: small struct members split by uint256
- **Transform**: reorder members so consecutive small types share a slot (struct members occupy storage sequentially from the struct's base slot), e.g. put a `uint64` next to an `address` (224 bits together) before any full-word member.
- **Savings**: each slot eliminated removes a cold SLOAD (2,100) from full-struct reads and an SSTORE (2,900–22,100) from writes that touch it.
- **Preconditions**: combined member widths must fit 256-bit boundaries; the win is largest when the co-packed members are read or written in the same transaction.
- **Risks**: reordering members of a struct used in an already-deployed or upgradeable contract's storage rearranges stored data and is a breaking layout change. Also changes positional-constructor argument order at call sites, and packed members cost extra masking when accessed individually.
- **Source**: RareSkills Gas Book, Storage #4

## ST-05 · Keep stored strings under 32 bytes
- **Kind**: advisory
- **Detect**: `string` or `bytes` state variables initialized or assigned with literals at or beyond 32 characters; names, symbols, URIs stored on-chain.
- **Hint**: string state vars with long literals
- **Transform**: design stored text to fit in 31 bytes. Short strings live entirely in their declared slot (data in the high bytes, length*2 in the low byte); at 32+ bytes the slot holds only length*2+1 and the data moves to slots starting at keccak256(slot). A further step is declaring the field as `bytes32` and packing/unpacking manually (assembly), avoiding dynamic-type overhead entirely.
- **Savings**: staying short avoids the keccak-derived indirection plus one extra cold SLOAD (2,100) per 32-byte chunk on every read, and the corresponding SSTOREs on write.
- **Preconditions**: content length must be bounded below 32 bytes by construction; the bytes32/assembly variant needs an explicit length guard on write.
- **Risks**: content length is usually a product decision, not a code diff. The assembly variant costs significant readability and is easy to get wrong around memory-pointer handling; on modern solc, prefer typed code unless measurements justify it.
- **Source**: RareSkills Gas Book, Storage #5

## ST-06 · Use constant/immutable for never-written variables
- **Kind**: transform
- **Detect**: state variables assigned only at declaration or only in the constructor and never reassigned; `view` functions returning fixed configuration values.
- **Hint**: state vars never reassigned after constructor
- **Transform**: mark compile-time-known values `constant` and constructor-set values `immutable`. Both are embedded in the contract's bytecode (constants inlined, immutables patched into runtime code at deployment) and occupy no storage.
- **Savings**: every read avoids an SLOAD, so 2,100 gas cold or 100 warm per access, plus one storage slot of deployment cost.
- **Preconditions**: the value must genuinely never change post-construction; `immutable` requires assignment in the constructor (or inline) exactly once.
- **Risks**: converting an existing storage variable removes its slot, shifting subsequent variables: breaking for deployed/upgradeable layouts. In proxy patterns, immutables live in the implementation's code, so all proxies share the value set at implementation deploy. None for new non-proxy code.
- **Source**: RareSkills Gas Book, Storage #6

## ST-07 · Replace fixed-index arrays with mappings
- **Kind**: transform
- **Detect**: storage arrays (`uint256[] x`) accessed only by known-valid index, never iterated, never queried for `.length`; index-keyed registries.
- **Hint**: arrays indexed but never iterated
- **Transform**: store the items in a `mapping(uint256 => T)` keyed by the former index. Array indexing emits a bounds check that SLOADs the length slot and reverts with `Panic(0x32)` when out of range; mapping access hashes the key and reads the slot directly, no length involved.
- **Savings**: about 2,100 gas per read when the length slot would have been cold (the article measures ~2,102 on a fresh read); only ~100 plus a few ops when the length is already warm, so the headline number assumes cold access.
- **Preconditions**: every access must be provably in-bounds by the surrounding logic, since the mapping enforces nothing; the code must not need `.length`, iteration, `push`/`pop`, or ABI array semantics.
- **Risks**: out-of-range keys silently return zero instead of reverting, converting a loud bug into silent state corruption; length must be tracked separately if ever needed. Swapping the type on a deployed/upgradeable contract changes slot derivation for the data and is breaking.
- **Source**: RareSkills Gas Book, Storage #7

## ST-08 · Use Arrays.unsafeAccess to skip bounds checks
- **Kind**: transform
- **Detect**: hot-path reads of storage arrays where the index was already validated (loop bounded by a cached length, index checked earlier in the call).
- **Hint**: validated-index array reads in hot loops
- **Transform**: replace `arr[i]` with OpenZeppelin's `Arrays.unsafeAccess(arr, i).value`, which computes the element slot directly without re-reading the array length, while keeping the array type and its other semantics.
- **Savings**: removes the length SLOAD (up to 2,100 cold, 100 warm) plus the compare-and-panic sequence on each access.
- **Preconditions**: the index must be guaranteed within bounds by construction; the array remains a normal array elsewhere (length, push, iteration all still work).
- **Risks**: an out-of-bounds index reads or writes an arbitrary derived slot with no revert, which is state corruption rather than a crash; every call site needs an audited in-bounds argument. Confine to measured hot paths.
- **Source**: RareSkills Gas Book, Storage #8

## ST-09 · Replace many bools with a bitmap
- **Kind**: transform
- **Detect**: `mapping(address => bool)` or `mapping(uint256 => bool)` marking large populations (airdrop claims, mint allowlists, nullifiers); one fresh slot written per participant.
- **Hint**: mapping to bool marking many claims
- **Transform**: pack 256 flags per slot in a `mapping(uint256 => uint256)`, addressing bit `i` as word `i >> 8`, mask `1 << (i & 0xff)`:
```solidity
claimedWords[i >> 8] |= 1 << (i & 0xff);
```
OpenZeppelin's `BitMaps` library wraps this.
- **Savings**: a per-user bool costs 22,100 gas (fresh zero-to-nonzero slot); with a bitmap only the first flag in each 256-bit word pays that, and the other 255 pay ~5,000 (nonzero-to-nonzero, cold) or ~2,900 warm.
- **Preconditions**: participants need dense sequential indices (e.g. merkle-leaf positions); address-keyed flags must first be mapped to indices. The saving requires multiple flags landing in the same word.
- **Risks**: index-assignment machinery adds complexity, and bit arithmetic is easier to get wrong than a bool. Migrating an existing bool mapping on a deployed/upgradeable contract abandons old state and is breaking.
- **Source**: RareSkills Gas Book, Storage #9

## ST-10 · Store bulk data as contract code (SSTORE2/SSTORE3)
- **Kind**: advisory
- **Detect**: large blobs written to storage (on-chain metadata, images, lookup tables); loops SSTOREing many words of write-once data.
- **Hint**: large write-once blobs stored in storage
- **Transform**: deploy the data as the runtime bytecode of a throwaway contract (prefixed with a STOP byte so it can't execute) and read it back with EXTCODECOPY. SSTORE2 writes once via CREATE and returns a pointer address to store; SSTORE3 stages the data in storage and deploys via CREATE2 with fixed initcode, so the address depends only on the salt and can be recomputed instead of stored.
- **Savings**: storage costs roughly 690 gas per byte (22,100 per 32-byte word) versus 200 gas per byte of deployed code, so writes get about 3x cheaper and large reads via EXTCODECOPY beat repeated SLOADs.
- **Preconditions**: data is written once (or very rarely) and read a lot. Per the article: prefer SSTORE2 when the stored pointer exceeds 14 bytes; prefer SSTORE3 when a sub-14-byte salt lets the pointer pack alongside other variables. Chunks are capped by the 24 KB code limit (EIP-170) and initcode limits (EIP-3860).
- **Risks**: data is immutable; updates mean deploying a new pointer. Since EIP-6780 (Dencun), SELFDESTRUCT no longer removes code, so any legacy variant relying on delete-and-redeploy at one address is broken. Requires a vetted external library, which is an architecture decision, not a local diff.
- **Source**: RareSkills Gas Book, Storage #10

## ST-11 · Take storage pointers instead of copying structs to memory
- **Kind**: transform
- **Detect**: `SomeStruct memory s = stateMapping[key];` (or from a storage array) followed by use of only one or two of the struct's fields.
- **Hint**: struct memory copy with partial field use
- **Transform**: declare the local as `storage` instead of `memory`. The variable becomes a slot reference resolved lazily, so only the fields actually touched incur SLOADs, instead of eagerly loading every field (including dynamic ones like strings) into memory.
- **Savings**: one SLOAD per field actually read versus one per field in the struct plus memory-copy overhead; the article's three-field example with a string measures roughly 5,000 gas saved per call.
- **Preconditions**: the function reads a strict subset of fields; the local copy is never mutated as scratch data (writes through a storage pointer hit state, unlike a memory copy).
- **Risks**: assignments through the pointer silently become state writes, so misapplying this to code that mutated its memory copy changes behavior. Beware dangling pointers: deleting or overwriting the underlying struct while the pointer is live leaves it referencing changed slots. Safe when usage is read-only.
- **Source**: RareSkills Gas Book, Storage #11

## ST-12 · Keep token balances from touching zero
- **Kind**: advisory
- **Detect**: protocol flows that fully drain an ERC20 balance slot and later refill it (vault sweeps, router intermediate balances, fee accumulators emptied to exact zero).
- **Hint**: flows fully draining then refilling balances
- **Transform**: design withdrawals and sweeps to leave a minimal residue (e.g. 1 wei) in frequently cycled balance slots, so the next inbound transfer is a nonzero-to-nonzero write rather than re-initializing the slot.
- **Savings**: each refill of a kept-warm slot costs ~5,000 gas (cold) instead of 22,100, avoiding the 20,000-gas zero-to-nonzero component. Note that clearing to zero does earn a refund (only 4,800 since EIP-3529, capped at one-fifth of transaction gas), so the net win is the difference, not the full 20,000.
- **Preconditions**: the same balance slot must cycle empty-then-refilled repeatedly; one-off withdrawals gain nothing. The residue must be economically negligible and excluded from accounting.
- **Risks**: dust breaks exact-balance invariants and "withdraw all" UX, and off-by-one handling of the residue is a classic bug source. This is holder/protocol behavior, not a safe local code diff.
- **Source**: RareSkills Gas Book, Storage #12

## ST-13 · Count down to zero instead of up
- **Kind**: transform
- **Detect**: storage counters initialized at zero and incremented toward a target (`remaining++` style progress trackers, per-batch counters), where the variable's job ends when the process completes.
- **Hint**: storage counter incremented toward a target
- **Transform**: initialize the counter at n and decrement to zero, so the final write clears the slot and triggers the SSTORE-clearing gas refund, making total gas over the counter's lifecycle lower.
- **Savings**: the transaction whose write zeroes the slot gets a refund; since EIP-3529 (London) that refund is 4,800 gas, and total refunds are capped at one-fifth of the transaction's gas used, so the benefit is smaller than pre-2021 write-ups suggest.
- **Preconditions**: the ending value must legitimately be zero; the refund only pays out within its per-transaction cap, so it works best when the clearing write shares a transaction with other gas use.
- **Risks**: inverted iteration order can change observable behavior (event ordering, index math, underflow at the boundary in unchecked blocks). The initial write setting the counter to n is a 22,100-gas zero-to-nonzero store that a count-up design might have avoided; measure the whole lifecycle.
- **Source**: RareSkills Gas Book, Storage #13

## ST-14 · Size timestamp and block-number fields realistically
- **Kind**: transform
- **Detect**: `uint256` storage fields holding `block.timestamp` or `block.number` (deadlines, lastUpdated, startBlock), especially inside structs or next to other small fields.
- **Hint**: uint256 fields holding timestamps or blocks
- **Transform**: shrink them to a realistic width and pack them with neighboring fields: `uint48` holds Unix timestamps for millions of years, and block numbers grow by one every ~12 seconds, so 48 bits is generous there too.
- **Savings**: none in isolation (a lone `uint48` still occupies a full slot and adds masking ops); the payoff is enabling slot sharing, saving 2,100 gas per avoided cold SLOAD and up to 22,100 per avoided slot initialization.
- **Preconditions**: only worthwhile when the shrunken field actually co-packs with other members accessed in the same transaction; casts from `block.timestamp` need a truncation-safe conversion (e.g. `SafeCast.toUint48`).
- **Risks**: mixed-width arithmetic invites silent truncation at cast sites; comparisons against unshrunken `uint256` values need care. Narrowing a field in an already-deployed or upgradeable contract rewrites the slot layout and is breaking.
- **Source**: RareSkills Gas Book, Storage #14
