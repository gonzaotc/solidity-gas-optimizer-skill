# Source coverage map

Optional attribution and coverage aid: credits sources and maps which article item each card came from. Not strictly required. Cards may be added from pasted snippets with no source, and those need no entry here. When you do work from a publication, mapping its items here documents coverage. Retired IDs stay recorded here so they are never reused.

Each section records the date the source was pulled, so a later revision of the source can be diffed against what was carded.

## RareSkills Book of Gas Optimization

Source: https://www.rareskills.io/post/gas-optimization (84 items; 83 carded, one deliberately omitted).
Pulled: 2026-07-13.

| Article section | # | Article item (abbreviated) | Card |
|---|---|---|---|
| Storage | 1 | Avoid zero-to-one storage writes | ST-01 |
| Storage | 2 | Cache storage variables | ST-02 |
| Storage | 3 | Pack related variables | ST-03 |
| Storage | 4 | Pack structs | ST-04 |
| Storage | 5 | Keep strings under 32 bytes | ST-05 |
| Storage | 6 | Immutable/constant for never-updated variables | ST-06 |
| Storage | 7 | Mappings instead of arrays | ST-07 |
| Storage | 8 | unsafeAccess on arrays | ST-08 |
| Storage | 9 | Bitmaps instead of bools | ST-09 |
| Storage | 10 | SSTORE2/SSTORE3 for bulk data | ST-10 |
| Storage | 11 | Storage pointers instead of memory | ST-11 |
| Storage | 12 | Keep ERC20 balances nonzero | ST-12 |
| Storage | 13 | Count down to zero | ST-13 |
| Storage | 14 | Small types for timestamps/block numbers | ST-14 |
| Deployment | 1 | Predict addresses via account nonce | DEP-01 |
| Deployment | 2 | Payable constructors | DEP-02 |
| Deployment | 3 | Optimize IPFS hash / no CBOR metadata | DEP-03 |
| Deployment | 4 | selfdestruct in constructor | DEP-04 |
| Deployment | 5 | Internal functions vs modifiers | DEP-05 |
| Deployment | 6 | Clones/metaproxies for similar contracts | DEP-06 |
| Deployment | 7 | Payable admin functions | DEP-07 |
| Deployment | 8 | Custom errors over require strings | DEP-08 |
| Deployment | 9 | Existing create2 factories | DEP-09 |
| Cross-contract calls | 1 | Transfer hooks instead of pull transfers | XC-01 |
| Cross-contract calls | 2 | fallback/receive instead of deposit() | XC-02 |
| Cross-contract calls | 3 | ERC-2930 access lists | XC-03 |
| Cross-contract calls | 4 | Cache external call results | XC-04 |
| Cross-contract calls | 5 | Multicall in routers | XC-05 |
| Cross-contract calls | 6 | Monolithic architecture | XC-06 |
| Design patterns | 1 | Multidelegatecall batching | ARC-01 |
| Design patterns | 2 | ECDSA signatures over merkle trees | ARC-02 |
| Design patterns | 3 | ERC20Permit approval+transfer batching | ARC-03 |
| Design patterns | 4 | L2 message passing | ARC-04 |
| Design patterns | 5 | State channels | ARC-05 |
| Design patterns | 6 | Voting delegation | ARC-06 |
| Design patterns | 7 | ERC-1155 over ERC-721 | ARC-07 |
| Design patterns | 8 | One ERC-1155/ERC-6909 over several ERC-20s | ARC-08 |
| Design patterns | 9 | UUPS vs Transparent proxy | ARC-09 |
| Design patterns | 10 | Alternatives to OpenZeppelin | omitted: library choice is a dependency decision, not a code transform (retired ID ARC-10) |
| Calldata | 1 | Vanity addresses | CD-01 |
| Calldata | 2 | Avoid signed integers in calldata | CD-02 |
| Calldata | 3 | Calldata over memory | CD-03 |
| Calldata | 4 | Packed calldata | CD-04 |
| Assembly | 1 | Assembly reverts | ASM-01 |
| Assembly | 2 | Reuse memory for interface calls | ASM-02 |
| Assembly | 3 | Efficient min/max | ASM-03 |
| Assembly | 4 | SUB/XOR inequality checks | ASM-04 |
| Assembly | 5 | Assembly address(0) check | ASM-05 |
| Assembly | 6 | selfbalance over address(this).balance | ASM-06 |
| Assembly | 7 | Assembly hashing/events ≤96 bytes | ASM-07 |
| Assembly | 8 | Reuse memory across external calls | ASM-08 |
| Assembly | 9 | Reuse memory across contract creations | ASM-09 |
| Assembly | 10 | Even/odd via last bit | ASM-10 |
| Compiler-related | 1 | Strict vs non-strict inequalities | EXE-01 |
| Compiler-related | 2 | Split require booleans | EXE-02 |
| Compiler-related | 3 | Split revert statements | EXE-03 |
| Compiler-related | 4 | Named returns | EXE-04 |
| Compiler-related | 5 | Invert negated if-else | EXE-05 |
| Compiler-related | 6 | ++i over i++ | EXE-06 |
| Compiler-related | 7 | Unchecked math | EXE-07 |
| Compiler-related | 8 | Gas-optimal for-loops | EXE-08 |
| Compiler-related | 9 | Do-while over for | EXE-09 |
| Compiler-related | 10 | Avoid unnecessary small-type casting | EXE-10 |
| Compiler-related | 11 | Short-circuit booleans | EXE-11 |
| Compiler-related | 12 | Avoid needless public variables | EXE-12 |
| Compiler-related | 13 | Large optimizer runs value | EXE-13 |
| Compiler-related | 14 | Optimal function names | EXE-14 |
| Compiler-related | 15 | Bitshift powers of two | EXE-15 |
| Compiler-related | 16 | Cache calldata when cheaper | EXE-16 |
| Compiler-related | 17 | Branchless algorithms | EXE-17 |
| Compiler-related | 18 | Inline once-used internal functions | EXE-18 |
| Compiler-related | 19 | Hash-compare long arrays/strings | EXE-19 |
| Compiler-related | 20 | Lookup tables for powers/logs | EXE-20 |
| Compiler-related | 21 | Precompiles for math/memory ops | EXE-21 |
| Compiler-related | 22 | n*n*n over n**3 | EXE-22 |
| Dangerous techniques | 1 | gasprice()/msg.value as information channel | FBD-01 |
| Dangerous techniques | 2 | Manipulate coinbase()/block.number | FBD-02 |
| Dangerous techniques | 3 | gasleft() branching | FBD-03 |
| Dangerous techniques | 4 | send() without success check | FBD-04 |
| Dangerous techniques | 5 | Make all functions payable | FBD-05 |
| Dangerous techniques | 6 | External library jumping | FBD-06 |
| Dangerous techniques | 7 | Appended bytecode subroutines | FBD-07 |
| Outdated tricks | 1 | external over public | FBD-08 |
| Outdated tricks | 2 | != 0 over > 0 | FBD-09 |

## WTF-gas-optimization (WTF Academy)

Source: https://github.com/WTFAcademy/WTF-gas-optimization (24 items; 4 carded, 19 already covered by existing cards — 4 of those contributed measurements to the existing card — and 1 omitted).
Pulled: 2026-07-14.

| # | Item (abbreviated) | Card |
|---|---|---|
| 1 | use constant and immutable | covered by ST-06 |
| 2 | use calldata over memory | covered by CD-03 |
| 3 | use Bitmap | covered by ST-09 |
| 4 | use unchecked | covered by EXE-07 |
| 5 | use uint256 over uint8 | covered by EXE-10 |
| 6 | use custom error over require/assert | covered by DEP-08 |
| 7 | use local variable over storage | covered by ST-02 |
| 8 | use clone over new/create2 | covered by DEP-06 |
| 9 | packing storage slots | covered by ST-03 |
| 10 | use ++i as better increment | covered by EXE-06 |
| 11 | use uint in reentrancy guard | covered by ST-01 |
| 12 | use < over <= | covered by EXE-01 |
| 13 | optimized selector/method id | covered by EXE-14 |
| 14 | selector/method-id order matters | covered by EXE-14 (measurement added) |
| 15 | use shorter string in require() | EXE-23 |
| 16 | short circuit in logic operation | covered by EXE-11 |
| 17 | delete variables to get gas refund | covered by ST-13 |
| 18 | do not initialize state variables with default values | DEP-10 |
| 19 | swap 2 variables with destructuring assignment | omitted: saves no gas per the source's own measurement (282 gas both ways) |
| 20 | set constructor to payable | covered by DEP-02 |
| 21 | use bytes32 for short string | covered by ST-05 (measurement added) |
| 22 | use fixed-size array over dynamic array | ST-15 |
| 23 | use event to store data when possible | ST-16 |
| 24 | use mapping over array when possible | covered by ST-07 (measurement added) |

## kadenzipfel gas-optimizations

Source: https://github.com/kadenzipfel/gas-optimizations (21 items; 7 new cards from 8 items, 13 already covered, and 2 of those flagged against forbidden cards where the source's advice conflicts with the catalog).
Pulled: 2026-07-14.

| Section | Item | Card |
|---|---|---|
| Gas costly patterns | Comparison with Unilateral Outcome in a Loop | EXE-24 |
| Gas costly patterns | Constant Outcome of a Loop | EXE-25 |
| Gas costly patterns | Dead Code | DEP-11 |
| Gas costly patterns | Expensive Operations in a Loop | covered by ST-02 (cache storage in a local across the loop) |
| Gas costly patterns | Loop Fusion | EXE-27 |
| Gas costly patterns | Opaque Predicate | EXE-26 |
| Gas costly patterns | Repeated Computations in a Loop | EXE-24 (same loop-invariant-hoisting mechanism) |
| Gas costly patterns | Storage Variable as Loop Length | covered by ST-02 (cache `array.length` before the loop) |
| Gas costly patterns | Unnecessary Libraries | DEP-12 |
| Gas golfing | Short Revert Strings | covered by EXE-23 (custom-error alternative by DEP-08) |
| Gas golfing | Unchecked Arithmetic | covered by EXE-07 |
| Gas golfing | Optimal Comparison Operator | strict `<`/`>` covered by EXE-01; the source's `!=`-is-cheapest claim is the debunked pattern in FBD-09, not adopted |
| Gas golfing | Payable Functions | FBD-05 (the source itself flags the security trade-off; the safe scoped cases are DEP-02 and DEP-07) |
| Gas golfing | Function Ordering | covered by EXE-14 |
| Gas golfing | Using Mulmod Over Mul & Div | EXE-28 |
| Gas golfing | Optimal Increment and Decrement Operators | covered by EXE-06 |
| Gas saving patterns | Proper Data Types | covered by EXE-10 (bytes32-over-string by ST-05) |
| Gas saving patterns | Explicit Function Visibility | the calldata-location benefit is covered by CD-03; the "external cheaper than public" claim is the debunked pattern in FBD-08, not adopted |
| Gas saving patterns | Short Circuiting | covered by EXE-11 |
| Gas saving patterns | Constants and Immutables | covered by ST-06 |
| Gas saving patterns | Struct Bit Packing | covered by ST-04 (manual bit-packing by ST-03) |
