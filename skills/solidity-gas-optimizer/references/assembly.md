# Assembly (ASM)

Techniques that require dropping into inline assembly (Yul) to bypass the Solidity compiler's memory management, type checks, or branching codegen. Never assume assembly wins automatically: benchmark against the plain-Solidity version under your exact compiler settings before adopting any of these.

## ASM-01 · Revert with a string error from assembly
- **Kind**: transform
- **Tier**: B
- **Detect**: `require(cond, "...")` or `revert("...")` with a short string literal on a hot path
- **Transform**: replace the check with an assembly block that, on failure, hand-encodes the `Error(string)` payload in low memory (offset word, length word, message bytes) and calls `revert(ptr, len)`
- **Savings**: roughly 300 gas per revert path in the article's benchmark; comes from skipping the compiler's memory expansion and implicit type-checking around string revert encoding
- **Preconditions**: message fits in one 32-byte word; on solc >= 0.8.4 a custom error (4-byte selector, no string encoding at all) is usually cheaper than either variant and needs no assembly, so measure before choosing this
- **Risks**: hand-encoded ABI payload is easy to get wrong (wrong length word silently corrupts the message); block writes memory, so any `memory-safe` annotation is a claim you must be able to prove — writing past scratch is only defensible here because the path unconditionally reverts, and a false annotation corrupts optimizer codegen
- **Source**: RareSkills Gas Book, Assembly #1

## ASM-02 · Make single external calls with hand-rolled calldata in scratch space
- **Kind**: transform
- **Tier**: C
- **Detect**: `IFoo(addr).fn(args)` interface calls where the encoded arguments fit in 64 bytes or memory already holds reusable data
- **Transform**: in assembly, `mstore` the 4-byte selector and arguments into scratch space (or previously used memory), then `call`/`staticcall` directly instead of going through the interface
- **Savings**: about 220 gas in the article's benchmark; avoids the memory expansion Solidity performs by ABI-encoding call arguments at the free memory pointer
- **Preconditions**: encoded calldata <= 64 bytes if using scratch space; larger payloads need reusable memory you can prove is dead
- **Risks**: a `call` to an address with no code returns success, so you must add an explicit `extcodesize(addr)` check and revert on zero or the contract logic silently proceeds; return data handling and ABI encoding become your responsibility; block writes memory, so the `memory-safe` annotation must be provably true — lying to the optimizer corrupts codegen
- **Source**: RareSkills Gas Book, Assembly #2

## ASM-03 · Branchless min/max and similar math primitives
- **Kind**: transform
- **Tier**: B
- **Detect**: ternary comparisons like `x > y ? x : y` or `a < b ? a : b`, hand-rolled min/max/abs helpers
- **Transform**: replace the conditional with a branchless assembly expression that selects via a comparison flag, e.g. for max:
  ```solidity
  assembly {
      z := xor(a, mul(xor(a, b), gt(b, a)))
  }
  ```
- **Savings**: small per call; a ternary compiles to conditional `JUMPI`s, and jump-based branching costs more than the straight-line arithmetic sequence
- **Preconditions**: worth it only on hot paths; check whether via-IR at high optimizer runs already produces comparable code for your case. Mature branchless implementations of many math ops exist in gas-optimized libraries (e.g. Solady), which are safer to adopt than re-deriving your own
- **Risks**: the selection formula is opaque and easy to transcribe wrong (swapped `gt`/`lt` silently returns min instead of max); pure stack operations, no memory touched
- **Source**: RareSkills Gas Book, Assembly #3

## ASM-04 · Inequality via SUB or XOR instead of ISZERO(EQ)
- **Kind**: transform
- **Tier**: B
- **Detect**: `iszero(eq(a, b))` patterns inside existing assembly blocks
- **Transform**: use `if sub(a, b) { ... }` (or `xor(a, b)`) as the not-equal condition, since a nonzero difference is truthy, dropping the `ISZERO` opcode
- **Savings**: marginal (one opcode); the article qualifies it as more efficient only in certain scenarios
- **Preconditions**: result depends on compiler version and surrounding code — the optimizer often produces identical bytecode either way, so diff the output or snapshot gas before keeping it
- **Risks**: the article warns that when substituting `xor`, a value with all bits flipped can also satisfy the check, so confirm that cannot be steered by an attacker; readability of the condition drops (intent of `sub` as "not equal" is non-obvious); no memory touched
- **Source**: RareSkills Gas Book, Assembly #4

## ASM-05 · Zero-address check in assembly
- **Kind**: transform
- **Tier**: B
- **Detect**: `require(addr != address(0), "...")` or `if (addr == address(0)) revert ...` guards
- **Transform**: assembly block with `if iszero(addr)` that encodes the revert string in low memory and reverts, skipping Solidity's comparison and revert-string machinery
- **Savings**: around 90 gas per check in the article's benchmark, from fewer opcodes and avoided memory expansion
- **Preconditions**: on solc >= 0.8.4, reverting with a custom error from plain Solidity captures most of the saving with none of the assembly, so benchmark both; the assembly version only clearly wins over string-message reverts
- **Risks**: the article's layout writes through offset 0x40 (the free memory pointer slot), acceptable only because that path always reverts; any `memory-safe` annotation is a claim you must be able to prove, and a false claim corrupts optimizer codegen
- **Source**: RareSkills Gas Book, Assembly #5

## ASM-06 · SELFBALANCE instead of address(this).balance
- **Kind**: transform
- **Tier**: B
- **Detect**: `address(this).balance` reads
- **Transform**: read the contract's own balance via `selfbalance()` in assembly
- **Savings**: `SELFBALANCE` (5 gas, EIP-1884) versus the `BALANCE` opcode (100 gas warm under EIP-2929)
- **Preconditions**: the article itself notes the compiler sometimes applies this substitution on its own; solc targeting EVM version Istanbul or later generally emits `SELFBALANCE` for `address(this).balance` already, erasing the saving — test both forms under your exact settings
- **Risks**: none beyond the readability cost of an assembly block for a one-opcode read; no memory touched
- **Source**: RareSkills Gas Book, Assembly #6

## ASM-07 · Hash or emit up to 96 bytes from scratch space
- **Kind**: transform
- **Tier**: C
- **Detect**: `keccak256(abi.encode(...))` over data totaling <= 96 bytes; `emit` of events with <= 96 bytes of unindexed data
- **Transform**: `mstore` the words into memory offsets 0x00, 0x20, 0x40 and call `keccak256(0x00, len)` or `log1(0x00, len, topicHash)` directly, instead of letting Solidity ABI-encode at the free memory pointer
- **Savings**: article benchmarks show roughly 2,000 gas on a 3-word event and 1,000+ gas on a 3-word hash, from avoided memory expansion
- **Preconditions**: data must fit in 96 bytes — the two scratch words (0x00–0x3f) plus the free-memory-pointer word (0x40), which you may borrow only if you cache it on the stack and restore it before leaving assembly; skipping the restore is safe only when execution terminates inside the block (e.g. the function ends right after the log)
- **Risks**: clobbering the free memory pointer without restoring it breaks every subsequent Solidity memory operation; uninitialized dynamic memory values point at the zero slot (0x60), so corrupting it is equally dangerous; the `memory-safe` annotation is a claim you must be able to prove (pointer cached and restored, zero slot intact), and lying to the optimizer corrupts codegen
- **Source**: RareSkills Gas Book, Assembly #7

## ASM-08 · Reuse one memory region across multiple external calls
- **Kind**: transform
- **Tier**: C
- **Detect**: two or more external calls in one function, each with arguments encoding to <= 96 bytes
- **Transform**: encode the first call's selector and arguments in low memory, `call`/`staticcall`, then overwrite only the argument words for each subsequent call, reusing the same region; return data <= 96 bytes can also land in scratch/zero-slot space instead of freshly allocated memory
- **Savings**: about 2,000 gas over two calls in the article's benchmark; Solidity would re-encode each call and its return data at the free memory pointer, expanding memory every time
- **Preconditions**: pays off when arguments fit in 96 bytes, or, above 64 bytes of arguments, only once there is more than one call to amortize (the article notes a single large-argument call saves nothing significant); via-IR does not reclaim call-encoding memory either, so the technique remains relevant on modern solc
- **Risks**: must check `extcodesize` before calling (calls to codeless addresses succeed vacuously); if the zero slot (0x60) receives return data, restore it to zero before exiting or every uninitialized dynamic memory value afterward reads garbage; update the free memory pointer if you used its slot; the `memory-safe` annotation is a claim you must be able to prove, and a false claim corrupts optimizer codegen
- **Source**: RareSkills Gas Book, Assembly #8

## ASM-09 · Reuse memory when deploying multiple contracts
- **Kind**: transform
- **Tier**: C
- **Detect**: two or more `new Contract()` expressions in one function
- **Transform**: load the creation bytecode once, then issue each deployment via `create(value, add(code, 0x20), mload(code))` in assembly; store the returned addresses in scratch space instead of letting Solidity allocate fresh memory per deployment (contract creation behaves like an external call returning 32 bytes)
- **Savings**: close to 1,000 gas over two deployments in the article's benchmark, from avoided memory expansion for the returned addresses
- **Preconditions**: deployments of the same bytecode can share one loaded copy; the article notes that deploying two different contracts requires manually `mstore`-ing the second creation code inside assembly rather than binding it to a Solidity variable, or the allocation reintroduces the expansion
- **Risks**: `create` returns the zero address on failure instead of reverting, so you must check each result and revert explicitly; constructor arguments and value forwarding are entirely manual; the block writes memory, so the `memory-safe` annotation is a claim you must be able to prove, and lying to the optimizer corrupts codegen
- **Source**: RareSkills Gas Book, Assembly #9

## ASM-10 · Parity check with a bitmask instead of modulo
- **Kind**: transform
- **Tier**: B
- **Detect**: `x % 2 == 0` or `x % 2 == 1` parity tests
- **Transform**: test the lowest bit instead: `x & 1 == 0` for even, `x & 1 == 1` for odd; the last binary digit fully determines parity since every higher bit contributes an even amount
- **Savings**: a few gas; `AND` (3 gas) is cheaper than `MOD` (5 gas)
- **Preconditions**: unsigned integers; the solc optimizer rewrites modulo by a power of two into a mask anyway, so with the optimizer enabled (any modern 0.8.x configuration) the two forms typically compile identically — verify with a gas snapshot before claiming a win
- **Risks**: none of substance; despite its placement in the assembly section this needs no assembly block and touches no memory
- **Source**: RareSkills Gas Book, Assembly #10
