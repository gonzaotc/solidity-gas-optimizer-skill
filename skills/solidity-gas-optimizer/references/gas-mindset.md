# Gas mindset: cost-accounting the hot path

The catalog names known patterns. This file is the method for the waste no card names. Read it at scan time alongside `catalog/INDEX.md`. Both passes interrogate the per-function resource inventory built in Phase 1; they do not rebuild it. Its two passes run on the hottest in-scope functions, interleaved with the catalog match on those same functions (Phase 2 step 1); the full-catalog sweep of the colder remainder follows.

Gas-hunting is not bug-hunting. A bug hunter breaks assumptions; a gas hunter does cost-accounting. You are not looking for something that is wrong, you are looking for a gas unit that is spent without needing to be. The stance is accountant, not attacker: no threat model, no exploit chain, no victim. The only question is where each gas unit goes and whether that cost has to exist where it is paid.

## The anchor question

At every cost you trace, ask one thing:

> **Does this cost need to exist here?**

"Here" means this line, this frequency, this location in the lifecycle. A cost can be real and necessary in the abstract yet misplaced: paid on every call when once would do, paid warm-cost-free work as cold, paid inside a loop when the value is loop-invariant, paid at runtime when it could be paid once at deploy. The waste is the gap between what the semantics require and what the code spends.

## Discipline: greedy finder, measurement is the referee

Record every candidate the anchor question surfaces. Do not argue yourself out of one, do not self-censor a "probably the compiler handles it" hunch. Deciding whether a gas candidate is real needs no judgment from you: Phase 3 measurement is the objective referee, so the finder can be greedy where a security auditor cannot. That judgment is cheap, but the measurement itself is not free: each candidate that reaches Phase 3 costs a compile, targeted tests, and a benchmark cycle, run serially. So record generously, and let Phase 2's expected-value ordering (not this pass) decide what gets measured first. A candidate you drop during scan is gone; a candidate you record and that measures flat is one revert. Bias toward recording.

Output each observation in the Phase 2 candidate format (`{uncarded, location, why it applies, estimated impact, kind after policy, coverage}`), tagged `uncarded` unless the trace lands you back on a catalog card. For `estimated impact`, give a rough magnitude class (which resource, how often it is paid, hot or cold path), never a precise gas figure dressed as a measurement. An observation is a candidate, never a finding: only Phase 3 measurement and the Phase 5 challenge create findings.

## Pass A: resource-flow trace

The Phase 1 resource inventory already lists what each function spends on the EVM; Pass A interrogates the hot rows. Take each resource site the inventory names and apply the anchor question. Working from the written inventory rather than re-reading from memory is what makes this cost-accounting rather than a hunch: a resource on paper cannot be silently skipped. Interrogate each resource class it captures:

- **Storage reads (SLOAD)** — 2100 cold, 100 warm. Look for the same slot read more than once; a storage variable read inside a loop; a read whose value never changes across the call.
- **Storage writes (SSTORE)** — ~20000 to set a zero slot (plus 2100 cold access on first touch), ~2900–5000 to update a cold clean slot. A slot already written earlier in the transaction is far cheaper, and rewriting a slot's current value costs only warm access. Look for a slot written more than once in a call; a write of a value equal to what is already there; a write that a later branch overwrites.
- **External calls (CALL/STATICCALL)** — each distinct target incurs cold access (adds 2600); repeated access to the same target within the call is warm. Look for the same address called repeatedly when one call would do; data fetched per call that could be fetched once; `extcodesize`/existence checks paid more than once. A `DELEGATECALL` carries the same access cost and runs in the caller's context; a value-bearing call adds the 9000 call-with-value cost (less the stipend accounting).
- **Returndata** — copying the callee's return data into memory expands memory like any other copy. Look for large returns decoded when a bounded slice would do, or return data copied when it is unused.
- **Contract creation (CREATE/CREATE2)** — deploying from within a call pays for the created code's size plus init. Look for per-call deployment that could be a clone, or creation on a path that does not need a fresh contract.
- **Events (LOG)** — 375 per log plus 375 per indexed topic plus the memory and byte cost of the data. Look for redundant events, data logged that indexers do not use, or values indexed that need not be.
- **Calldata** — 16 gas per nonzero byte, 4 per zero. Look for `abi.decode` of the same region twice; arguments copied to memory only to be read once; a `calldata` pointer that would avoid the copy; unused or redundant arguments. Narrowing an integer type does not shrink standard ABI calldata: `uint8` and `uint256` both occupy a 32-byte word, so that is a storage-packing win, not a calldata one.
- **Memory** — expansion cost grows with the high-water mark: linear per word, plus a quadratic term that dominates only at large sizes. Look for arrays or structs allocated larger than used; copies (`memory` params, `abi.encode`) that a `calldata` or storage pointer would avoid. Revert-data construction spends here too: a long revert string or a rich custom-error payload stages bytes in memory on the failing path, so keep error data lean.
- **Loops / control** — every per-iteration cost multiplies by count. Look for loop-invariant reads, calls, or computations hoistable out; `.length` re-read each iteration; bounds that could be tightened.
- **Hashing (KECCAK256)** — 30 + 6 per word, plus the memory to stage the preimage. Look for the same hash (mapping key, domain separator, selector) recomputed within a call or across calls where it is constant.
- **Recomputation** — any arithmetic or derived value computed more than once from unchanged inputs.

Across the inventory, apply the anchor question to each entry: which resource is paid **more often, colder, wider, or earlier** than the semantics require? Each "yes" is a candidate.

## Pass B: lifecycle and paired-path diff

Costs also hide in the relationship between two paths that should agree, or between the first execution and the rest. Diff these pairs and account for the delta:

- **view vs write** — a getter and the writer of the same state: does the writer recompute what it could cache, or the getter re-derive what it could store?
- **deposit vs withdraw** (any inverse pair) — asymmetric cost between operations that mirror each other often marks avoidable work on the heavier side.
- **happy vs revert** — is expensive work done before a check that can revert? Move the cheap guard first so the failing path pays less and the happy path is unchanged. Preserve revert precedence: when two checks can both fail, reordering changes which error the caller receives, so only hoist a guard past work it does not depend on.
- **first vs subsequent** — a one-time zero→nonzero SSTORE, a lazy init, a persistent cache initialized on first use (a storage value written once and read thereafter, not EVM warmth, which resets every transaction): is a per-call cost actually amortizable, or is a one-time cost being paid every time?
- **constructor vs runtime** — a value derived at runtime but fixed for the deployment can be `immutable` (set in the constructor, baked into runtime code), read from code instead of storage and dropping the SLOAD. `constant` is not an option here: it requires a compile-time-known value. Conversely, code or data that bloats every deployment but runtime never needs.
- **one call vs many** — batch and loop forms of the same operation: fixed per-call overhead (dispatch, cold access, repeated guards) that batching pays once.

For each pair, name the cheaper path's shape and ask whether the expensive path could take it without changing behavior. The semantic constraint that must survive is the pair's contract with the caller: same result, same events, same reverts.

## Boundary: what this method does not do

It does not assign severity (that is measured gas impact in Phase 3), does not score confidence, and does not reason about attackers, profit, or safety beyond the semantic-equivalence constraint each candidate must preserve. It surfaces candidates. Measurement and the tradeoff challenge decide the rest.
