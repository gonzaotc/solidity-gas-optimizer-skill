# Technique index

Procedurally generated from the category files by `build-index.sh`; do not edit by hand.

The scan checklist: one row per technique, 83 total. Each ID links to the category file holding the full card. Read this file in full when scanning; open a category file only when a Detect hint matches the code under review. Kind and tier semantics are defined in the audit skill's Reference catalog section and in the card spec.

## Categories

Orientation for where a technique lives, not a filter: the scan still walks every hint below.

| Prefix | Category | Covers |
|--------|----------|--------|
| ST | [storage.md](storage.md) | Techniques that cut the cost of persistent state: fewer SLOAD/SSTORE operations, fewer occupied slots, and cheaper write classes (avoiding zero-to-nonzero transitions). |
| DEP | [deployment.md](deployment.md) | Techniques whose savings land in the deployment transaction: smaller init/runtime bytecode, cheaper code deposit, or avoided setup transactions. |
| XC | [external-calls.md](external-calls.md) | Techniques that change how contracts call each other: replacing pull-based flows with hooks, batching, caching, transaction-level warming, and architectural consolidation. |
| ARC | [architecture.md](architecture.md) | System-level design decisions: which contracts, token standards, execution layers, and upgrade patterns exist at all. |
| CD | [calldata.md](calldata.md) | Techniques that shrink transaction calldata or make it cheaper to consume: zero-byte-friendly value encodings, leaner argument layouts, and reading inputs in place instead of copying them to memory. |
| ASM | [assembly.md](assembly.md) | Techniques that require dropping into inline assembly (Yul) to bypass the Solidity compiler's memory management, type checks, or branching codegen. |
| EXE | [execution.md](execution.md) | Local codegen and execution-cost techniques that stay in plain Solidity: comparison and control-flow shape, arithmetic strength reduction, compiler configuration, and function-dispatch cost. |
| FBD | [forbidden.md](forbidden.md) | Techniques the optimizer must never apply: seven are contest-only techniques that are unsafe in production, and two are obsolete micro-optimizations that no longer save gas on modern solc 0.8.x. |

## Techniques

| ID | Technique | Kind | Tier | Detect hint |
|----|-----------|------|------|-------------|
| [ST-01](storage.md) | Avoid zero-to-nonzero storage writes | advisory | B | flags or counters round-tripping through zero |
| [ST-02](storage.md) | Cache storage variables in the stack | transform | A | same state variable read twice per function |
| [ST-03](storage.md) | Pack related state variables into one slot | transform | B | adjacent sub-32-byte vars accessed together |
| [ST-04](storage.md) | Order struct members to pack | transform | B | small struct members split by uint256 |
| [ST-05](storage.md) | Keep stored strings under 32 bytes | advisory | B | string state vars with long literals |
| [ST-06](storage.md) | Use constant/immutable for never-written variables | transform | A | state vars never reassigned after constructor |
| [ST-07](storage.md) | Replace fixed-index arrays with mappings | transform | B | arrays indexed but never iterated |
| [ST-08](storage.md) | Use Arrays.unsafeAccess to skip bounds checks | transform | B | validated-index array reads in hot loops |
| [ST-09](storage.md) | Replace many bools with a bitmap | transform | B | mapping to bool marking many claims |
| [ST-10](storage.md) | Store bulk data as contract code (SSTORE2/SSTORE3) | advisory | B | large write-once blobs stored in storage |
| [ST-11](storage.md) | Take storage pointers instead of copying structs to memory | transform | A | struct memory copy with partial field use |
| [ST-12](storage.md) | Keep token balances from touching zero | advisory | B | flows fully draining then refilling balances |
| [ST-13](storage.md) | Count down to zero instead of up | transform | B | storage counter incremented toward a target |
| [ST-14](storage.md) | Size timestamp and block-number fields realistically | transform | B | uint256 fields holding timestamps or blocks |
| [DEP-01](deployment.md) | Precompute CREATE addresses to break circular dependencies | advisory | B | peer-address setter plus storage variable |
| [DEP-02](deployment.md) | Make constructors payable | transform | B | constructor without payable keyword |
| [DEP-03](deployment.md) | Strip or zero-optimize the CBOR metadata hash | transform | B | bytecode CBOR tail, no appendCBOR:false |
| [DEP-04](deployment.md) | Selfdestruct at the end of a one-shot deployer constructor | transform | C | selfdestruct inside constructor body |
| [DEP-05](deployment.md) | Weigh modifiers against internal functions | advisory | B | modifier reused across three-plus functions |
| [DEP-06](deployment.md) | Deploy repeated contracts as clones or metaproxies | advisory | B | factory repeatedly deploying identical contracts with `new` |
| [DEP-07](deployment.md) | Mark admin-only functions payable | transform | B | onlyOwner functions lacking payable |
| [DEP-08](deployment.md) | Replace require strings with custom errors | transform | B | require or revert with string literal |
| [DEP-09](deployment.md) | Reuse a canonical CREATE2 factory | advisory | B | project ships its own deployer factory |
| [XC-01](external-calls.md) | Prefer token transfer hooks over pull-based deposits | advisory | B | approve plus transferFrom-to-this deposit flow |
| [XC-02](external-calls.md) | Accept plain ETH via receive/fallback instead of a deposit function | advisory | B | payable deposit function only reacting to ETH |
| [XC-03](external-calls.md) | Use EIP-2930 access-list transactions for cross-contract calls | advisory | B | cross-contract or proxy calls, tx-construction time |
| [XC-04](external-calls.md) | Cache repeated external call results locally | transform | A | same external view call issued twice |
| [XC-05](external-calls.md) | Add multicall batching to router-style contracts | advisory | B | router without bytes-array batch entry point |
| [XC-06](external-calls.md) | Consolidate architecture to avoid cross-contract calls | advisory | B | hot paths crossing several protocol contracts |
| [ARC-01](architecture.md) | Batch operations behind a self-delegatecall multicall | advisory | B | multiple sequential txs to one contract |
| [ARC-02](architecture.md) | Prefer signer-issued signatures over Merkle proofs for allowlists | advisory | B | claim functions taking bytes32[] proof |
| [ARC-03](architecture.md) | Use ERC20Permit to fuse approval and spend into one transaction | advisory | B | separate approve then transferFrom transactions |
| [ARC-04](architecture.md) | Move high-frequency, low-value activity to an L2 | advisory | B | frequent low-value state changes on L1 |
| [ARC-05](architecture.md) | Use state channels for repeated interactions between fixed parties | advisory | B | fixed parties exchanging many on-chain moves |
| [ARC-06](architecture.md) | Reduce governance transactions through vote delegation | advisory | B | every holder votes on-chain per proposal |
| [ARC-07](architecture.md) | Model NFTs as ERC-1155 ids instead of ERC-721 | advisory | B | ERC-721 with unused balanceOf |
| [ARC-08](architecture.md) | Deploy one multi-token contract instead of many ERC-20s | advisory | B | factory deploying ERC-20 per market |
| [ARC-09](architecture.md) | Choose UUPS over Transparent proxies to shift gas off users | advisory | B | Transparent proxy with frequent user calls |
| [CD-01](calldata.md) | Mine leading-zero addresses for frequently passed contracts | advisory | B | address arguments recurring in hot call paths |
| [CD-02](calldata.md) | Prefer unsigned types in external parameters | advisory | B | signed int params on external functions |
| [CD-03](calldata.md) | Take unmodified reference parameters as calldata | transform | A | memory params never written, external functions |
| [CD-04](calldata.md) | Design packed non-ABI calldata for data-heavy L2 functions | advisory | C | many small padded params, L2 data costs |
| [ASM-01](assembly.md) | Revert with a string error from assembly | transform | B | require/revert with short string literal |
| [ASM-02](assembly.md) | Make single external calls with hand-rolled calldata in scratch space | transform | C | interface call with small encoded arguments |
| [ASM-03](assembly.md) | Branchless min/max and similar math primitives | transform | B | ternary comparison selecting between two values |
| [ASM-04](assembly.md) | Inequality via SUB or XOR instead of ISZERO(EQ) | transform | B | iszero(eq(...)) inside assembly blocks |
| [ASM-05](assembly.md) | Zero-address check in assembly | transform | B | require addr != address(0) guards |
| [ASM-06](assembly.md) | SELFBALANCE instead of address(this).balance | transform | B | address(this).balance reads |
| [ASM-07](assembly.md) | Hash or emit up to 96 bytes from scratch space | transform | C | keccak256 or emit over three words max |
| [ASM-08](assembly.md) | Reuse one memory region across multiple external calls | transform | C | multiple external calls in one function |
| [ASM-09](assembly.md) | Reuse memory when deploying multiple contracts | transform | C | multiple new Contract() in one function |
| [ASM-10](assembly.md) | Parity check with a bitmask instead of modulo | transform | B | x % 2 equality comparisons |
| [EXE-01](execution.md) | Prefer strict comparisons | transform | A | `<=` or `>=` in conditions |
| [EXE-02](execution.md) | Split conjunctive require statements | transform | A | `&&` inside `require(` |
| [EXE-03](execution.md) | Split disjunctive revert conditions | transform | B | `\|\|` guarding a single revert |
| [EXE-04](execution.md) | Use named return variables | transform | A | anonymous `returns` plus explicit `return` |
| [EXE-05](execution.md) | Swap branches to remove a negation | transform | A | `if (!` with an `else` |
| [EXE-06](execution.md) | Pre-increment instead of post-increment | transform | A | standalone `i++` or `i--` |
| [EXE-07](execution.md) | Use unchecked arithmetic where overflow is impossible | transform | B | naturally bounded arithmetic, loop counters |
| [EXE-08](execution.md) | Gas-optimal loop counter pattern | transform | A | conventional for-loop, solc below 0.8.22 |
| [EXE-09](execution.md) | Do-while instead of for | transform | B | for-loops in gas-critical paths |
| [EXE-10](execution.md) | Default to uint256 unless packing | transform | B | unpacked sub-word integer or bool |
| [EXE-11](execution.md) | Order short-circuit operands deliberately | transform | B | expensive first operand in boolean chain |
| [EXE-12](execution.md) | Avoid public visibility on state variables | advisory | B | `public` variables without on-chain readers |
| [EXE-13](execution.md) | Set a high optimizer runs value for hot contracts | advisory | B | low `runs` on frequently called contract |
| [EXE-14](execution.md) | Mine low-value selectors for hot functions | advisory | B | hot functions with non-zero-leading selectors |
| [EXE-15](execution.md) | Shift instead of multiplying or dividing by powers of two | transform | B | mul/div by literal power of two |
| [EXE-16](execution.md) | Consider caching calldata values in locals | transform | A | repeated calldata reads inside loops |
| [EXE-17](execution.md) | Branchless code and loop unrolling | advisory | B | conditional-dense hot paths, tight loops |
| [EXE-18](execution.md) | Inline internal functions with a single caller | transform | B | internal function with one caller |
| [EXE-19](execution.md) | Compare long arrays and strings by hash | transform | A | element-wise equality loops over bytes |
| [EXE-20](execution.md) | Precomputed tables for powers and logarithms | advisory | B | on-chain fractional power or log math |
| [EXE-21](execution.md) | Use precompiles for big-number and memory work | advisory | B | Solidity modexp or bulk memory copies |
| [EXE-22](execution.md) | Chain multiplications instead of small constant exponents | transform | A | `**` with small constant exponent |
| [FBD-01](forbidden.md) | Never smuggle inputs through gas price or msg.value | advisory | C | tx.gasprice or msg.value used as data |
| [FBD-02](forbidden.md) | Never branch on manipulated block environment values | advisory | C | logic keyed on coinbase or block fields |
| [FBD-03](forbidden.md) | Never use gasleft() as a control-flow signal | advisory | C | gasleft() thresholds steering loops or branches |
| [FBD-04](forbidden.md) | Never ignore the return value of send() | advisory | C | send() result discarded, failure path unhandled |
| [FBD-05](forbidden.md) | Never mark functions payable just to save gas | advisory | C | payable on functions not meant for ether |
| [FBD-06](forbidden.md) | Never take jump destinations from calldata | advisory | C | assembly JUMP to caller-supplied offset |
| [FBD-07](forbidden.md) | Never append hand-written bytecode subroutines to a contract | advisory | C | raw bytecode appended after runtime code |
| [FBD-08](forbidden.md) | Do not change public to external for gas | advisory | C | visibility flip justified by gas savings |
| [FBD-09](forbidden.md) | Do not rewrite > 0 as != 0 for gas | advisory | C | unsigned zero-check swapped citing gas |
