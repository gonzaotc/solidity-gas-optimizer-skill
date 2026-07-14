# Source coverage map

Optional attribution and coverage aid: credits sources and maps which article item each card came from. Not strictly required. Cards may be added from pasted snippets with no source, and those need no entry here. When you do work from a publication, mapping its items here documents coverage. Retired IDs stay recorded here so they are never reused.

## RareSkills Book of Gas Optimization

Source: https://www.rareskills.io/post/gas-optimization (84 items; 83 carded, one deliberately omitted).

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
