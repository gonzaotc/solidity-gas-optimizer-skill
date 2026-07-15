<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

# Final evaluation strategy: Solidity Gas Optimizer

This is the merged, authoritative design for the benchmark and eval harness that backs a version 0 release and guards the version 1 refactor. It combines two independent research passes. Where they agreed, that convergence is called out as a strong signal. Where they diverged, the reconciliation is explicit.

The benchmark must answer four questions, kept separate and never collapsed into one score: does the optimizer **find** real opportunities, does it **verify** them correctly, does it **respect** the active gas policy, and does it do so at an acceptable **cost**. Comparing Markdown reports alone is insufficient: report wording and agent behavior are non-deterministic. A trustworthy comparison needs hidden expert labels, deterministic outcome checks, a structured machine-readable run artifact, and repeated paired trials.

## The organizing fact: a built-in ground-truth oracle

Most LLM tools have no ground truth, so their evals lean on an LLM judge and spend their effort fighting self-grading bias. This system is different. It ships a **ground-truth oracle**: the compiler, the gas reporter, and the test suite. Gas savings are measured, not judged. Behavior breaks are caught by tests. This single fact reorganizes the whole design and splits the labeling effort cleanly:

- **The oracle gives precision and correctness almost for free.** A phantom saving fails to measure and is auto-rejected. A behavior-breaking transform fails tests and is reverted. Whether a claimed delta is real is an executable check, not a judgment call. The skill's own non-negotiables already enforce this.
- **The oracle is blind to recall.** It can only validate what the tool produced. It cannot see what the tool missed. False negatives are invisible to measurement, so **recall is the only axis that requires the expensive human-authored answer key.**

This ordering matches the wider consensus for coding agents: prefer deterministic outcome grading first, use a model judge only for the qualities code cannot check, and hold expert labels as the calibration standard. Anthropic and OpenAI both give this ordering; SWE-bench operationalizes it with fail-to-pass and pass-to-pass tests. The oracle is why this project can push most of its grading down to the deterministic layer that everyone recommends but few tools can reach.

## Architecture: producer, deterministic grader, narrow model grader

Three roles, and the separation is load-bearing.

1. **Producer.** The complete optimizer under evaluation. It receives a clean fixture repository and the same tools, instructions, and budget as in normal operation. It cannot access the expected findings.
2. **Deterministic grader.** Compares structured findings, commits, tests, and measured gas deltas against a hidden expert manifest. This is the primary source of truth. Everything the oracle can settle is settled here.
3. **Narrow model grader.** Handles only the subjective remainder: is reported finding X semantically the same optimization as expected finding Y, and is the tradeoff rationale sound. It never decides whether a saving is real; the oracle already did.

**The producer-grader correction (both passes agree, and it is the research headline).** The intuitive sketch is a second agent that "detects what should be found" and grades against its own detection. This is the trap. If the grader re-derives the findings, it shares the producer's blind spots, so both miss the same things, agree with each other, and neither catches the gap. The correlated error is invisible. The established finding across the eval literature is blunt: **never let the agent write its own ground truth.** LLM-written expectations reflect the current implementation, not intended behavior. So the grader scores against a **static, human-validated answer key**, and a model judge is confined to fuzzy alignment. A "detector agent" is useful only to *propose* additions to the key, always human-gated before the key changes.

## What the system under test includes

This repository is an agent-driven audit workflow, not a deterministic optimizer binary. The benchmark must exercise the whole loop, because any stage can regress:

- Toolchain and compiler-setting discovery.
- Green baseline enforcement.
- Gas baseline capture and hot-function ranking.
- Catalog-guided and uncarded discovery.
- One-transform-per-commit compilation, testing, and measurement.
- Routing into the five populations: applied, team-decision, advisory, rejected, coverage-gap.
- Independent Phase 5 tradeoff analysis under the active gas policy.
- Final report and work-branch integrity.

Card recall matters, but optimizing solely for it would train the system to recite the catalog. The benchmark must also include **uncarded** architectural opportunities and **detect-hint-matches-but-preconditions-fail** cases, so it measures discrimination rather than pattern recitation.

## Benchmark design: four layers

### Layer 1: isolated technique fixtures, with negative twins

Small fixtures, one intended opportunity each, hand-crafted so the answer-key **ceiling is known** (unlike scraped real-world code, whose ceiling is unknown and can only score precision plus "found the known ones"). Every positive fixture ships a **near-miss or already-optimal twin**, the paired structure that NIST's Juliet suite uses to stop a scanner from maximizing recall by flagging everything. Example pairs:

- A repeated storage read with no intervening external call, paired with one where caching across an external call would change behavior.
- Packable variables in an undeployed contract, paired with a deployed upgradeable contract whose layout is frozen.
- A safe bounded loop increment, paired with an increment whose bound does not prove overflow impossible.
- An unmodified `memory` parameter, paired with one that is mutated.
- A profitable custom-error conversion with ABI changes allowed, paired with an ABI-frozen policy.

Coverage across: common transform cards, advisory cards, forbidden transformations, flat or regressive candidates, untested candidates that must become coverage gaps, and uncarded opportunities. Keep interactions out of Layer 1: a single contract with ten planted inefficiencies is easy to write and hard to grade, because transforms shift each other's measured gas.

### Layer 2: policy counterfactuals (the policy on/off ablation)

Run the same code under different policy profiles. This isolates policy behavior from detection: the discovered set should be **identical**, only the routing should move. Profiles:

- Default compatibility freeze.
- Layout changes allowed vs frozen.
- ABI changes allowed vs frozen.
- Assembly allowed vs report-only.
- Different reporting thresholds.
- User-paid hot path vs rare admin path.
- Single deployment vs high deployment multiplicity.
- L1 vs an explicitly named L2 gas context.

Because the discovery set is held fixed, policy testing needs no separate fixtures, only a policy variant of Layer 1 and Layer 3 cases.

### Layer 3: realistic integration fixtures

Added once isolated cases are stable. These are integration smoke tests, not the primary recall metric:

- A reusable library where small savings and API stability matter (internal functions inline into every consumer, so code-size cost is real).
- A token or accounting contract with frequent user paths.
- A DeFi flow with storage and external-call interactions.
- An upgradeable contract with frozen layout and ABI.
- A factory or clone architecture where deployment multiplicity reorders priorities.
- A contract with architectural and local opportunities competing for attention.

Tag **domain** and **difficulty** independently. Difficulty describes the reasoning required: (1) local syntactic pattern, (2) preconditions or intra-contract dataflow, (3) inter-contract behavior or measurement setup, (4) project context and policy interpretation, (5) architectural or uncarded reasoning.

### Layer 4: end-to-end workflow fixtures

Exercise workflow invariants independently of finding quality:

- Unsupported toolchain.
- Failing baseline.
- Foundry-only, Hardhat-only, and dual-toolchain coverage.
- Divergent compiler settings between toolchains.
- Missing function coverage.
- A candidate that breaks targeted tests.
- A candidate interaction that breaks only the final full suite.
- Hardhat measurements requiring manual extraction.

## The unplanted-finding rule

This is where the oracle forces a change to the standard scoring, and it is the one place the two research passes had to be reconciled. A naive precision metric (reported-and-correct over all reported) treats any finding not in the answer key as a false positive. CASTLE does exactly this and penalizes correct-but-unlabeled findings. With a measurement oracle that is unforgivable: **if the tool reports a saving that was not planted, yet it measures real and passes tests, that is a true positive you failed to anticipate, not a false positive.** The grader must route "measured-real but not in the key" to a "valid find, flag for key update" bucket, never to a precision penalty. Bake this in or the metric punishes the tool for being better than the key, and the answer key will only ever ratchet toward the tool's current blind spots.

## Hidden gold manifest

One human-validated manifest, kept outside the agent-visible environment. Each expected finding records:

- Stable case identifier.
- Agent-visible fixture and the semantic code region (not a bare line number).
- Expected card ID or `uncarded`, plus allowed equivalent techniques.
- Required preconditions.
- Expected result population under each policy variant.
- Reference patch when a transform exists (multiple valid patches allowed when they satisfy the same mechanism and preserve behavior).
- Reference runtime, deployment, and code-size deltas, with an acceptable measurement tolerance.
- Required tests and coverage state.
- Difficulty and domain tags.
- Suite membership: capability, regression, or holdout.

Match findings on card ID plus file plus function-or-AST-level region plus semantic label. **Line-number-only matching is brittle** and breaks the moment a fixture is edited. Review the manifest like production code: a reference solution must pass every grader, proving the task is solvable and the checks are wired correctly (SWE-bench Verified had to discard 68.3% of reviewed samples for underspecified tasks and unfair tests; the manifest is where that rot would start here).

## Structured run artifact

The human report stays Markdown. Benchmark scoring consumes a **machine-readable JSON sidecar** the run emits, so scores never depend on prose formatting. It carries:

- Run, model, scaffold, skill, catalog, and policy versions.
- Compiler and EVM settings.
- Task and trial identifiers.
- Per finding: card, semantic location, report population, verdict, claimed vs measured runtime/deploy/code-size deltas.
- Tests run and outcomes.
- Commit references.
- Coverage-gap evidence.
- Wall time, token use, monetary cost, tool calls, failed tool calls.
- Harness or infrastructure errors.

This sidecar is the single biggest piece of net-new engineering the strategy asks for, and it is a prerequisite for everything downstream. Emitting it should become a skill deliverable.

## Metrics

Report by domain, difficulty, card category, and policy. Never publish only a global average.

**Finding quality.**
- Precision: correct reported findings over all reported (with the unplanted-finding rule applied).
- Recall: expected findings discovered over all expected.
- Verified recall: expected findings that survive compilation, tests, and measurement.
- **Impact-weighted recall (the headline):** recoverable reference gas captured by correctly verified findings over total recoverable reference gas. Missing a 500-gas hot-path win is not the same as missing a 5-gas one. Report plain recall alongside it: plain recall keeps small library wins from being ignored, impact weighting keeps the tool from farming many cheap micro-optimizations while missing the dominant cost.
- Uncarded recall: architectural opportunities found without catalog support.

**Policy and routing.**
- Hard-constraint violation count.
- Correct report-population rate.
- Verdict confusion across `recommend` / `team-decision` / `reject`.
- Correct report-only reclassification rate.
- Coverage-gap vs rejected classification accuracy.
- Forbidden-technique application count.

**Measurement and change integrity.**
- Runtime-delta error against reference.
- Deploy and code-size reporting accuracy.
- Tests preserved.
- One transform per commit.
- Rejected changes fully reverted.
- Compiler context recorded correctly.
- Fabricated or unmeasured saving claims (a hard-fail gate).

**Operational efficiency.**
- True verified findings per million tokens, per dollar, per hour.
- Cost and time per true finding.
- False positives per run, as a proxy for human review burden.
- Tool calls and failed tool calls.

Efficiency must never reward premature termination. Report it beside a minimum quality threshold, or as a Pareto comparison of quality against cost.

## Non-determinism: repeated paired trials

Gas measurement is deterministic. The producer's findings are not. One run cannot separate a real system change from agent variance. Run each case multiple times and distinguish:

- **`pass@1`** is the primary capability metric: the product needs a useful first audit.
- **`pass^k`** (all k attempts succeed) measures release reliability.
- Report recall as a distribution (mean and variability), and add bootstrap confidence intervals once the suite is large enough for them to mean something, as METR does for agent evals.

Use **paired trials**: baseline and candidate see the same tasks, model, scaffold, budgets, and toolchain, so the comparison is like-for-like.

## Capability and regression suites

Keep two suites. **Capability** tasks stay hard enough to expose improvements. **Regression** tasks should sit near a 100% pass rate and protect what already works. New hard cases enter capability; once consistently solved they graduate to regression; every real escaped failure becomes a permanent regression case. This avoids saturation while preserving prior gains.

## Isolation and contamination

Each trial starts from a clean environment. Copy only the agent-visible fixture into an isolated worktree or temporary repo; the gold manifest, reference patches, and grader stay outside it. Shared files, caches, branches, or git history leak prior solutions and correlate failures. Fixture names and comments must not reveal the expected technique. Public benchmarks also leak into training data over time, so keep a **public development set plus a small private or freshly mutated holdout** from the start.

## Phase 5 has its own eval suite

The tradeoff challenge is an LLM judge living inside the system, and it regresses independently: it can wrongly reject a good finding or wrongly recommend a bad-tradeoff one. Give it a direct suite of controlled reports, diffs, measurements, and policies with known-right verdicts, so a discovery failure upstream cannot mask a judgment failure here. Any model grader used in the harness gets the same discipline: grade one narrow dimension at a time, receive explicit criteria and reference evidence, return `unknown` when evidence is thin, prefer categorical decisions, randomize order in pairwise comparisons, be tested against expert labels before use, and retain disagreements for human review.

## Passing checks is necessary, not sufficient

METR found automated SWE-bench pass rates exceeded maintainer acceptance by about 24 points: patches were rejected for code quality, regressions, and core-functionality problems despite passing tests. This validates keeping Phase 5 as a distinct gate. Deterministic checks establish safety and measurement; the policy and tradeoff evaluation establishes whether a saving justifies its readability, auditability, compatibility, and security cost. Both are required before a finding is called `recommend`.

## Comparison protocol (the version-regression backbone)

For every pull request touching the skill, catalog, policy rubric, or harness, this doubles as the "compare two runs to see a PR's effect" backbone from the TODO:

1. Pin the model, scaffold, prompts, tool versions, compiler, EVM version, optimizer settings, and token and time budgets.
2. Run baseline and candidate on the same fixture and policy matrix.
3. Start each trial from a clean isolated repo.
4. At least three trials per case initially.
5. Report per-case paired deltas before aggregates.
6. Report means and variability; add bootstrap CIs when the suite supports them.
7. Preserve transcripts and grader evidence for failed or changed cases.

A higher aggregate is not automatically an improvement. Inspect whether the gain is real capability, a grader loophole, a changed cost budget, or a regression hidden by averaging. This is the safety net that lets the v1 refactor proceed: refactor freely as long as the scorecard holds or improves.

## Version 0 scope

Five entangled real contracts are too small and too hard to diagnose to be the backbone; they are integration smoke tests. A tractable first suite:

- 10 to 15 isolated positive/negative pairs (Layer 1).
- 5 to 8 policy counterfactual cases (Layer 2).
- 3 to 5 realistic mixed contracts (Layer 3).
- At least one uncarded architectural case, one coverage-gap case, and one flat-or-regressive candidate.
- At least one Layer 4 workflow fixture per invariant that can be cheaply simulated.
- Three trials per case.
- A hidden expert manifest with reference patches, plus the JSON sidecar.
- Deterministic grading plus a narrowly scoped model grader.

**Release gate for v0:**
- Zero hard-policy violations.
- Zero unmeasured findings presented as verified.
- Zero benchmark infrastructure failures.
- Green baseline and green final suite for retained changes.
- No statistically or consistently observed regression in precision or verified recall against the blessed baseline.
- Explicit review of any cost increase or new false-positive class.

Do not invent an absolute recall target before the fixtures and grader are validated; that is false precision. Set it after the first trustworthy baseline exists.

## Maintenance

Treat the benchmark as a versioned product:

- Every real escaped failure becomes a regression task.
- Saturated capability tasks move into regression coverage.
- Add harder capability and holdout tasks over time.
- Review gold labels and reference measurements whenever compiler or EVM settings change.
- Record benchmark, fixture, policy, grader, and harness versions with every result.
- Periodically sample transcripts and grades to catch grader bugs.
- Keep benchmark changes separate from optimizer changes when measuring a PR.

The benchmark tests the combined model plus agent harness, not the model alone. Results are comparable only when the model, scaffold, tools, budgets, and environment are all recorded.

## Build order

1. Emit the structured JSON sidecar from a skill run. Nothing downstream works without it.
2. Author Layer 1 fixtures with negative twins and a human-validated manifest; write reference patches and prove they pass the grader.
3. Build the deterministic grader against the oracle outputs and the manifest, with the unplanted-finding rule.
4. Add the narrow model grader for semantic alignment and the Phase 5 verdict suite, calibrated against expert labels.
5. Add Layer 2 policy variants, then Layer 3 and Layer 4.
6. Wire the paired comparison protocol and freeze a blessed baseline.

Lock the methodology before building the golden set: the human-in-the-loop labeling is the expensive step, so the fixtures wait until the approach is agreed.

## Sources

Convergent methodology (both research passes):

- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents). Tasks, trials, graders, transcripts, capability vs regression suites, deterministic coding-agent grading, repeated trials, clean environments, grader calibration.
- OpenAI, [Evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices). Representative datasets, executable graders first, expert calibration for model graders.
- OpenAI, [Introducing SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/). Human task validation, difficulty stratification, containerized execution, grader defects, contamination.
- Jimenez et al., [SWE-bench: Can Language Models Resolve Real-World GitHub Issues?](https://openreview.net/forum?id=VTF8yNQM66). Fail-to-pass and pass-to-pass executable grading.
- NIST, [Juliet 1.1 C/C++ and Java Test Suite](https://www.nist.gov/publications/juliet-11-cc-and-java-test-suite). Paired flawed and non-flawed fixtures for TP/FN/FP/TN analysis.
- METR, [Preliminary evaluation of o3 and o4-mini](https://metr.org/evaluations/openai-o3-report/). Repeated attempts, bootstrap confidence intervals.
- METR, [Many SWE-bench-Passing PRs Would Not Be Merged into Main](https://metr.org/notes/2026-03-10-many-swe-bench-passing-prs-would-not-be-merged-into-main/). Passing tests is below maintainer acceptance.
- Shi et al., [Judging the Judges: Position Bias in LLM-as-a-Judge](https://arxiv.org/abs/2406.07791). Position, verbosity, self-preference bias in model judges.
- Liu et al., [AgentBench](https://arxiv.org/abs/2308.03688). Evaluating across distinct interactive environments.
- Xia et al., [SWE-rebench](https://arxiv.org/abs/2505.20411). Continuously collected tasks, contamination tracking.

Findings-grading and domain specifics:

- [CASTLE: Benchmarking Dataset for Static Code Analyzers and LLMs toward CWE Detection](https://arxiv.org/html/2503.09433v1). Severity-folded single score, and the false-positive-on-unlabeled-findings trap this design deliberately avoids.
- [ZeroFalse: Improving Precision in Static Analysis with LLMs](https://arxiv.org/abs/2510.02534). Precision, recall, F1, and false-positive reduction framing for findings.
- [LLMs vs Static Code Analysis Tools: A Systematic Benchmark for Vulnerability Detection](https://arxiv.org/html/2508.04448v1).
- [LLM-as-a-Judge in 2026, DeepEval](https://deepeval.com/blog/llm-as-a-judge). Reference-based vs referenceless judges, never letting the agent write its own ground truth.
- [Gas-expensive patterns detection to optimize smart contracts, ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S1568494623005604). 25 categorized gas-inefficient patterns, useful as a fixture-pattern checklist, not a golden set.
- [SolEval: Benchmarking LLMs for Repository-level Solidity Code Generation](https://arxiv.org/pdf/2502.18793). Real-world Solidity benchmark construction.
