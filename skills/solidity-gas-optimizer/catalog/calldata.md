# Calldata (CD)

Techniques that shrink transaction calldata or make it cheaper to consume: zero-byte-friendly value encodings, leaner argument layouts, and reading inputs in place instead of copying them to memory.

## CD-01 · Mine leading-zero addresses for frequently passed contracts
- **Kind**: advisory
- **Detect**: contract addresses that recur as function arguments on high-volume call paths (routers, tokens, marketplaces referenced in integrators' calldata); deployments using plain CREATE where a CREATE2 salt search would be feasible.
- **Hint**: address arguments recurring in hot call paths
- **Transform**: deploy-time tooling, not a code diff: brute-force a CREATE2 salt until the resulting address has several leading zero bytes, so every later call that passes that address as an argument carries cheaper calldata.
- **Savings**: a calldata zero byte costs 4 gas vs 16 for nonzero, so each zeroed byte saves 12 gas (30 at the EIP-7623 floor rate of 10 vs 40 per byte). An address with 8 leading zero bytes saves roughly 96 gas each time it appears as an argument.
- **Preconditions**: pays off only for addresses passed as arguments at scale; calling the address as a transaction target gains nothing. The contract must be deployable via CREATE2 so a salt can be searched.
- **Risks**: mining vanity EOAs with weak key-generation entropy has enabled real private-key recovery attacks; only CREATE2-mined contract addresses are safe, since no private key exists. On post-Dencun L2s (EIP-4844 blobs), data is compressed before posting and zero bytes compress well anyway, so the L2-side benefit is small.
- **Source**: RareSkills Gas Book, Calldata #1

## CD-02 · Prefer unsigned types in external parameters
- **Kind**: advisory
- **Detect**: `int`/`intN` parameters on external or public functions, especially where callers routinely pass small negative values; grep for `int` types inside function signatures.
- **Hint**: signed int params on external functions
- **Transform**: at interface-design time, model the value as unsigned where the domain allows: carry magnitude plus a direction flag, or add a fixed bias so the whole range is nonnegative. Never retrofit a released function, since changing the type changes the selector.
- **Savings**: two's complement fills small negatives with 0xff bytes, so -1 occupies its 32-byte slot entirely with nonzero bytes (16 gas each) where a small positive is ~31 zero bytes (4 gas each): roughly 370 gas per affected argument, weighted 4x heavier still under the EIP-7623 floor.
- **Preconditions**: value range must map cleanly to an unsigned or biased representation; the benefit only materializes on calls that actually carry small negative values.
- **Risks**: bias and flag encodings invite off-by-one and boundary bugs and cost readability; a signature change breaks the ABI for every integrator. Post-Dencun L2 compression shrinks the win there.
- **Source**: RareSkills Gas Book, Calldata #2

## CD-03 · Take unmodified reference parameters as calldata
- **Kind**: transform
- **Detect**: external or public functions declaring `bytes memory`, `string memory`, or array/struct `memory` parameters that are never written inside the function; grep for `memory` in external function signatures.
- **Hint**: memory params never written, external functions
- **Transform**: change the parameter's data location from `memory` to `calldata`.
- **Savings**: skips the ABI decoder's eager copy into memory (CALLDATACOPY, memory expansion, free-pointer bookkeeping); reads happen in place via CALLDATALOAD. Tens to a few hundred gas, growing with argument size.
- **Preconditions**: the parameter is never mutated (calldata is read-only), and every internal call site of a public function must itself hold calldata for that argument, since memory values cannot be passed where calldata is expected. Independent of optimizer settings; data location does not affect the selector, so the external ABI is unchanged.
- **Risks**: essentially none for concrete contracts. In inheritable base contracts, a `calldata` parameter forces overriders that want to mutate the input to copy it first, which is why some libraries deliberately keep `memory` on virtual functions.
- **Source**: RareSkills Gas Book, Calldata #3

## CD-04 · Design packed non-ABI calldata for data-heavy L2 functions
- **Kind**: advisory
- **Detect**: functions with long lists of small-valued parameters, each padded to a full 32-byte word by ABI encoding; L2 contracts whose dominant cost is data posting.
- **Hint**: many small padded params, L2 data costs
- **Transform**: ground-up design decision, never a retrofit: define an application-specific byte layout (tight widths, implicit fields), receive it through `fallback` or a single raw `bytes` argument, and decode by hand on-chain. The compiler packs storage this way automatically but never packs ABI-encoded calldata, so the layout and decoder must be hand-built.
- **Savings**: removes padding bytes roughly in proportion to how oversized the ABI words are; each byte cut saves 4/16 gas (10/40 under the EIP-7623 floor) and reduces the data charge on L2s.
- **Preconditions**: only worth weighing when calldata dominates the function's cost, which historically meant L2s posting calldata to L1. Since Dencun (EIP-4844) most L2s post blobs instead, so the payoff is far smaller than when this advice was written.
- **Risks**: abandons the standard ABI entirely: explorers, wallets, SDKs, verification tooling, and downstream integrators all lose automatic encoding/decoding, and the hand-rolled decoder becomes a standing bug and audit burden. Changing an existing function's encoding breaks every caller. Never apply automatically; justified only as a deliberate interface design by humans.
- **Source**: RareSkills Gas Book, Calldata #4
