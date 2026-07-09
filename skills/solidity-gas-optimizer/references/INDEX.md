# Technique index

The scan checklist: one row per technique, 84 total. Read this file in full when scanning; open a category file only when a Detect hint matches the code under review. Kind `transform` enters the verify loop; `advisory` is report-only. Tier A = auto-apply when measured, B = humans decide, C = never apply.

| ID | Technique | Kind | Tier | Detect hint |
|----|-----------|------|------|-------------|
| ST-01 | Avoid zero-to-nonzero writes | advisory | B | flags or counters round-tripping through zero |
| ST-02 | Cache storage reads/writes | transform | A | same state variable read twice per function |
| ST-03 | Pack related state variables | transform | B | adjacent sub-32-byte vars accessed together |
| ST-04 | Order struct members to pack | transform | B | small struct members split by uint256 |
| ST-05 | Keep strings under 32 bytes | advisory | B | string state vars with long literals |
| ST-06 | Use constant/immutable | transform | A | state vars never reassigned after constructor |
| ST-07 | Mappings over fixed-index arrays | transform | B | arrays indexed but never iterated |
| ST-08 | Arrays.unsafeAccess bounds skip | transform | B | validated-index array reads in hot loops |
| ST-09 | Bitmaps for bulk booleans | transform | B | mapping to bool marking many claims |
| ST-10 | SSTORE2/SSTORE3 for bulk data | advisory | B | large write-once blobs stored in storage |
| ST-11 | Storage pointers over struct copies | transform | A | struct memory copy with partial field use |
| ST-12 | Keep balances nonzero | advisory | B | flows fully draining then refilling balances |
| ST-13 | Count down to zero | transform | B | storage counter incremented toward a target |
| ST-14 | Right-size timestamps and blocks | transform | B | uint256 fields holding timestamps or blocks |
| DEP-01 | Precompute CREATE addresses | advisory | B | peer-address setter plus storage variable |
| DEP-02 | Payable constructor | transform | B | constructor without payable keyword |
| DEP-03 | Strip CBOR metadata | transform | B | bytecode CBOR tail, no appendCBOR:false |
| DEP-04 | Selfdestruct in constructor | transform | C | selfdestruct inside constructor body |
| DEP-05 | Modifiers vs internal functions | advisory | B | modifier reused across three-plus functions |
| DEP-06 | Clone repeated deployments | advisory | B | factory repeatedly new-ing identical contract |
| DEP-07 | Payable admin functions | transform | B | onlyOwner functions lacking payable |
| DEP-08 | Custom errors over strings | transform | B | require or revert with string literal |
| DEP-09 | Reuse canonical CREATE2 factory | advisory | B | project ships its own deployer factory |
| XC-01 | Token transfer hooks over pull deposits | advisory | B | approve plus transferFrom-to-this deposit flow |
| XC-02 | receive/fallback instead of deposit() | advisory | B | payable deposit function only reacting to ETH |
| XC-03 | EIP-2930 access-list transactions | advisory | B | cross-contract or proxy calls, tx-construction time |
| XC-04 | Cache repeated external call results | transform | A | same external view call issued twice |
| XC-05 | Multicall batching in routers | advisory | B | router without bytes-array batch entry point |
| XC-06 | Monolithic architecture over many contracts | advisory | B | hot paths hopping between protocol contracts |
| ARC-01 | Multicall batching | advisory | B | multiple sequential txs to one contract |
| ARC-02 | Signatures over Merkle proofs | advisory | B | claim functions taking bytes32[] proof |
| ARC-03 | ERC20Permit approval batching | advisory | B | separate approve then transferFrom transactions |
| ARC-04 | L2 migration for high throughput | advisory | B | frequent low-value state changes on L1 |
| ARC-05 | State channels | advisory | B | fixed parties exchanging many on-chain moves |
| ARC-06 | Vote delegation | advisory | B | every holder votes on-chain per proposal |
| ARC-07 | ERC-1155 as NFT standard | advisory | B | ERC-721 with unused balanceOf |
| ARC-08 | One multi-token vs many ERC-20s | advisory | B | factory deploying ERC-20 per market |
| ARC-09 | UUPS over Transparent proxy | advisory | B | Transparent proxy with frequent user calls |
| ARC-10 | Leaner library alternatives | advisory | B | OpenZeppelin primitives on gas-critical hot paths |
| CD-01 | Mine leading-zero addresses | advisory | B | address arguments recurring in hot call paths |
| CD-02 | Prefer unsigned external parameters | advisory | B | signed int params on external functions |
| CD-03 | Calldata for unmodified reference params | transform | A | memory params never written, external functions |
| CD-04 | Packed non-ABI calldata design | advisory | C | many small padded params, L2 data costs |
| ASM-01 | Assembly string revert | transform | B | require/revert with short string literal |
| ASM-02 | Scratch-space external call | transform | C | interface call with small encoded arguments |
| ASM-03 | Branchless min/max | transform | B | ternary comparison selecting between two values |
| ASM-04 | SUB/XOR inequality check | transform | B | iszero(eq(...)) inside assembly blocks |
| ASM-05 | Assembly zero-address check | transform | B | require addr != address(0) guards |
| ASM-06 | SELFBALANCE for own balance | transform | B | address(this).balance reads |
| ASM-07 | Scratch-space hash/log under 96 bytes | transform | C | keccak256 or emit over three words max |
| ASM-08 | Reuse memory across external calls | transform | C | multiple external calls in one function |
| ASM-09 | Reuse memory across deployments | transform | C | multiple new Contract() in one function |
| ASM-10 | Bitmask parity test | transform | B | x % 2 equality comparisons |
| EXE-01 | Prefer strict comparisons | transform | A | `<=` or `>=` in conditions |
| EXE-02 | Split conjunctive requires | transform | A | `&&` inside `require(` |
| EXE-03 | Split disjunctive reverts | transform | B | `\|\|` guarding a single revert |
| EXE-04 | Named return variables | transform | A | anonymous `returns` plus explicit `return` |
| EXE-05 | Swap branches to drop negation | transform | A | `if (!` with an `else` |
| EXE-06 | Pre-increment | transform | A | standalone `i++` or `i--` |
| EXE-07 | Unchecked arithmetic | transform | B | naturally bounded arithmetic, loop counters |
| EXE-08 | Optimal loop counter pattern | transform | A | conventional for-loop, solc below 0.8.22 |
| EXE-09 | Do-while loops | transform | B | for-loops in gas-critical paths |
| EXE-10 | Default to uint256 | transform | B | unpacked sub-word integer or bool |
| EXE-11 | Order short-circuit operands | transform | B | expensive first operand in boolean chain |
| EXE-12 | Avoid public state variables | advisory | B | `public` variables without on-chain readers |
| EXE-13 | High optimizer runs | advisory | B | low `runs` on frequently called contract |
| EXE-14 | Mine low-value selectors | advisory | B | hot functions with non-zero-leading selectors |
| EXE-15 | Shift for powers of two | transform | B | mul/div by literal power of two |
| EXE-16 | Cache calldata reads | transform | A | repeated calldata reads inside loops |
| EXE-17 | Branchless code and unrolling | advisory | B | conditional-dense hot paths, tight loops |
| EXE-18 | Inline single-use internals | transform | B | internal function with one caller |
| EXE-19 | Hash-compare long data | transform | A | element-wise equality loops over bytes |
| EXE-20 | Lookup tables for pow/log | advisory | B | on-chain fractional power or log math |
| EXE-21 | Precompiles for heavy ops | advisory | B | Solidity modexp or bulk memory copies |
| EXE-22 | Chain small-exponent multiplications | transform | A | `**` with small constant exponent |
| FBD-01 | Never smuggle inputs through gas price or msg.value | advisory | C | tx.gasprice or msg.value used as data |
| FBD-02 | Never branch on manipulated block environment values | advisory | C | logic keyed on coinbase or block fields |
| FBD-03 | Never use gasleft() as a control-flow signal | advisory | C | gasleft() thresholds steering loops or branches |
| FBD-04 | Never ignore the return value of send() | advisory | C | send() result discarded, failure path unhandled |
| FBD-05 | Never mark functions payable just to save gas | advisory | C | payable on functions not meant for ether |
| FBD-06 | Never take jump destinations from calldata | advisory | C | assembly JUMP to caller-supplied offset |
| FBD-07 | Never append hand-written bytecode subroutines | advisory | C | raw bytecode appended after runtime code |
| FBD-08 | Do not change public to external for gas | advisory | C | visibility flip justified by gas savings |
| FBD-09 | Do not rewrite > 0 as != 0 for gas | advisory | C | unsigned zero-check swapped citing gas |
