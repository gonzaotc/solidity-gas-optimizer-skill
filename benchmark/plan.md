<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

# Benchmark plan

The benchmark measures whether the optimizer finds real gas savings, verifies them correctly, respects the active policy, and does so at acceptable cost. Full design and its sources live in `research/final-evaluation-strategy.md`. This file is the executable roadmap: what ships now, what comes later.

The organizing fact carries both horizons: the system has a **ground-truth oracle** (compiler, gas reporter, test suite), so precision and correctness are executable checks. Recall needs a reference, and the tier design below supplies it cheaply: a hand-written `Good` tier whose measured gas is the target, so no per-technique answer key is required for the headline score.

## Short term (version 0 backbone, doable per session)

Goal: a small, honest, hand-graded suite that already works as the version-to-version regression backbone. Comparing two runs' scorecards shows a PR's effect.

The centerpiece is **tiered standards**. Each recognizable standard ships three implementations, `Bad`, `Medium`, `Good`, that pass one shared conformance suite, so they behave identically and differ only in gas. Grading is by **gas-gap closure**: run the optimizer on a lower tier and measure how much of the `tier minus good` gas gap it closes. The good tier is the measured ceiling, so recall needs no enumerated key. Each tier probes a different regime: `bad` tests recall (large gap), `good` tests precision and restraint (near the floor, a run should find almost nothing), `medium` tests both.

Built and measured:

- One Foundry project under `benchmark/fixtures/` with pinned compiler settings, so gas is deterministic.
- **ERC20** three tiers (`src/erc20/`) behind one `IERC20` interface, one shared suite (`test/erc20/ERC20Tiers.t.sol`).
- **AccessControl** three tiers (`src/accesscontrol/`) behind one `IAccessControl` interface, one shared suite.
- **OpenZeppelin references** (`ReferenceERC20`, `ReferenceAccessControl`, OZ Contracts v5.1.0 pinned) wrapped through the same interfaces and suites, as a real-world baseline column. Not the optimization target: OZ carries safety and flexibility the minimal tiers omit, so it sits above the good tier. See `answer-key.md` for how to read it.
- One isolated **discrimination case** (`src/isolated/PriceGuard.sol`): a reentrancy trap where caching a repeated read would change behavior, so the tool must abstain. The tier ladder tests finding savings; this tests refusing an unsafe one.
- A hidden `benchmark/answer-key.md` holding the measured tier gas, the good-tier ceilings, and a per-tier technique diagnostic. Kept a directory above `fixtures/` so a blind run never sees it. Honor-system hidden for v0.

Measurement discipline: all tier gas is measured with `forge test --gas-report` under the pinned settings, and the tiers are verified to be monotonic (`bad >= medium >= good`) per axis before the numbers enter the key. The tiers are built as a cumulative opportunity ladder, so the count of tier-discriminating findings is also monotone (`bad > medium > good`) and a blind scan must surface strictly more on the lower tiers; the key records the per-tier counts. For these standards the cold `SSTORE` dominates the happy path, so the deployment axis carries the largest gradient and runtime differences are real but small; the key reports both axes.

The loop, run by hand for v0:

0. One-time setup in `benchmark/fixtures/` (the `lib/` directory is gitignored): `forge install foundry-rs/forge-std` and `forge install OpenZeppelin/openzeppelin-contracts@v5.1.0`.
1. Confirm green baseline and a working gas report (currently 94 tests passing).
2. Run the skill (producer) blind against `benchmark/fixtures/`, once per lower tier.
3. Score gas-gap closure per function and for deployment against the good-tier ceilings; check abstention on the isolated twin; log any unplanted-but-measured-real saving for a key update rather than penalizing it.
4. Commit the scored run as the blessed baseline scorecard.

Explicitly out of scope for v0: the JSON sidecar, the automated grader, the model grader, Layer 2 policy counterfactuals, Layers 3 and 4, capability/regression split, and statistical confidence intervals. All of these are long term. The v0 grader is a human reading the report next to the key.

## Long term (the full harness)

Goal: automate grading, broaden coverage, and turn the backbone into a release gate. Build order:

1. **Structured JSON sidecar.** Emit a machine-readable run artifact from the skill so scoring never parses prose. Prerequisite for all automation below.
2. **Deterministic grader.** Score findings, commits, tests, and measured deltas against a hidden manifest, with the unplanted-finding rule baked in.
3. **Narrow model grader plus Phase 5 verdict suite.** A model judge confined to semantic alignment and tradeoff-rationale soundness, calibrated against expert labels; a dedicated suite for the Phase 5 tradeoff judge.
4. **Layer 2 policy counterfactuals.** Same code under different policy profiles; discovery set held fixed, only routing moves.
5. **Layers 3 and 4.** Realistic integration fixtures (library, token, DeFi flow, upgradeable, factory) and end-to-end workflow fixtures (unsupported toolchain, failing baseline, dual toolchain, coverage gaps).
6. **Paired comparison protocol and blessed baseline.** Pinned environment, three-plus trials per case, per-case paired deltas, `pass@1` and `pass^k`, bootstrap CIs once the suite is large enough.
7. **Capability and regression suites plus maintenance.** New hard cases enter capability, graduate to regression when solved, escaped failures become permanent regression cases.

Full metric taxonomy, the v0 release gate, isolation and contamination handling, and maintenance discipline are specified in `research/final-evaluation-strategy.md`.

## Suite map (short term)

Orientation only. The measured ceilings and per-tier technique diagnostics live in `answer-key.md`. Both this file and `answer-key.md` reveal expected techniques, so neither belongs in a producer's context. A blind run is scoped to `benchmark/fixtures/`, a directory below both.

| Suite | Tiers | Graded by | Probes |
|---|---|---|---|
| ERC20 | Bad, Medium, Good, + OZ reference | gas-gap closure to good | recall (bad), precision (good), both (medium) |
| AccessControl | Bad, Medium, Good, + OZ reference | gas-gap closure to good | recall (bad), precision (good), both (medium) |
| PriceGuard (isolated) | single | abstention | restraint: must not cache across an external call |

The OZ reference is a baseline column, not a graded tier: it shows where production code lands, and it seeds a future restraint test (an optimizer run on OZ must not strip safety to chase the good number).

Next standard to add (later session): ERC721, same three-tier pattern. It is heavier to implement with a full conformance suite, so it was deferred out of this session.
