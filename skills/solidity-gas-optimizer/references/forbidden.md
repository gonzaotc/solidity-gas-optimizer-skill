# Forbidden and outdated (FBD)

Techniques the optimizer must never apply: seven are contest-only tricks that are unsafe in production, and two are obsolete micro-optimizations that no longer save gas on modern solc 0.8.x. They are cataloged so they can be flagged in code review and never re-proposed.

## FBD-01 · Never smuggle inputs through gas price or msg.value
- **Kind**: advisory
- **Tier**: C
- **Detect**: logic reads `tx.gasprice` or `msg.value` as a data input rather than for fee/payment purposes; functions taking fewer parameters than their logic clearly consumes
- **Transform**: pass values as ordinary function parameters in calldata
- **Savings**: skips calldata costs (4 gas per zero byte, 16 per nonzero, roughly 128+ gas per word-sized argument) by encoding the number in a transaction field the caller sets anyway
- **Preconditions**: only viable in a gas-golfing harness where ether is free and the test controls the effective gas price
- **Risks**: on a real network, encoding data in `msg.value` spends actual ether per call, and a data-chosen gas price either overpays or makes the transaction unattractive to include; the "input" channel is also unauthenticated and observable
- **Source**: RareSkills Gas Book, Dangerous techniques #1

## FBD-02 · Never branch on manipulated block environment values
- **Kind**: advisory
- **Tier**: C
- **Detect**: control flow keyed on `block.coinbase`, `block.number`, or similar environment opcodes used as a covert configuration channel
- **Transform**: drive behavior from explicit parameters, storage flags, or access control
- **Savings**: environment opcodes cost only 2 gas, cheaper than passing an equivalent calldata argument
- **Preconditions**: works only when a test framework lets the author dictate block fields; a contest-only side channel
- **Risks**: in production these values are set by block producers and the network, not the caller; behavior becomes nondeterministic and can be steered by validators, and the intended "signal" cannot be reproduced on-chain
- **Source**: RareSkills Gas Book, Dangerous techniques #2

## FBD-03 · Never use gasleft() as a control-flow signal
- **Kind**: advisory
- **Tier**: C
- **Detect**: `gasleft()` compared against thresholds to exit loops early or to select between code paths later in execution
- **Transform**: use an explicit loop counter, iteration bound, or state flag
- **Savings**: the gas counter decreases as a side effect of execution, so reading it provides a "free" progress indicator without maintaining a counter
- **Preconditions**: requires the exact gas cost of every executed opcode to be known and permanently stable
- **Risks**: gas schedules are repriced across hard forks, silently moving every threshold and changing behavior without a code change; the caller chooses the gas limit, so an attacker can supply a crafted gas amount to force whichever branch benefits them
- **Source**: RareSkills Gas Book, Dangerous techniques #3

## FBD-04 · Never ignore the return value of send()
- **Kind**: advisory
- **Tier**: C
- **Detect**: `payable(addr).send(amount)` used as a statement with the boolean result discarded; any ether transfer whose failure path is unhandled
- **Transform**: use `call{value: amount}("")` and require success, or prefer a pull-payment pattern; avoid `send()`/`transfer()` entirely because of the 2300-gas stipend
- **Savings**: `send()` omits the revert-on-failure opcodes that `transfer()` emits, and dropping the success check removes a few more, so the happy path is marginally cheaper
- **Preconditions**: only "safe" if every recipient is guaranteed to accept ether within 2300 gas, forever
- **Risks**: a failed transfer is silently swallowed: state proceeds as if payment happened while the ether stays behind, so recipients (multisigs, smart wallets, contracts with receive logic) can permanently lose funds owed to them. The 2300-gas stipend assumption is brittle: opcode repricings (EIP-1884 historically, and any future gas schedule change) can push a previously working recipient over the stipend
- **Source**: RareSkills Gas Book, Dangerous techniques #4

## FBD-05 · Never mark functions payable just to save gas
- **Kind**: advisory
- **Tier**: C
- **Detect**: `payable` on functions with no legitimate reason to receive ether, typically justified by a gas comment
- **Transform**: keep non-ether functions non-payable; restricting `payable` to constructors and admin-only functions is the acceptable variant, since deployers and admins are trusted with far more than stray ether
- **Savings**: removes the compiler-inserted `msg.value == 0` guard, a handful of opcodes per external call
- **Preconditions**: contest-only, where accidentally attached ether has no consequence
- **Risks**: users or integrating contracts can attach ether by mistake and it becomes stuck or requires sweep logic; balance-based accounting invariants (contract balance equals tracked deposits) silently break, and the savings are too small to justify the widened attack and mistake surface
- **Source**: RareSkills Gas Book, Dangerous techniques #5

## FBD-06 · Never take jump destinations from calldata
- **Kind**: advisory
- **Tier**: C
- **Detect**: assembly performing `JUMP` to an offset supplied in calldata; dispatch that replaces the standard 4-byte selector with a caller-provided code pointer
- **Transform**: use normal Solidity function dispatch through the compiler-generated selector table
- **Savings**: shrinks the effective selector to a single byte and skips the linear jump-table comparison sequence on every call
- **Preconditions**: every `JUMPDEST` in the bytecode audited as safe to enter directly, and all callers fully trusted
- **Risks**: callers can enter the code at any valid jump destination, including mid-function past access-control or validation checks, turning dispatch into an arbitrary-control-flow primitive; the pattern also relies on dynamic jumps, which the EOF upgrade path (EIP-3540 family) removes, so it is forward-incompatible with newer EVM code formats
- **Source**: RareSkills Gas Book, Dangerous techniques #6

## FBD-07 · Never append hand-written bytecode subroutines to a contract
- **Kind**: advisory
- **Tier**: C
- **Detect**: raw bytecode blobs placed after the compiler-generated runtime code (or in the metadata region) and reached by jumping out of and back into Solidity-emitted code, typically for hot routines like custom hash functions
- **Transform**: deploy the optimized routine as a separate contract and call it, or write it in reviewed inline assembly/Yul inside normal compiled code
- **Savings**: avoids the per-call account access cost of an external contract, 2600 gas cold or 100 warm under EIP-2929, on computation-heavy inner loops
- **Preconditions**: hand-verified bytecode plus a compiler version and settings frozen forever, since any output change shifts the jump offsets
- **Risks**: the appended code is invisible to the compiler's control-flow reasoning, to verification tooling, and to auditors reading Solidity; a settings or version bump silently relocates offsets so jumps land in the wrong place; EOF code validation (EIP-3540 family) rejects such out-of-band code sections and the dynamic jumps needed to reach them, and the extra bytes push against the EIP-170 24KB runtime size cap
- **Source**: RareSkills Gas Book, Dangerous techniques #7

## FBD-08 · Do not change public to external for gas
- **Kind**: advisory
- **Tier**: C
- **Detect**: visibility flipped from `public` to `external` with a gas-saving justification in the diff, comment, or review note
- **Transform**: choose visibility by API intent alone: `external` when the function is never called internally (clarity), `public` when it is
- **Savings**: claimed savings date from old compilers, where `public` functions copied their arguments into memory while `external` ones read calldata directly
- **Preconditions**: none on any supported compiler
- **Risks**: obsolete: modern solc 0.8.x emits identical parameter-handling code for both visibilities, so the change saves zero gas; re-adding it as an "optimization" only churns the API surface and misleads reviewers about where gas actually goes
- **Source**: RareSkills Gas Book, Outdated tricks #1

## FBD-09 · Do not rewrite > 0 as != 0 for gas
- **Kind**: advisory
- **Tier**: C
- **Detect**: unsigned comparisons `x > 0` swapped to `x != 0` (or the reverse) with a gas rationale
- **Transform**: keep whichever comparison reads most naturally for the invariant being expressed
- **Savings**: claimed to drop one comparison opcode's worth of gas per check on very old compilers
- **Preconditions**: only measurable on legacy compilers, roughly pre-0.8.12; benchmark before applying even there
- **Risks**: obsolete: since around solc 0.8.12 the compiler produces equivalent bytecode for both forms of an unsigned zero check, so on modern 0.8.x the rewrite saves nothing and only adds noise to diffs and review discussions
- **Source**: RareSkills Gas Book, Outdated tricks #2
