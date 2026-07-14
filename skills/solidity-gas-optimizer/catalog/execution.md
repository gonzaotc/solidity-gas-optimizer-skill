# Execution and compiler (EXE)

Local codegen and execution-cost techniques that stay in plain Solidity: comparison and control-flow shape, arithmetic strength reduction, compiler configuration, and function-dispatch cost. Modern solc (0.8.2x, especially via-IR) already performs several of these, so every card assumes a before/after gas measurement rather than blind application.

## EXE-01 · Prefer strict comparisons
- **Kind**: transform
- **Detect**: `<=` or `>=` in conditions, especially hot paths; grep `>=` and `<=` inside `if (`/`require(`
- **Hint**: `<=` or `>=` in conditions
- **Transform**: where integer semantics allow, restate the bound strictly, e.g. `x >= 1` becomes `x > 0`
- **Savings**: ~3 gas per comparison; the EVM only has `LT`/`GT`/`EQ`, so non-strict forms compile to a comparison plus `ISZERO`
- **Preconditions**: integer operands where the boundary shift is exact. Not a guaranteed win: surrounding codegen can flip the result, so benchmark both variants and keep the cheaper one
- **Risks**: off-by-one bugs if the bound is adjusted incorrectly; none when the rewrite is exactly equivalent
- **Source**: RareSkills Gas Book, Compiler-related #1

## EXE-02 · Split conjunctive require statements
- **Kind**: transform
- **Detect**: `&&` inside `require(`
- **Hint**: `&&` inside `require(`
- **Transform**: one `require` per conjunct, preserving the original left-to-right order
- **Savings**: small; separate statements let the compiler branch directly on each check instead of materializing a combined boolean, and a failing first check reverts before later ones run
- **Preconditions**: benchmark both variants; the gain is context-dependent and via-IR may equalize them
- **Risks**: if the original had one revert string, splitting either duplicates it (bigger bytecode) or changes the observable message per branch
- **Source**: RareSkills Gas Book, Compiler-related #2

## EXE-03 · Split disjunctive revert conditions
- **Kind**: transform
- **Detect**: `if (` with `||` guarding a single `revert SomeError()`
- **Hint**: `||` guarding a single revert
- **Transform**: one `if`/`revert` per condition, optionally with a distinct custom error for each cause
- **Savings**: avoids evaluating the second condition once the first fires and removes boolean-combination codegen
- **Preconditions**: conditions are independent and side-effect-free; benchmark both shapes
- **Risks**: introducing new error types changes the contract's revert ABI; integrators and tests matching the old selector break.
- **Source**: RareSkills Gas Book, Compiler-related #3

## EXE-04 · Use named return variables
- **Kind**: transform
- **Detect**: `returns (type)` without a name plus an explicit `return expr;` in the body
- **Hint**: anonymous `returns` plus explicit `return`
- **Transform**: name the return variable in the signature and assign to it instead of using `return`
- **Savings**: minor; declaring the slot in the signature lets the compiler skip an extra local copy in most functions
- **Preconditions**: exceptions exist, so when in doubt compile both versions and compare; via-IR frequently erases the difference on solc 0.8.x
- **Risks**: none semantically; an unassigned named return silently yields the zero value, so ensure every path assigns it
- **Source**: RareSkills Gas Book, Compiler-related #4

## EXE-05 · Swap branches to remove a negation
- **Kind**: transform
- **Detect**: `if (!` followed by an `else` block
- **Hint**: `if (!` with an `else`
- **Transform**: test the positive condition and exchange the two branch bodies
- **Savings**: drops one `ISZERO` (3 gas) per evaluation
- **Preconditions**: an `else` branch must exist so the swap is purely structural; the optimizer sometimes performs this itself, so benchmark both forms
- **Risks**: none if the branch bodies are swapped correctly
- **Source**: RareSkills Gas Book, Compiler-related #5

## EXE-06 · Pre-increment instead of post-increment
- **Kind**: transform
- **Detect**: `i++` or `i--` as a standalone statement, typically in loop headers
- **Hint**: standalone `i++` or `i--`
- **Transform**: replace with `++i` / `--i`
- **Savings**: post-increment must keep the old value on the stack even when discarded, costing an extra stack operation; pre-increment does not
- **Preconditions**: expression result must be unused. On modern solc 0.8.x with the optimizer (and via-IR in particular) the two usually compile identically, so verify there is a measurable difference
- **Risks**: semantic change if the expression value was actually consumed
- **Source**: RareSkills Gas Book, Compiler-related #6

## EXE-07 · Use unchecked arithmetic where overflow is impossible
- **Kind**: transform
- **Detect**: arithmetic on values with natural bounds: loop counters below a limit, inputs already range-validated, monotonic counters incremented by small steps
- **Hint**: naturally bounded arithmetic, loop counters
- **Transform**: wrap the operation in an `unchecked { ... }` block
- **Savings**: removes the compiler-inserted overflow/underflow check (comparison plus conditional jump) on every operation
- **Preconditions**: a written overflow-impossibility argument covering every code path, including the variable's type width; re-derive it whenever surrounding code changes
- **Risks**: silent wraparound if the argument is wrong; this is a classic exploit source. Never apply without the documented proof
- **Source**: RareSkills Gas Book, Compiler-related #7

## EXE-08 · Gas-optimal loop counter pattern
- **Kind**: transform
- **Detect**: `for (uint256 i = 0; i < n; i++)` on solc older than 0.8.22
- **Hint**: conventional for-loop, solc below 0.8.22
- **Transform**: default-initialize the counter, move the increment into the body as `unchecked { ++i; }`
- **Savings**: combines the pre-increment and unchecked-counter savings: no overflow check and no discarded stack value per iteration
- **Preconditions**: loop bound guarantees the counter cannot overflow. Obsolete on solc >= 0.8.22, which removes the counter's overflow check automatically; on such versions leave the conventional loop alone
- **Risks**: none when the bound holds; noisier code for zero benefit on current compilers
- **Source**: RareSkills Gas Book, Compiler-related #8

## EXE-09 · Do-while instead of for
- **Kind**: transform
- **Detect**: `for` loops in gas-critical paths
- **Hint**: for-loops in gas-critical paths
- **Transform**: guard the zero-iteration case, then loop with `do { ... } while (cond);`
```solidity
if (times == 0) {
    return;
}
uint256 i;
do {
    unchecked {
        ++i;
    }
} while (i < times);
```
- **Savings**: the condition is checked after the body, removing one conditional jump per iteration; remains a net saving even with the added zero-iteration guard
- **Preconditions**: hot loop where per-iteration cost dominates; benchmark against the plain loop
- **Risks**: unconventional shape hurts readability and auditability; forgetting the zero-iteration guard executes the body once spuriously
- **Source**: RareSkills Gas Book, Compiler-related #9

## EXE-10 · Default to uint256 unless packing
- **Kind**: transform
- **Detect**: standalone state variables or locals typed `uint8`/`uint16`/.../`uint128` or `bool` that share no slot with neighbors
- **Hint**: unpacked sub-word integer or bool
- **Transform**: widen to `uint256` when the smaller width serves no packing purpose
- **Savings**: the EVM works on 256-bit words, so sub-word types force masking/extension operations on every access; full-width variables skip that
- **Preconditions**: the variable does not participate in a storage-slot or struct packing scheme, where small types are the win instead
- **Risks**: widening a state variable shifts storage layout and, if public, changes the getter ABI; range-restriction guarantees implied by the narrow type disappear
- **Source**: RareSkills Gas Book, Compiler-related #10

## EXE-11 · Order short-circuit operands deliberately
- **Kind**: transform
- **Detect**: `||` / `&&` chains where the first operand is expensive (storage read, external call, hash) and the second is cheap, or where operand likelihood is known
- **Hint**: expensive first operand in boolean chain
- **Transform**: for `||`, put the operand most likely to be true first; for `&&`, put the one most likely to be false first; when likelihoods are unknown, put the cheaper operand first
- **Savings**: the second operand is skipped whenever the first decides the result, saving its full evaluation cost on the common path
- **Preconditions**: operands are side-effect-free and independent; you have a defensible estimate of which case dominates in production traffic
- **Risks**: reordering breaks code where the first operand guards the second (e.g. a bounds check before an access); likelihood assumptions can invert and make the common path more expensive
- **Source**: RareSkills Gas Book, Compiler-related #11

## EXE-12 · Avoid public visibility on state variables
- **Kind**: advisory
- **Detect**: `public` state variables, especially constants only humans need to read
- **Hint**: `public` variables without on-chain readers
- **Transform**: declare `private`/`internal` when no on-chain caller needs the value
- **Savings**: each public variable adds an implicit getter, growing the dispatch table and runtime bytecode, which raises deployment cost and marginally lengthens selector matching
- **Preconditions**: no contract or integration depends on the generated getter; off-chain readers can still fetch the value directly from storage via node tooling
- **Risks**: removes part of the external API, which is a breaking interface change for existing integrators; visibility keywords never provide secrecy either way
- **Source**: RareSkills Gas Book, Compiler-related #12

## EXE-13 · Set a high optimizer runs value for hot contracts
- **Kind**: advisory
- **Detect**: `runs: 200` (or similarly low) in compiler settings for a frequently called contract
- **Hint**: low `runs` on frequently called contract
- **Transform**: raise the `runs` parameter (e.g. to a very large value) in the optimizer config
- **Savings**: high runs tells the optimizer to favor runtime execution cost over creation-code size, cheapening every call for the contract's lifetime at a one-time deployment premium
- **Preconditions**: contract is called often enough that cumulative runtime savings outweigh the larger deploy cost
- **Risks**: bigger runtime bytecode can approach the EIP-170 24KB size cap; deployment gets more expensive
- **Source**: RareSkills Gas Book, Compiler-related #13

## EXE-14 · Mine low-value selectors for hot functions
- **Kind**: advisory
- **Detect**: frequently called external functions whose 4-byte selectors have no leading zero bytes
- **Hint**: hot functions with non-zero-leading selectors
- **Transform**: append a mined suffix to the function name (tooling exists to search suffixes) until the selector starts with zero bytes and sorts low
- **Savings**: with few functions, dispatch is a linear scan ordered by selector value, so low selectors match sooner (a Foundry benchmark measures ~22 gas per dispatch position); zero selector bytes also cost 4 gas each in calldata versus 16 for non-zero
- **Preconditions**: contract has four or fewer external functions for the linear-scan benefit (more triggers binary search, shrinking the dispatch gain); calldata savings apply regardless
- **Risks**: mangled names (`transfer_Xyz123`) hurt readability, tooling, and interface compatibility; renaming an existing function changes its selector and breaks callers
- **Source**: RareSkills Gas Book, Compiler-related #14

## EXE-15 · Shift instead of multiplying or dividing by powers of two
- **Kind**: transform
- **Detect**: `* 2`, `/ 4`, `* 2 ** n`, or division/multiplication by any literal power of two on unsigned values
- **Hint**: mul/div by literal power of two
- **Transform**: replace `x * 2**n` with `x << n` and `x / 2**n` with `x >> n`
- **Savings**: `SHL`/`SHR` cost 3 gas versus 5 for `MUL`/`DIV`; larger savings come from Solidity emitting no overflow or division checks for shifts
- **Preconditions**: unsigned operands and constant shift amounts; the optimizer already strength-reduces literal power-of-two arithmetic on modern solc, so confirm a real difference
- **Risks**: `<<` wraps silently where checked `*` would revert, so the overflow protection is lost; for signed values `>>` rounds toward negative infinity while `/` truncates toward zero, giving wrong results
- **Source**: RareSkills Gas Book, Compiler-related #15

## EXE-16 · Consider caching calldata values in locals
- **Kind**: transform
- **Detect**: repeated reads of the same calldata slot inside a loop, e.g. `arr.length` or `arr[i]` referenced multiple times
- **Hint**: repeated calldata reads inside loops
- **Transform**: copy the value into a local variable once and read the local thereafter
- **Savings**: although `calldataload` is cheap, the compiler sometimes generates less code around a cached stack local
- **Preconditions**: not consistently cheaper; the article is explicit that you must compile and measure both versions and keep whichever is cheaper
- **Risks**: none semantically for immutable calldata; slight verbosity
- **Source**: RareSkills Gas Book, Compiler-related #16

## EXE-17 · Branchless code and loop unrolling
- **Kind**: advisory
- **Detect**: hot paths dense with conditionals; tight loops where the jump overhead rivals the body cost
- **Hint**: conditional-dense hot paths, tight loops
- **Transform**: replace conditionals with equivalent arithmetic/bitwise expressions; partially unroll loops (e.g. process two elements per iteration to halve the jump count)
- **Savings**: eliminates `JUMPI`/`JUMP` opcodes, which cost more than plain arithmetic; unrolling amortizes the per-iteration condition check
- **Preconditions**: extreme-optimization contexts only, with measurements proving the branch overhead matters
- **Risks**: significantly harder to read, review, and audit; branchless equivalences are easy to get subtly wrong at boundaries
- **Source**: RareSkills Gas Book, Compiler-related #17

## EXE-18 · Inline internal functions with a single caller
- **Kind**: transform
- **Detect**: `internal`/`private` function referenced from exactly one call site
- **Hint**: internal function with one caller
- **Transform**: move the body into the caller and delete the function
- **Savings**: skips the jump into and out of the function body plus its jump destinations
- **Preconditions**: single caller, and the function is not an intentional override point; via-IR's inliner often does this automatically, so verify the gain on your compiler settings
- **Risks**: loses the abstraction and self-documenting name; in library code, removes a hook subclasses may rely on
- **Source**: RareSkills Gas Book, Compiler-related #18

## EXE-19 · Compare long arrays and strings by hash
- **Kind**: transform
- **Detect**: element-by-element equality loops over `bytes`, `string`, or arrays longer than 32 bytes
- **Hint**: element-wise equality loops over bytes
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
- **Detect**: on-chain computation of fractional powers, roots, or logarithms where the base or the exponent is fixed
- **Hint**: on-chain fractional power or log math
- **Transform**: precompute results (or curve segments) off-chain and ship them as a constant lookup table; interpolate or combine entries at runtime. Production fixed-point math in AMM and bonding-curve code uses this pattern
- **Savings**: replaces iterative approximation loops (many `MUL`/`DIV`/jumps per call) with a handful of constant reads and multiplications
- **Preconditions**: input domain is bounded and one parameter is fixed at build time; table precision matches the protocol's accuracy needs
- **Risks**: tables are hard to verify by inspection; a wrong entry is a silent correctness bug; larger bytecode raises deployment cost
- **Source**: RareSkills Gas Book, Compiler-related #20

## EXE-21 · Use precompiles for big-number and memory work
- **Kind**: advisory
- **Detect**: modular exponentiation or large modular multiplication implemented in Solidity; large memory-copy loops
- **Hint**: Solidity modexp or bulk memory copies
- **Transform**: call the modexp precompile (address 0x05) for big modular arithmetic, or the identity precompile (0x04) for bulk memory copies
- **Savings**: precompiles execute natively at fixed prices far below equivalent EVM bytecode
- **Preconditions**: chain supports the precompile; for memory copies, note that the `MCOPY` opcode (Cancun, solc 0.8.24+) supersedes the identity-precompile approach on chains that have it
- **Risks**: several L2s and alt-EVMs lack or misprice precompiles, breaking portability; raw `staticcall` plumbing adds audit surface
- **Source**: RareSkills Gas Book, Compiler-related #21

## EXE-22 · Chain multiplications instead of small constant exponents
- **Kind**: transform
- **Detect**: `** 2`, `** 3`, or similar small-constant exponents on the `**` operator
- **Hint**: `**` with small constant exponent
- **Transform**: expand to repeated multiplication, e.g. `n ** 3` becomes `n * n * n`
- **Savings**: two `MUL` opcodes cost 10 gas total, while `EXP` costs 10 plus 50 per byte of the exponent (60 for a one-byte exponent)
- **Preconditions**: small constant exponents where the expansion stays readable; the optimizer may already strength-reduce constant exponents, so measure
- **Risks**: none; both checked forms revert identically on overflow in solc 0.8.x
- **Source**: RareSkills Gas Book, Compiler-related #22

## EXE-23 · Keep revert strings under 32 bytes
- **Kind**: transform
- **Detect**: `require(cond, "…")` or `revert("…")` whose string literal is 32 characters or longer
- **Hint**: revert string literals of 32+ characters
- **Transform**: shorten the message to 31 characters or fewer so it fits a single word, e.g. `require(balance > 0, "Bad Balance");`
- **Savings**: each extra 32-byte chunk of the string costs deployed bytecode (200 gas per byte) and extra memory stores when the revert path runs; the source benchmark measures the reverting call at 2,347 gas with a short string versus 2,578 with a long one (solc 0.8.13)
- **Preconditions**: only relevant where string reverts are kept at all; the shortened message must stay meaningful
- **Risks**: changes the observable revert message, breaking tests and integrators that match on it; custom errors (solc ≥0.8.4) are cheaper than any string and usually the better fix
- **Source**: WTF-gas-optimization, item 15

## EXE-24 · Hoist loop-invariant computation out of the loop
- **Kind**: transform
- **Detect**: an expression inside a loop body whose operands never change across iterations, recomputed every pass, e.g. a comparison on a variable not written in the loop
- **Hint**: loop-invariant expression recomputed each iteration
- **Transform**: evaluate the invariant expression once before the loop into a local, then read the local inside the loop
```solidity
bool increment = x > 1;
for (uint256 i; i <= 100; ++i) {
    if (increment) {
        sum += 1;
    }
}
```
- **Savings**: runs the expression's opcodes once instead of once per iteration
- **Preconditions**: operands provably unchanged for the loop's duration (not written in the body, no aliasing through storage or external calls); the optimizer performs loop-invariant code motion in many cases, so measure whether a manual hoist still helps
- **Risks**: hoisting an expression with side effects, or one that actually depends on a value the loop mutates, changes behavior; none when it is genuinely invariant
- **Source**: kadenzipfel gas-optimizations, Comparison with Unilateral Outcome in a Loop; Repeated Computations in a Loop

## EXE-25 · Replace a loop with its constant outcome
- **Kind**: transform
- **Detect**: a loop whose result is fixed at compile time because its bounds and body are constant, e.g. adding a literal a fixed number of times
- **Hint**: loop computing a compile-time-constant result
- **Transform**: drop the loop and return the precomputed constant
```solidity
function constantOutcome() public pure returns (uint256) {
    return 100;
}
```
- **Savings**: removes the per-iteration overhead (counter increment, bound comparison, conditional jump) and the body entirely, leaving a single constant
- **Preconditions**: the outcome is provably independent of any runtime input or state; solc constant-folds and can unroll small fixed loops but does not reliably collapse an arbitrary counted loop to its result, so measure
- **Risks**: the constant must equal the loop's result for every reachable state; a hidden input dependency makes the rewrite wrong
- **Source**: kadenzipfel gas-optimizations, Constant Outcome of a Loop

## EXE-26 · Remove redundant (opaque) predicates
- **Kind**: transform
- **Detect**: a condition whose truth is already implied by an enclosing condition, so it is always true when reached, e.g. `if (x > 1) { if (x > 0) { ... } }`
- **Hint**: nested condition already implied by an outer one
- **Transform**: drop the redundant inner check and inline its body
- **Savings**: removes the redundant comparison and conditional jump from every execution that reaches it
- **Preconditions**: the inner condition is logically entailed by the outer for all values; the optimizer resolves many such predicates, so confirm a measurable difference
- **Risks**: none when the entailment truly holds; misjudging it drops a check that was doing real work
- **Source**: kadenzipfel gas-optimizations, Opaque Predicate

## EXE-27 · Fuse loops over the same range
- **Kind**: transform
- **Detect**: two or more consecutive loops with identical bounds and independent bodies
- **Hint**: consecutive loops sharing the same bounds
- **Transform**: merge the bodies into a single loop over the shared range
```solidity
for (uint256 i; i < 100; ++i) {
    x += 1;
    y += 1;
}
```
- **Savings**: pays the loop control overhead (counter init, per-iteration comparison, increment, jump) once instead of once per loop
- **Preconditions**: identical iteration ranges and bodies that do not depend on a prior loop having fully completed
- **Risks**: fusing bodies that must run in separate full passes (one loop's later iterations feeding the next loop's early ones) changes results
- **Source**: kadenzipfel gas-optimizations, Loop Fusion

## EXE-28 · Check exact division with mulmod
- **Kind**: transform
- **Detect**: a divisibility/exactness check written by dividing then multiplying back, e.g. `value != (newValue * denominator) / numerator`
- **Hint**: exact-division check via mul then div
- **Transform**: test the remainder directly with `mulmod`
```solidity
newValue = (value * numerator) / denominator;
if (mulmod(value, numerator, denominator) != 0) {
    revert InExactDivision();
}
```
- **Savings**: `mulmod` does the multiply-and-mod in one opcode for 8 gas, versus a separate `MUL` (5) and `DIV` (5) for the round-trip check
- **Preconditions**: the check is verifying whether a division truncated; `mulmod(value, numerator, denominator)` is nonzero exactly when `(value * numerator)` is not divisible by `denominator`
- **Risks**: `mulmod` reverts on a zero modulus, matching division by zero; the intent reads less obviously than the explicit form
- **Source**: kadenzipfel gas-optimizations, Using Mulmod Over Mul & Div
