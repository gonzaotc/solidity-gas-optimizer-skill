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

## 0xKitsune EVM-Gas-Optimizations

Source: https://github.com/0xKitsune/EVM-Gas-Optimizations (26 README sections; the ETH-balance section is repeated verbatim, so 25 distinct techniques). No new cards: 20 already covered by existing cards, 1 contributed a runtime measurement to DEP-12, and 4 omitted as marginal or optimizer-handled with no distinct durable mechanism. Assembly-heavy and overlaps the RareSkills seed source; benchmarks predate solc 0.8.22.
Pulled: 2026-07-14.

| # | Section | Card |
|---|---|---|
| 1 | Use assembly for a contract's ETH balance | covered by ASM-06 |
| 2 | `unchecked{++i}` instead of `i++` | covered by EXE-06 (and EXE-07/EXE-08) |
| 3 | Use assembly for math (add/sub/mul/div) | covered by EXE-07 (assembly skips the same overflow check as `unchecked`, no further mechanism) |
| 4 | Tightly pack storage variables | covered by ST-03 |
| 5 | Short circuiting | covered by EXE-11 |
| 6 | Use `calldata` instead of `memory` | covered by CD-03 |
| 7 | Pack calldata where possible | covered by CD-04 |
| 8 | Cache memory values before a `for` loop | covered by EXE-24 (loop-invariant hoisting) |
| 9 | Cache array length in `for` loop | covered by EXE-24 (calldata case EXE-16, storage case ST-02) |
| 10 | Pack structs | covered by ST-04 |
| 11 | `immutable`/`constant` for never-changed variables | covered by ST-06 |
| 12 | Use assembly to hash | covered by ASM-07 |
| 13 | Use assembly to call an external contract | covered by ASM-02 |
| 14 | Right shift instead of dividing by two | covered by EXE-15 |
| 15 | Left shift instead of multiplying by two | covered by EXE-15 |
| 16 | Use assembly to check for `address(0)` | covered by ASM-05 |
| 17 | Use assembly to compare a storage value | omitted: ~18 gas generic-assembly `sload`+`eq` variant, optimizer-dependent, no distinct durable mechanism |
| 18 | Use assembly to write storage values | omitted: ~66 gas generic-assembly `sstore` variant, same rationale |
| 19 | `array[i] += amount` over `array[i] = array[i] + amount` | omitted: the optimizer equalizes these; marginal and version-dependent |
| 20 | Use assembly for a contract's ETH balance (repeat of #1) | covered by ASM-06 (source repeats the section verbatim) |
| 21 | `if(x)` instead of `if(x == bool)` | omitted: trivial redundant-comparison cleanup the compiler already performs |
| 22 | Multiple `require()` instead of `&&` | covered by EXE-02 |
| 23 | Custom errors over string messages | covered by DEP-08 |
| 24 | Mark functions as payable | covered by DEP-02/DEP-07 (blanket-payable hazard is FBD-05) |
| 25 | Don't use SafeMath on solc >= 0.8.0 | DEP-12 (runtime measurement added: 348 vs 303 gas per add) |
| 26 | `int` can be more expensive than `uint` | covered by CD-02 |

## OpenZeppelin Forum: A Collection of Gas Optimisation Tricks

Source: https://forum.openzeppelin.com/t/a-collection-of-gas-optimisation-tricks/19966 (20 posts, 2021–2023). 1 new card (CD-05); the rest are canonical tricks already covered. Post #11 was deleted; its content (manual bit-packing) is recoverable from the replies #12/#13 and maps to ST-03/ST-04, so nothing is missing.
Pulled: 2026-07-14.

| Post | Trick | Card |
|---|---|---|
| 1 | Infinite allowance as `2**255` instead of `2**256-1` | CD-05 |
| 2 | Pack small types (uint64 timestamps) into one slot | covered by ST-03/ST-04 (timestamp sizing ST-14) |
| 3 | constant/immutable over storage | covered by ST-06 |
| 4 | Cache a re-read state variable in a local | covered by ST-02 |
| 5 | Payable constructor cuts 10 creation-code opcodes | covered by DEP-02 |
| 6 | "Upgrade to 0.8.4+" digest (SafeMath default, inliner, packed-struct fixes, custom errors, cache loop length, calldata over memory, immutable, short revert strings, unchecked increment) | meta-advice; sub-tricks covered by DEP-12, EXE-18, DEP-08, EXE-24/EXE-16, CD-03, ST-06, EXE-23, EXE-07/EXE-08 |
| 7, 10 | `!= 0` over `> 0` for unsigned | covered by FBD-09 (thread itself concludes no difference on solc 0.8.6+) |
| 8 | Shift over divide/multiply by two | covered by EXE-15 |
| 9 | Fallback avoids selector dispatch | omitted: one-line mention, no measurement, dangerous design; dispatch cost is EXE-14, packed fallback calldata is CD-04 |
| 9 | Negative values costlier in calldata (`0xf` prefix) | covered by CD-02 |
| 11–13 | Manual bit-packing vs packed struct (post #11 deleted) | covered by ST-03/ST-04 |
| 14–16 | `!=` cheaper than `<` for a max-boundary check | covered by EXE-01 (comparison-operator choice); thread concludes viaIR equalizes the bytecode |
| 20–21 | calldata for `string` params (constructor params must be memory) | covered by CD-03 |

## harendra-shakya/solidity-gas-optimization

Source: https://github.com/harendra-shakya/solidity-gas-optimization (README prose guide). No new cards: a derivative, pre-Berlin-era digest whose tricks are all already carded, several with stale numbers the catalog already corrects (storage-clearing and selfdestruct refunds). Its "Yul tricks" section is a verbatim copy of the transmissions11 list, so a future re-pull is not fresh material.
Pulled: 2026-07-14.

| Section | Trick | Card |
|---|---|---|
| Storage / Tips | Cache storage in memory, compute before writing, pack vars/structs, no zero-init, constants | ST-02, ST-03, ST-04, DEP-10, ST-06 |
| Storage / Refunds | Zero out unused slots for a refund (stale 15,000) | covered by ST-13 (catalog notes EIP-3529: 4,800, capped) |
| Storage / Refunds | Selfdestruct refund (stale 24,000) | covered by DEP-04 (obsolete; EIP-3529/6780) |
| Storage / Data types | bytes32 over string, smallest bytesN, uint8-alone-not-cheaper | ST-05, ST-03/ST-04, EXE-10 |
| Storage / Inheritance | Child vars pack with parent vars (C3 linearization) | covered by ST-03/ST-04 (same slot-packing mechanism) |
| Storage / Memory vs Storage | Storage pointer instead of copying to memory | covered by ST-11 |
| Variables | Avoid public / prefer private, events over storage, named returns | EXE-12, ST-16, EXE-04 |
| Variables / Mapping vs Array | Mapping over array | covered by ST-07 |
| Variables / Fixed vs Dynamic | Fixed-size arrays, bytes32 for short string | ST-15, ST-05 |
| Variables / Fixed vs Dynamic | Additive over subtractive array ops | omitted: this is the ST-13/ST-01 refund mechanism, and as stated is partly wrong (truncating earns the refund) |
| Functions | external/calldata params, function ordering, payable, modifiers-as-functions | CD-03 (FBD-08 for the debunked external<public claim), EXE-14, DEP-02/DEP-07 (FBD-05), DEP-05 |
| Functions / Fallback | Fallback avoids selector dispatch | omitted: one-line mention, no measurement; dispatch cost is EXE-14, packed fallback calldata CD-04 |
| Loops | Memory vars, avoid unbounded, no zero-init, `++i` | ST-02/EXE-24, DEP-10, EXE-06 |
| Operations | Operand ordering, short-circuiting, unchecked | EXE-11, EXE-07 |
| Other | Dead code, minimize cross-contract calls (EXTCODESIZE) | DEP-11, XC-06 |
| Other / Libraries | External library keeps bytecode out of client | covered-adjacent DEP-12 (same lib-vs-inline deployment tradeoff, opposite direction) |
| Other / Errors | Short require strings; require-vs-assert gas | EXE-23; assert note omitted (stale pre-0.8 and a correctness point, not gas) |
| Other / Hash | keccak256 cheaper than sha256/ripemd160 | omitted: applicable only when hash choice is free, which interop almost always dictates otherwise |
| Other | ERC1167 minimal proxy for many clones | covered by DEP-06 |
| Merkle proof | Prove large data with a small proof | omitted: one-line, no mechanism; the allowlist-specific tradeoff is ARC-02 |
| Yul tricks | Access lists | covered by XC-03 |
| Yul tricks | Keep data in calldata; sub-32-byte caveat; negative-value calldata cost; write to existing slot (EIP-2200); SSTORE2 | CD-03, EXE-10, CD-02, ST-01, ST-10 |
| Yul tricks | Vanity-pack two addresses into one storage slot | omitted: covered-adjacent ST-03 + CD-01; exotic, no measurement |
| Yul tricks | `iszero()` before JUMP; `gas()` in `call()`; copy Solmate assembly; verify Yul beats compiler | omitted: opaque/version-dependent micro-tips or meta-advice, no durable mechanism |
| Yul tricks | Remove unnecessary NFT zero-address checks | omitted: security-sensitive contest advice, not a mechanical gas transform |
