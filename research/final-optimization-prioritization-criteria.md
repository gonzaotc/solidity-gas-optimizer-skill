# How the best engineers prioritize optimization, and what it means for the gas-audit scan

Research note. Question: which criteria do strong engineers use to decide *where* to optimize a
system, and can any of them sharpen how the gas-optimizer skill prioritizes its scan? This is a
synthesis of two independent research passes (this author's and a parallel GPT pass); where they
converged or diverged is called out in the last section. Methodology research only; no skill change is
proposed here.

## The framing: optimization search ≠ security search

The two audits run different search algorithms because they extremize different quantities.

- **Security** searches for the *worst reachable state*, then compounds assumptions so several small
  weaknesses synergize into one critical finding. Payoff is combinatorial and adversarial: the tail
  dominates, one overlooked path can decide the result, and — crucially — *observed* frequency does
  not bound *attacker-chosen* frequency. NIST SP 800-30 prioritizes risk by likelihood × impact ×
  uncertainty, not impact alone, which is why security keeps likelihood and magnitude separate.
- **Optimization** mostly searches for the *largest recoverable expected cost*: `saving_per_occurrence
  × how_often_it_occurs`, summed over the system. Costs add rather than synergize, so the optimizer
  wants the few places where that product is large and can ignore everything below a noise floor.

So the one thing the two audits share is *coverage discipline* — a value/risk-ranked first pass
followed by a complete sweep — not their severity semantics. Production call counts can seed an
optimizer's frequency estimate; they can never seed a security likelihood.

**One refinement the security lens forces onto the optimizer.** Optimization is not purely
expected-value. Some gas costs are *feasibility* constraints, not averages: a loop that grows with
storage can exceed the block gas limit and stall the contract; a batch can approach its gas budget.
Those are tail/worst-case concerns that an expected-value ranking buries. So the honest optimizer
runs **two lanes**:

1. **Expected-total-cost lane** — rank by `saving/call × expected calls` (+ deploy saving × expected
   deployments). This is the bulk of the work.
2. **Tail / constraint lane** — separately surface worst-case or critical-path gas that threatens
   transaction feasibility, batch capacity, a gas budget, or a user-facing cost target. A rare path
   with a hard ceiling is not low priority.

The open question the skill must answer for lane 1 is: what estimates "how often it occurs" when the
only workload you have is a test suite?

## The theory: what performance engineering prioritizes

Ordered from most to least load-bearing for our case.

### 1. Measure first; intuition about *where* is usually wrong

Knuth, 1974: *"We should forget about small efficiencies, say about 97% of the time: premature
optimization is the root of all evil. Yet we should not pass up our opportunities in that critical
3%."* The operative half is "the critical 3%" — there *is* a small region worth all the effort, and
the whole skill is locating it by measurement, since intuition often fails. Knuth explicitly argues
for automatic feedback about which parts cost the most. The operational form is everywhere in
practice: Intel VTune's Hotspots orders functions by time and presents hot call paths as the *starting
point for algorithm analysis* (and warns some hotspots are fundamental, not removable); Gregg's CPU
Profile Method says profile, understand the entries, estimate net payoff, tune, and stop when the gain
is insufficient. The skill already refuses to run without measurement, which is the strict form.

### 2. Amdahl's Law bounds the payoff before you touch anything

Amdahl, 1967. Speedup is capped by the fraction of total cost the component carries: if a path is 5%
of cost, no fix saves more than 5%. Stated as a design maxim (Hennessy & Patterson): *make the common
case fast*. Rank candidates by the **fraction of total lifecycle cost they carry**, not by how
inefficient they look locally. Caveat: the relevant fraction is the share of the *workload/transaction
path* the candidate affects, not a single function's standalone maximum — one critical path can be
split across callees, modifiers, and libraries, so "only inspect the hottest function" is the wrong
reading.

### 3. Cost × frequency is the real metric — frequency is the multiplier we under-weight

The sharpest point, and where both research passes agreed independently. Ranking by per-call cost
alone ranks by one factor of a product. A 70k-gas admin function called once a year and a 30k-gas swap
called ten thousand times a day are orders of magnitude apart in real cost, yet a cost-only ranking
puts the admin function on top.

This is the compiler's own discipline: LLVM weights local block cost by block execution frequency;
Solidity's `--optimize-runs` is literally an estimate of how often deployed opcodes execute over the
contract's lifetime, trading deploy size against runtime cost. The lifecycle quantity is:

```
expected_total_saving = saving_per_call × expected_production_calls
                      + deploy_saving   × expected_deployments
```

Frequency weighting is not a license to invent a point estimate. If frequency is unknown, it stays
`unknown`; do not manufacture a multiplier and do not collapse unknown to zero.

### 4. Profile with a representative workload, or the profile lies (PGO)

Profile-guided optimization works only on profiles collected from production-like inputs. LLVM's PGO
guide says profiles should represent intended use (its own counterexample: x86-64 profiles are useless
when optimizing for ARM). The Linux-kernel AutoFDO docs are blunter — an unrepresentative workload
optimizes the wrong objective — and recommend sampling real production or a representative load test.
SPEC draws the line we need directly: its `test`/`train` inputs are *untimed correctness* workloads;
only the *reference* workload produces the reported performance number.

Applied here: **a Solidity test suite is a correctness workload, not a usage workload.** A gas
reporter's `# calls` column is a test-execution count — great for coverage, but it reflects how the
tests were written (an admin setup call in every test, a hot user path once), not production demand.
So test-suite frequency is at best a weak, possibly misleading proxy. The honest signals for
*production* frequency, when no policy declares one, are static and structural:

- **Visibility and access control.** Un-gated `external`/`public` ⇒ candidate hot path;
  `onlyOwner`/`onlyRole`/`onlyGovernance` ⇒ almost always cold (admin, infrequent).
- **Position in the documented core flow.** The primary user action (transfer, swap, deposit,
  consume) the README/NatSpec presents, versus configuration / rescue / migration.
- **Naming and shape.** `set*`/`configure*`/`rescue*`/`sweep*`/`initialize` skew cold; the verbs a
  user repeats skew hot.

None of these is measurement, so they inform *scan order and weighting*, never the reported number.

### 5. The biggest wins are algorithmic/architectural; a card sweep is blind to them

The literature is unanimous that changing the algorithm or data structure dominates micro-tuning it
(Agner Fog: find the best algorithm before touching assembly; optimizing a poor algorithm is wasted
effort. VTune frames hotspots as the entry to *algorithm analysis*). Our scan is catalog-card
matching, which is structurally a *micro*-optimization instrument: it recognizes local patterns
(packing, caching a SLOAD, `unchecked`, error strings → custom errors) and cannot, by construction,
propose "this accounting scheme should be a different data structure" or "this per-call storage growth
should be an off-chain index with an on-chain checkpoint." The example that started this discussion — a
`Checkpoints.push` onto a new slot dominating a hot path — is an architectural cost, not a card. This
is a **structural limit of the search**, worth stating in the report so a clean audit is not misread
as "cost-optimal."

### 6. Find the bottleneck resource; storage is it (systems methodology + EIP-2929)

Gregg's USE method (per resource: Utilization, Saturation, Errors), the RED method for services, and
the Roofline model all enforce the same discipline: find the one dominant bottleneck and attack it
rather than shaving inefficiencies evenly. USE is explicitly a *complete checklist* meant to avoid
overlooked areas while still finding the bottleneck fast — which is exactly the "hot-first then full
sweep" shape. The gas analogue of "the dominant resource" is storage: EIP-2929 charges a cold slot
2,100 gas and a warm read 100, and cold account access 2,600 — storage access dwarfs arithmetic and
memory. So a function that touches a *new (cold)* slot is where cost concentrates almost by
definition; ranking by storage-touching behavior is a cheap structural prior, complementary to the
measured number.

### 7. Which statistic, and the two layers of uncertainty

A gas reporter gives min / mean / median / max / calls — descriptive stats for the *test* scenarios,
not production. Two consequences:

- **`max` is a scenario fact, not a workload weight.** A cold-access maximum (EIP-2929 first-touch)
  must not be read as expected per-call cost; sorting by `max` systematically elevates rare and
  setup-heavy scenarios. Keep `max`/worst-case in the tail lane, name the scenario, and use a declared
  representative-scenario cost for the expected-value lane. (This is precisely why a "hot ranking by
  max = cold-slot cost" is a worst-case ordering, not an expected-cost ordering.)
- **Uncertainty has two independent layers.** *Technical repeatability* (same scenario + toolchain ⇒
  same delta; fix compiler version, EVM version, reporter config) is different from *workload
  representativeness* (does the scenario resemble production state/inputs/frequency?). A perfectly
  repeatable delta can still have unknown lifecycle value. And a project's reporting floor (e.g. "10
  gas") is a *worth* threshold, not a *measurement-noise* threshold unless run-to-run variation was
  actually measured — keep the two separate.

## Where the skill stands today

Already sound (it encodes 1, 2, 6 implicitly):
- Refuses to run without measurement. — `SKILL.md:19`
- Ranks in-scope functions by measured cost, scans hottest-first because "gas lives in a few hot
  functions," and keeps a mandatory full sweep afterward as the guardrail against profile blind spots.
  — `SKILL.md:74`, `SKILL.md:80`
- Allows uncarded (algorithmic/architectural) candidates. — `SKILL.md:81`
- Separates "not measured" (coverage gap) from "measured and rejected." — `SKILL.md:84`
- Orders Phase-3 candidates by expected value: hot/per-call before deploy-only/cold. — `SKILL.md:85`
- Tradeoffs rubric weights "who pays and how often." — `solidity-gas-tradeoffs-analysis/SKILL.md:26`
- The policy schema already has a home for this: "the functions that run most often" and "who pays and
  how often" under Context weighting. — `templates/gas-policy.md:29`

Gaps, in priority order:

1. **Frequency is the wrong distribution.** The ranking key is measured cost; frequency enters only
   "where the reporter shows it," and what the reporter shows is *test-suite* frequency (§4). There is
   no fallback signal for production frequency, and no label separating "observed test calls" from
   "expected production frequency."
2. **The ranking statistic is undefined.** `SKILL.md:74` says "measured cost" without saying min/mean/
   median/max. `max` overweights rare/cold/setup scenarios (§7) — this is exactly the worst-case bias
   in a "rank by max = cold-slot" ordering.
3. **No structural business-logic prior.** Nothing tells the scan to treat un-gated `external` core
   actions as hotter than `onlyOwner` config, independent of test call counts. The intuition — "read
   the business logic to find the most-used functions" — has no encoded hook beyond free-text policy.
4. **Architecture is permitted but not searched.** Uncarded candidates are allowed "if you see them"
   (`SKILL.md:81`), which is passive; a hot-function catalog walk biases toward local transforms. The
   micro-vs-architectural limit is also unstated in the report (§5).
5. **"Unmeasurable hot code" is epistemically backwards.** `SKILL.md:84` calls uncovered code "hot";
   absence from a test report establishes lack of *exercise*, not production *hotness*. An untested
   path may be hot, cold, dead, or privileged. Call it an "unmeasurable candidate."
6. **"Factory/clone" is too coarse a deploy signal.** ERC-1167 clones deploy minimal proxy bytecode
   per instance and delegate to one implementation: shrinking the implementation is paid once,
   shrinking the proxy is paid per clone. The signal that matters is
   `expected_deployments_of_this_bytecode`, not a boolean "uses a factory."

## Recommendations (for discussion; nothing applied here)

Ranked by leverage. The guiding constraint: add *weighting and ordering*, not a bureaucratic scoring
system — a universal scalar score would hide policy choices behind arbitrary coefficients, and the
decision matrix should stay qualitative.

1. **Rank lane 1 by `cost × frequency`, and define frequency's fallback.** Frequency comes, in order:
   (a) the gas policy's hot-paths / who-pays-how-often; (b) a structural heuristic when the policy is
   silent — un-gated `external`/`public` named as a core user action ⇒ hot; access-gated or
   config/rescue/migration-shaped ⇒ cold; (c) test-suite counts only as a labeled weak tiebreaker.
   Unknown stays unknown: put unknown-frequency candidates in their own bucket ordered by per-call
   impact and breadth, and ask for workload evidence in the report — never collapse them to the bottom.
2. **Add lane 2, the tail/constraint check.** Separately flag worst-case gas that threatens
   feasibility: storage-dependent loops near the block gas limit, batches near a gas budget, or a
   policy-declared user cost target. Rank these by distance to the constraint, and this is where
   `max`/worst-case measurements belong (named to their scenario).
3. **Add a one-line business-logic read to Phase 1.** Before ranking, skim README/NatSpec to tag each
   in-scope function core-user / admin / rare, and fold that tag into the frequency factor. Cheap, and
   it operationalizes the original intuition.
4. **Make the scan three passes.** (A) a short whole-scope structural pass — loops/asymptotics,
   repeated storage or external calls across a path, data layout, batching, deployment topology —
   *before* local card matching, so architecture can outrank micro-optimizations; (B) the profile-led
   local catalog walk, tail-critical then high-expected-cost then unknown-high-per-call then cold;
   (C) keep the mandatory full INDEX sweep exactly as today. This preserves the guardrail and stops the
   catalog from finding cents while stepping over dollars.
5. **State the structural limit in the report.** One sentence: this audit matches local techniques and
   does not evaluate algorithmic/architectural redesigns; a clean result means no *carded* win remains,
   not that the design is cost-optimal. Add an "architectural observations" note when a hot cost is
   obviously structural.
6. **Lean on the storage prior for the first walk.** Functions that write/read storage, especially new
   (cold) slots, rank first structurally even before the measured number — it is where EVM cost
   concentrates and it is a free signal.
7. **Small wording fixes that cost nothing.** Relabel the reporter's `# calls` as observed test calls,
   not frequency; say "unmeasurable candidate," not "unmeasurable hot code"; replace "factory/clone
   targets" with expected deployment multiplicity of the specific bytecode; and separate the reporting
   floor (worth) from measurement noise (repeatability) in the tradeoffs skill.

The through-line: the skill already believes "gas lives in a few hot functions." These sharpen *how it
decides which functions are hot* — by cost weighted by real usage and by what the code is for, plus a
separate feasibility lane — instead of by measured (often worst-case) cost alone or by whatever the
test suite happened to call.

## Convergence and divergence with the parallel research

**Independent agreement (strong signal these are real):** both passes landed on frequency as the
missing multiplier; on the test-suite-vs-production distinction as the crux (PGO/AutoFDO/SPEC); on the
card sweep being structurally micro-biased and blind to architecture; on keeping the full sweep; and
on connecting all of it to the policy's existing Context-weighting hook.

**What the parallel pass added, and this note absorbed:** the explicit two-lane split (expected value
vs tail/feasibility, grounded in Solidity's own gas-limit-and-loops warning); the three-pass scan; the
statistic problem (`max` = a cold-access scenario fact, not a workload weight — the direct explanation
of the "rank by max = cold-slot" ordering); the two layers of measurement uncertainty; deployment
*multiplicity* over the factory/clone boolean (ERC-1167); and the epistemic fix to "unmeasurable hot
code."

**Where to push back:** the parallel pass proposes a fairly heavy apparatus — per-function YAML
workload schemas, two formal rankings, a lexicographic candidate order, pseudocode. That risks turning
a lightweight audit skill into a bureaucratic scoring pipeline, and its own best advice ("keep the
matrix qualitative; a universal scalar hides policy behind coefficients") argues against most of it.
The recommendation here is to take the *ideas* (two lanes, three passes, frequency fallback, honest
labels) as prose guidance and the policy's free-text Context-weighting section, not as a new required
schema. Adopt the reasoning, not the ceremony.

## Sources

Web-verified this session:
- Knuth, D. (1974). *Structured Programming with go to Statements.* ACM Computing Surveys 6(4). The
  97%/3% passage.
- Amdahl, G. (1967). *Validity of the single processor approach to achieving large scale computing
  capabilities.* AFIPS Spring Joint Computer Conference, pp. 483–485.

Carried from the parallel research pass; canonical and consistent with this author's knowledge, but
not independently re-fetched this session:
- Hennessy & Patterson, *Computer Architecture: A Quantitative Approach* — "make the common case fast."
- LLVM PGO guide and Block Frequency Terminology; Linux kernel AutoFDO docs; Chen et al., *AutoFDO*
  (CGO 2016) — profiles must represent intended workloads.
- SPEC CPU methodology — untimed `test`/`train` correctness workloads vs the timed reference workload.
- Intel VTune Hotspots (hotspots as the entry to algorithm analysis) and the Intel Optimization
  Reference Manual (latency vs throughput).
- Brendan Gregg — Performance Analysis Methodology, the CPU Profile Method, and the USE method.
- Agner Fog, *Optimizing Software in C++* — best algorithm before assembly.
- Dean & Barroso (2013), *The Tail at Scale*, CACM — tails dominate at fan-out (imported only as a
  narrow analogy for composed calls/loops, not mechanically).
- Google SRE, *Monitoring Distributed Systems* — latency vs traffic as distinct signals.
- Google Benchmark docs — noise, repeated runs, statistical comparison.
- EIP-2929 (cold 2,100 / warm 100 / cold account 2,600); Ethereum Yellow Paper (code-deposit cost);
  ERC-1167 (minimal proxy); Solidity docs on the optimizer, cold-cost gas estimation, and
  gas-limit-and-loops; Foundry and hardhat-gas-reporter gas-report columns.
- NIST SP 800-30 Rev.1 — risk = likelihood × impact × uncertainty.
