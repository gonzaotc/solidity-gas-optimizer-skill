# Execution and compiler (EXE)

Local codegen and execution-cost techniques that stay in plain Solidity: comparison and control-flow shape, arithmetic strength reduction, compiler configuration, and function-dispatch cost. Modern solc (0.8.2x, especially via-IR) already performs several of these, so every card assumes a before/after gas measurement rather than blind application.

## EXE-01 · Prefer strict comparisons
- **Kind**: transform
- **Tier**: A
- **Detect**: `<=` or `>=` in conditions, especially hot paths; grep `>=` and `<=` inside `if (`/`require(`
- **Transform**: where integer semantics allow, restate the bound strictly, e.g. `x >= 1` becomes `x > 0`
- **Savings**: ~3 gas per comparison; the EVM only has `LT`/`GT`/`EQ`, so non-strict forms compile to a comparison plus `ISZERO`
- **Preconditions**: integer operands where the boundary shift is exact. Not a guaranteed win: surrounding codegen can flip the result, so benchmark both variants and keep the cheaper one
- **Risks**: off-by-one bugs if the bound is adjusted incorrectly; none when the rewrite is exactly equivalent
- **Source**: RareSkills Gas Book, Compiler-related #1

## EXE-02 · Split conjunctive require statements
- **Kind**: transform
- **Tier**: A
- **Detect**: `&&` inside `require(`
- **Transform**: one `require` per conjunct, preserving the original left-to-right order
- **Savings**: small; separate statements let the compiler branch directly on each check instead of materializing a combined boolean, and a failing first check reverts before later ones run
- **Preconditions**: benchmark both variants; the gain is context-dependent and via-IR may equalize them
- **Risks**: if the original had one revert string, splitting either duplicates it (bigger bytecode) or changes the observable message per branch
- **Source**: RareSkills Gas Book, Compiler-related #2

## EXE-03 · Split disjunctive revert conditions
- **Kind**: transform
- **Tier**: B
- **Detect**: `if (` with `||` guarding a single `revert SomeError()`
- **Transform**: one `if`/`revert` per condition, optionally with a distinct custom error for each cause
- **Savings**: avoids evaluating the second condition once the first fires and removes boolean-combination codegen
- **Preconditions**: conditions are independent and side-effect-free; benchmark both shapes
- **Risks**: introducing new error types changes the contract's revert ABI; integrators and tests matching the old selector break. Tier B because the external error surface moves
- **Source**: RareSkills Gas Book, Compiler-related #3

## EXE-04 · Use named return variables
- **Kind**: transform
- **Tier**: A
- **Detect**: `returns (type)` without a name plus an explicit `return expr;` in the body
- **Transform**: name the return variable in the signature and assign to it instead of using `return`
- **Savings**: minor; declaring the slot in the signature lets the compiler skip an extra local copy in most functions
- **Preconditions**: exceptions exist, so when in doubt compile both versions and compare; via-IR frequently erases the difference on solc 0.8.x
- **Risks**: none semantically; an unassigned named return silently yields the zero value, so ensure every path assigns it
- **Source**: RareSkills Gas Book, Compiler-related #4

## EXE-05 · Swap branches to remove a negation
- **Kind**: transform
- **Tier**: A
- **Detect**: `if (!` followed by an `else` block
- **Transform**: test the positive condition and exchange the two branch bodies
- **Savings**: drops one `ISZERO` (3 gas) per evaluation
- **Preconditions**: an `else` branch must exist so the swap is purely structural; the optimizer sometimes performs this itself, so benchmark both forms
- **Risks**: none if the branch bodies are swapped correctly
- **Source**: RareSkills Gas Book, Compiler-related #5

## EXE-06 · Pre-increment instead of post-increment
- **Kind**: transform
- **Tier**: A
- **Detect**: `i++` or `i--` as a standalone statement, typically in loop headers
- **Transform**: replace with `++i` / `--i`
- **Savings**: post-increment must keep the old value on the stack even when discarded, costing an extra stack operation; pre-increment does not
- **Preconditions**: expression result must be unused. On modern solc 0.8.x with the optimizer (and via-IR in particular) the two usually compile identically, so verify there is a measurable difference
- **Risks**: semantic change if the expression value was actually consumed
- **Source**: RareSkills Gas Book, Compiler-related #6

## EXE-07 · Use unchecked arithmetic where overflow is impossible
- **Kind**: transform
- **Tier**: B
- **Detect**: arithmetic on values with natural bounds: loop counters below a limit, inputs already range-validated, monotonic counters incremented by small steps
- **Transform**: wrap the operation in an `unchecked { ... }` block
- **Savings**: removes the compiler-inserted overflow/underflow check (comparison plus conditional jump) on every operation
- **Preconditions**: a written overflow-impossibility argument covering every code path, including the variable's type width; re-derive it whenever surrounding code changes
- **Risks**: silent wraparound if the argument is wrong; this is a classic exploit source. Never apply without the documented proof
- **Source**: RareSkills Gas Book, Compiler-related #7

## EXE-08 · Gas-optimal loop counter pattern
- **Kind**: transform
- **Tier**: A
- **Detect**: `for (uint256 i = 0; i < n; i++)` on solc older than 0.8.22
- **Transform**: default-initialize the counter, move the increment into the body as `unchecked { ++i; }`
- **Savings**: combines the pre-increment and unchecked-counter savings: no overflow check and no discarded stack value per iteration
- **Preconditions**: loop bound guarantees the counter cannot overflow. Obsolete on solc >= 0.8.22, which removes the counter's overflow check automatically; on such versions leave the conventional loop alone
- **Risks**: none when the bound holds; noisier code for zero benefit on current compilers
- **Source**: RareSkills Gas Book, Compiler-related #8

## EXE-09 · Do-while instead of for
- **Kind**: transform
- **Tier**: B
- **Detect**: `for` loops in gas-critical paths
- **Transform**: guard the zero-iteration case, then loop with `do { ... } while (cond);`
```solidity
if (times == 0) return;
uint256 i;
do {
    unchecked { ++i; }
} while (i < times);
```
- **Savings**: the condition is checked after the body, removing one conditional jump per iteration; wins even with the added zero-iteration guard
- **Preconditions**: hot loop where per-iteration cost dominates; benchmark against the plain loop
- **Risks**: unconventional shape hurts readability and auditability; forgetting the zero-iteration guard executes the body once spuriously
- **Source**: RareSkills Gas Book, Compiler-related #9

## EXE-10 · Default to uint256 unless packing
- **Kind**: transform
- **Tier**: B
- **Detect**: standalone state variables or locals typed `uint8`/`uint16`/.../`uint128` or `bool` that share no slot with neighbors
- **Transform**: widen to `uint256` when the smaller width serves no packing purpose
- **Savings**: the EVM works on 256-bit words, so sub-word types force masking/extension operations on every access; full-width variables skip that
- **Preconditions**: the variable does not participate in a storage-slot or struct packing scheme, where small types are the win instead
- **Risks**: widening a state variable shifts storage layout and, if public, changes the getter ABI; range-restriction guarantees implied by the narrow type disappear
- **Source**: RareSkills Gas Book, Compiler-related #10

## EXE-11 · Order short-circuit operands deliberately
- **Kind**: transform
- **Tier**: B
- **Detect**: `||` / `&&` chains where the first operand is expensive (storage read, external call, hash) and the second is cheap, or where operand likelihood is known
- **Transform**: for `||`, put the operand most likely to be true first; for `&&`, put the one most likely to be false first; when likelihoods are unknown, put the cheaper operand first
- **Savings**: the second operand is skipped whenever the first decides the result, saving its full evaluation cost on the common path
- **Preconditions**: operands are side-effect-free and independent; you have a defensible estimate of which case dominates in production traffic
- **Risks**: reordering breaks code where the first operand guards the second (e.g. a bounds check before an access); likelihood assumptions can invert and make the common path more expensive
- **Source**: RareSkills Gas Book, Compiler-related #11

## EXE-12 · Avoid public visibility on state variables
- **Kind**: advisory
- **Tier**: B
- **Detect**: `public` state variables, especially constants only humans need to read
- **Transform**: declare `private`/`internal` when no on-chain caller needs the value
- **Savings**: each public variable adds an implicit getter, growing the dispatch table and runtime bytecode, which raises deployment cost and marginally lengthens selector matching
- **Preconditions**: no contract or integration depends on the generated getter; off-chain readers can still fetch the value directly from storage via node tooling
- **Risks**: removes part of the external API, which is a breaking interface change for existing integrators; visibility keywords never provide secrecy either way
- **Source**: RareSkills Gas Book, Compiler-related #12

## EXE-13 · Set a high optimizer runs value for hot contracts
- **Kind**: advisory
- **Tier**: B
- **Detect**: `runs: 200` (or similarly low) in compiler settings for a frequently called contract
- **Transform**: raise the `runs` parameter (e.g. to a very large value) in the optimizer config
- **Savings**: high runs tells the optimizer to favor runtime execution cost over creation-code size, cheapening every call for the contract's lifetime at a one-time deployment premium
- **Preconditions**: contract is called often enough that cumulative runtime savings outweigh the larger deploy cost
- **Risks**: bigger runtime bytecode can approach the EIP-170 24KB size cap; deployment gets more expensive
- **Source**: RareSkills Gas Book, Compiler-related #13

## EXE-14 · Mine low-value selectors for hot functions
- **Kind**: advisory
- **Tier**: B
- **Detect**: frequently called external functions whose 4-byte selectors have no leading zero bytes
- **Transform**: append a mined suffix to the function name (tooling exists to search suffixes) until the selector starts with zero bytes and sorts low
- **Savings**: with few functions, dispatch is a linear scan ordered by selector value, so low selectors match sooner; zero selector bytes also cost 4 gas each in calldata versus 16 for non-zero
- **Preconditions**: contract has four or fewer external functions for the linear-scan benefit (more triggers binary search, shrinking the dispatch gain); calldata savings apply regardless
- **Risks**: mangled names (`transfer_Xyz123`) hurt readability, tooling, and interface compatibility; renaming an existing function changes its selector and breaks callers
- **Source**: RareSkills Gas Book, Compiler-related #14

## EXE-15 · Shift instead of multiplying or dividing by powers of two
- **Kind**: transform
- **Tier**: B
- **Detect**: `* 2`, `/ 4`, `* 2 ** n`, or division/multiplication by any literal power of two on unsigned values
- **Transform**: replace `x * 2**n` with `x << n` and `x / 2**n` with `x >> n`
- **Savings**: `SHL`/`SHR` cost 3 gas versus 5 for `MUL`/`DIV`; larger savings come from Solidity emitting no overflow or division checks for shifts
- **Preconditions**: unsigned operands and constant shift amounts; the optimizer already strength-reduces literal power-of-two arithmetic on modern solc, so confirm a real difference
- **Risks**: `<<` wraps silently where checked `*` would revert, so the overflow protection is lost; for signed values `>>` rounds toward negative infinity while `/` truncates toward zero, giving wrong results
- **Source**: RareSkills Gas Book, Compiler-related #15

## EXE-16 · Consider caching calldata values in locals
- **Kind**: transform
- **Tier**: A
- **Detect**: repeated reads of the same calldata slot inside a loop, e.g. `arr.length` or `arr[i]` referenced multiple times
- **Transform**: copy the value into a local variable once and read the local thereafter
- **Savings**: although `calldataload` is cheap, the compiler sometimes generates less code around a cached stack local
- **Preconditions**: not a consistent win; the article is explicit that you must compile and measure both versions and keep whichever is cheaper
- **Risks**: none semantically for immutable calldata; slight verbosity
- **Source**: RareSkills Gas Book, Compiler-related #16

## EXE-17 · Branchless code and loop unrolling
- **Kind**: advisory
- **Tier**: B
- **Detect**: hot paths dense with conditionals; tight loops where the jump overhead rivals the body cost
- **Transform**: replace conditionals with equivalent arithmetic/bitwise expressions; partially unroll loops (e.g. process two elements per iteration to halve the jump count)
- **Savings**: eliminates `JUMPI`/`JUMP` opcodes, which cost more than plain arithmetic; unrolling amortizes the per-iteration condition check
- **Preconditions**: extreme-optimization contexts only, with measurements proving the branch overhead matters
- **Risks**: significantly harder to read, review, and audit; branchless equivalences are easy to get subtly wrong at boundaries
- **Source**: RareSkills Gas Book, Compiler-related #17

## EXE-18 · Inline internal functions with a single caller
- **Kind**: transform
- **Tier**: B
- **Detect**: `internal`/`private` function referenced from exactly one call site
- **Transform**: move the body into the caller and delete the function
- **Savings**: skips the jump into and out of the function body plus its jump destinations
- **Preconditions**: single caller, and the function is not an intentional override point; via-IR's inliner often does this automatically, so verify the gain on your compiler settings
- **Risks**: loses the abstraction and self-documenting name; in library code, removes a hook subclasses may rely on
- **Source**: RareSkills Gas Book, Compiler-related #18

## EXE-19 · Compare long arrays and strings by hash
- **Kind**: transform
- **Tier**: A
- **Detect**: element-by-element equality loops over `bytes`, `string`, or arrays longer than 32 bytes
- **Transform**: hash both sides and compare the digests
```solidity
function equal(bytes memory a, bytes memory b) internal pure returns (bool) {
    return keccak256(a) == keccak256(b);
}
```
- **Savings**: `KECCAK256` costs 30 gas plus 6 per word, far below a loop's per-element loads, bound checks, and jumps
- **Preconditions**: data longer than 32 bytes (a single-word compare is already one `EQ`); both sides in the same encoding
- **Risks**: none practical; hash-collision probability is negligible
- **Source**: RareSkills Gas Book, Compiler-related #19

## EXE-20 · Precomputed tables for powers and logarithms
- **Kind**: advisory
- **Tier**: B
- **Detect**: on-chain computation of fractional powers, roots, or logarithms where the base or the exponent is fixed
- **Transform**: precompute results (or curve segments) off-chain and ship them as a constant lookup table; interpolate or combine entries at runtime. Production fixed-point math in AMM and bonding-curve code uses this pattern
- **Savings**: replaces iterative approximation loops (many `MUL`/`DIV`/jumps per call) with a handful of constant reads and multiplications
- **Preconditions**: input domain is bounded and one parameter is fixed at build time; table precision matches the protocol's accuracy needs
- **Risks**: tables are hard to verify by inspection; a wrong entry is a silent correctness bug; larger bytecode raises deployment cost
- **Source**: RareSkills Gas Book, Compiler-related #20

## EXE-21 · Use precompiles for big-number and memory work
- **Kind**: advisory
- **Tier**: B
- **Detect**: modular exponentiation or large modular multiplication implemented in Solidity; large memory-copy loops
- **Transform**: call the modexp precompile (address 0x05) for big modular arithmetic, or the identity precompile (0x04) for bulk memory copies
- **Savings**: precompiles execute natively at fixed prices far below equivalent EVM bytecode
- **Preconditions**: chain supports the precompile; for memory copies, note that the `MCOPY` opcode (Cancun, solc 0.8.24+) supersedes the identity-precompile trick on chains that have it
- **Risks**: several L2s and alt-EVMs lack or misprice precompiles, breaking portability; raw `staticcall` plumbing adds audit surface
- **Source**: RareSkills Gas Book, Compiler-related #21

## EXE-22 · Chain multiplications instead of small constant exponents
- **Kind**: transform
- **Tier**: A
- **Detect**: `** 2`, `** 3`, or similar small-constant exponents on the `**` operator
- **Transform**: expand to repeated multiplication, e.g. `n ** 3` becomes `n * n * n`
- **Savings**: two `MUL` opcodes cost 10 gas total, while `EXP` costs 10 plus 50 per byte of the exponent (60 for a one-byte exponent)
- **Preconditions**: small constant exponents where the expansion stays readable; the optimizer may already strength-reduce constant exponents, so measure
- **Risks**: none; both checked forms revert identically on overflow in solc 0.8.x
- **Source**: RareSkills Gas Book, Compiler-related #22
