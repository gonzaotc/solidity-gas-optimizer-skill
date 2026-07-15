<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

# Final evaluation strategy: Solidity Gas Optimizer

The authoritative design for the benchmark and eval harness that backs a version 0 release and guards the version 1 refactor. It merges two independent research passes; where they diverged, the reconciliation is explicit.

The benchmark answers four questions, kept separate and never collapsed into one score: does the optimizer **find** real opportunities, does it **verify** them correctly, does it **respect** the active gas policy, and does it do so at acceptable **cost**. Comparing Markdown reports alone is not enough, because report wording and agent behavior are non-deterministic. A trustworthy comparison needs hidden expert labels, deterministic outcome checks, a machine-readable run artifact, and repeated paired trials.

## The organizing fact: a built-in ground-truth oracle

Most LLM tools have no ground truth, so their evals lean on an LLM judge and fight self-grading bias. This system ships a **ground-truth oracle**: the compiler, the gas reporter, and the test suite. Gas savings are measured, not judged; behavior breaks fail tests. This splits the labeling effort cleanly:

- **Precision and correctness come almost for free.** A phantom saving fails to measure and is auto-rejected. A behavior-breaking transform fails tests and is reverted. Whether a delta is real is an executable check. The skill's non-negotiables already enforce this.
- **The oracle is blind to recall.** It validates only what the tool produced, never what it missed. False negatives are invisible to measurement, so **recall is the only axis that requires a human-authored answer key.**

This matches the consensus for coding agents: deterministic outcome grading first, a model judge only for what code cannot check, expert labels as the calibration standard. SWE-bench operationalizes it with fail-to-pass and pass-to-pass tests. The oracle is why this project can push most grading down to the deterministic layer.

## Architecture: producer, deterministic grader, narrow model grader

1. **Producer.** The complete optimizer under evaluation, given a clean fixture repo and the normal tools, instructions, and budget. It cannot access the expected findings.
2. **Deterministic grader.** Compares structured findings, commits, tests, and measured gas deltas against a hidden manifest. Primary source of truth: everything the oracle can settle is settled here.
3. **Narrow model grader.** Handles only the subjective remainder: is reported finding X the same optimization as expected finding Y, and is the tradeoff rationale sound. It never decides whether a saving is real.

**The producer-grader correction (both passes agree, the research headline).** The intuitive sketch is a second agent that "detects what should be found" and grades against its own detection. That is the trap: a grader that re-derives findings shares the producer's blind spots, so both miss the same things and neither catches the gap. The literature is blunt: **never let the agent write its own ground truth.** The grader scores against a static, human-validated key; a model judge is confined to fuzzy alignment. A detector agent may only *propose* key additions, always human-gated.

## What the system under test includes

An agent-driven audit workflow, not a deterministic binary. Any stage can regress, so the benchmark exercises the whole loop: toolchain and compiler-setting discovery, green-baseline enforcement, gas baseline capture and hot-function ranking, catalog-guided and uncarded discovery, one-transform-per-commit compile/test/measure, routing into the five populations (applied, team-decision, advisory, rejected, coverage-gap), independent Phase 5 tradeoff analysis, and final report and branch integrity.

Card recall matters, but optimizing solely for it trains the system to recite the catalog. The benchmark also includes **uncarded** opportunities and **hint-matches-but-preconditions-fail** cases, so it measures discrimination, not recitation.

## Benchmark design: four layers

**Layer 1: isolated technique fixtures, with negative twins.** Small fixtures, one intended opportunity each, hand-crafted so the answer-key ceiling is known (scraped code has an unknown ceiling and can only score precision plus "found the known ones"). Every positive fixture ships a near-miss or already-optimal twin, the paired structure NIST's Juliet suite uses to stop a scanner from maximizing recall by flagging everything. Example pairs: a repeated storage read with no intervening call, twinned with one where caching across an external call would change behavior; packable variables in an undeployed contract, twinned with a frozen-layout upgradeable contract; a safe bounded increment, twinned with one whose bound does not prove overflow impossible. Cover common transforms, advisory cards, forbidden transforms, flat or regressive candidates, untested candidates that must become coverage gaps, and uncarded opportunities. Keep interactions out: one contract with ten planted inefficiencies is hard to grade because transforms shift each other's measured gas.

**Layer 2: policy counterfactuals (the on/off ablation).** Run the same code under different policy profiles. This isolates policy from detection: the discovered set should be identical, only the routing moves. Profiles: default freeze, layout allowed vs frozen, ABI allowed vs frozen, assembly allowed vs report-only, different thresholds, hot vs rare path, single vs high deployment multiplicity, L1 vs a named L2. Because discovery is held fixed, policy testing needs only a policy variant of existing cases, not separate fixtures.

**Layer 3: realistic integration fixtures.** Added once isolated cases are stable; these are smoke tests, not the primary recall metric. A reusable library (internal functions inline into every consumer, so code-size cost is real), a token or accounting contract with frequent user paths, a DeFi flow with storage and external-call interactions, a frozen-layout upgradeable contract, a factory or clone where deployment multiplicity reorders priorities, and a contract with architectural and local opportunities competing for attention. Tag **domain** and **difficulty** independently. Difficulty is the reasoning required: (1) local syntactic pattern, (2) preconditions or intra-contract dataflow, (3) inter-contract behavior or measurement setup, (4) project context and policy interpretation, (5) architectural or uncarded reasoning.

**Layer 4: end-to-end workflow fixtures.** Exercise workflow invariants independent of finding quality: unsupported toolchain, failing baseline, Foundry-only / Hardhat-only / dual coverage, divergent compiler settings between toolchains, missing function coverage, a candidate that breaks targeted tests, an interaction that breaks only the final full suite, and Hardhat measurements needing manual extraction.

## The unplanted-finding rule

The one place the two passes had to be reconciled. A naive precision metric (correct-reported over all-reported) treats any finding not in the key as a false positive; CASTLE does exactly this and penalizes correct-but-unlabeled findings. With a measurement oracle that is unforgivable: **a reported saving that was not planted, yet measures real and passes tests, is a true positive you failed to anticipate, not a false positive.** The grader routes "measured-real but not in the key" to a "valid find, flag for key update" bucket, never to a precision penalty. Otherwise the metric punishes the tool for beating the key, and the key only ratchets toward the tool's blind spots.

## Hidden gold manifest

One human-validated manifest, kept outside the agent-visible environment. Each expected finding records: stable case id; fixture and semantic code region (not a bare line); expected card id or `uncarded` plus allowed equivalents; required preconditions; expected result population under each policy variant; reference patch when a transform exists (multiple valid patches allowed if they share the mechanism and preserve behavior); reference runtime, deploy, and code-size deltas with a measurement tolerance; required tests and coverage state; difficulty and domain tags; suite membership (capability, regression, holdout).

Match on card id plus file plus function-or-region plus semantic label. **Line-number-only matching is brittle** and breaks on any edit. Review the manifest like production code: a reference solution must pass every grader, proving the task is solvable and the checks are wired correctly. SWE-bench Verified discarded 68.3% of reviewed samples for underspecified tasks and unfair tests; the manifest is where that rot would start here.

## Structured run artifact

The human report stays Markdown. Scoring consumes a **machine-readable JSON sidecar** the run emits, so scores never depend on prose. It carries: run/model/scaffold/skill/catalog/policy versions; compiler and EVM settings; task and trial ids; per finding the card, semantic location, population, verdict, and claimed vs measured runtime/deploy/code-size deltas; tests run and outcomes; commit references; coverage-gap evidence; wall time, tokens, cost, tool calls, failed tool calls; harness errors. This sidecar is the biggest net-new engineering the strategy asks for and a prerequisite for automated grading, so emitting it should become a skill deliverable.

## Metrics

Report by domain, difficulty, card category, and policy. Never publish only a global average.

**Finding quality.** Precision (with the unplanted-finding rule applied); recall (found over expected); verified recall (findings surviving compile, tests, measurement); **impact-weighted recall as the headline** (recoverable reference gas captured over total recoverable, because missing a 500-gas hot-path win differs from missing a 5-gas one), reported beside plain recall so small library wins are not ignored and cheap micro-optimizations are not farmed; uncarded recall.

**Policy and routing.** Hard-constraint violation count, correct report-population rate, verdict confusion across recommend/team-decision/reject, correct report-only reclassification rate, coverage-gap vs rejected accuracy, forbidden-technique application count.

**Measurement and change integrity.** Runtime-delta error against reference, deploy and code-size reporting accuracy, tests preserved, one transform per commit, rejected changes fully reverted, compiler context recorded, fabricated or unmeasured saving claims (a hard-fail gate).

**Operational efficiency.** True verified findings per million tokens, per dollar, per hour; cost and time per true finding; false positives per run; tool calls and failed tool calls. Never reward premature termination: report efficiency beside a minimum quality threshold, or as a quality-vs-cost Pareto comparison.

## Non-determinism: repeated paired trials

Gas measurement is deterministic; the producer's findings are not. One run cannot separate a real system change from agent variance. Run each case multiple times: **`pass@1`** is the primary capability metric (the product needs a useful first audit), **`pass^k`** measures release reliability. Report recall as a distribution, adding bootstrap confidence intervals once the suite is large enough to mean something, as METR does. Use **paired trials**: baseline and candidate see the same tasks, model, scaffold, budgets, and toolchain.

## Capability and regression suites

**Capability** tasks stay hard enough to expose improvements. **Regression** tasks sit near a 100% pass rate and protect what works. New hard cases enter capability, graduate to regression once consistently solved, and every real escaped failure becomes a permanent regression case. This avoids saturation while preserving gains.

## Isolation and contamination

Each trial starts clean. Copy only the agent-visible fixture into an isolated worktree; the manifest, reference patches, and grader stay outside it. Shared files, caches, branches, or git history leak prior solutions. Fixture names and comments must not reveal the expected technique. Public benchmarks leak into training data over time, so keep a public development set plus a small private or freshly mutated holdout from the start.

## Phase 5 has its own eval suite

The tradeoff challenge is an LLM judge inside the system and regresses independently: it can wrongly reject a good finding or recommend a bad-tradeoff one. Give it controlled reports, diffs, measurements, and policies with known-right verdicts, so an upstream discovery failure cannot mask a judgment failure. Any model grader gets the same discipline: one narrow dimension at a time, explicit criteria and reference evidence, return `unknown` when evidence is thin, prefer categorical decisions, randomize order in pairwise comparisons, test against expert labels before use, retain disagreements for human review.

## Passing checks is necessary, not sufficient

METR found automated SWE-bench pass rates exceeded maintainer acceptance by about 24 points: patches were rejected for code quality, regressions, and core-functionality problems despite passing tests. This validates keeping Phase 5 a distinct gate. Deterministic checks establish safety and measurement; the tradeoff evaluation establishes whether a saving justifies its readability, auditability, compatibility, and security cost. Both are required before a finding is `recommend`.

## Comparison protocol (the version-regression backbone)

For every PR touching the skill, catalog, policy rubric, or harness, this is the "compare two runs to see a PR's effect" backbone:

1. Pin model, scaffold, prompts, tool versions, compiler, EVM version, optimizer settings, and budgets.
2. Run baseline and candidate on the same fixture and policy matrix.
3. Start each trial from a clean isolated repo.
4. At least three trials per case initially.
5. Report per-case paired deltas before aggregates.
6. Report means and variability; add bootstrap CIs when the suite supports them.
7. Preserve transcripts and grader evidence for failed or changed cases.

A higher aggregate is not automatically an improvement: inspect whether the gain is real capability, a grader loophole, a changed cost budget, or a regression hidden by averaging. This is the safety net that lets the v1 refactor proceed.

## Version 0 scope

Five entangled real contracts are too small and too hard to diagnose to be the backbone; they are smoke tests. A tractable first suite: 10 to 15 isolated positive/negative pairs (Layer 1); 5 to 8 policy counterfactuals (Layer 2); 3 to 5 realistic mixed contracts (Layer 3); at least one uncarded, one coverage-gap, and one flat-or-regressive case; at least one Layer 4 fixture per cheaply simulated invariant; three trials per case; a hidden manifest with reference patches plus the JSON sidecar; deterministic grading plus a narrow model grader.

**Release gate for v0:** zero hard-policy violations; zero unmeasured findings presented as verified; zero benchmark infrastructure failures; green baseline and green final suite for retained changes; no consistent regression in precision or verified recall against the blessed baseline; explicit review of any cost increase or new false-positive class. Do not invent an absolute recall target before the fixtures and grader are validated; set it after the first trustworthy baseline exists.

## Maintenance

Treat the benchmark as a versioned product: every escaped failure becomes a regression task; saturated capability tasks move into regression; add harder capability and holdout tasks over time; review gold labels and reference measurements when compiler or EVM settings change; record benchmark, fixture, policy, grader, and harness versions with every result; periodically sample transcripts and grades to catch grader bugs; keep benchmark changes separate from optimizer changes when measuring a PR. The benchmark tests the combined model plus harness, not the model alone; results are comparable only when model, scaffold, tools, budgets, and environment are all recorded.

## Build order

1. Emit the structured JSON sidecar from a skill run. Nothing downstream automates without it.
2. Author Layer 1 fixtures with negative twins and a human-validated manifest; write reference patches and prove they pass the grader.
3. Build the deterministic grader against the oracle outputs and the manifest, with the unplanted-finding rule.
4. Add the narrow model grader for semantic alignment and the Phase 5 verdict suite, calibrated against expert labels.
5. Add Layer 2 policy variants, then Layer 3 and Layer 4.
6. Wire the paired comparison protocol and freeze a blessed baseline.

Lock the methodology before building the golden set: the human-in-the-loop labeling is the expensive step.

## Sources

Convergent methodology (both passes):

- Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents). Tasks, trials, graders, transcripts, capability vs regression, deterministic coding-agent grading, repeated trials, clean environments, grader calibration.
- OpenAI, [Evaluation best practices](https://developers.openai.com/api/docs/guides/evaluation-best-practices). Representative datasets, executable graders first, expert calibration for model graders.
- OpenAI, [Introducing SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/). Human task validation, difficulty stratification, containerized execution, grader defects, contamination.
- Jimenez et al., [SWE-bench](https://openreview.net/forum?id=VTF8yNQM66). Fail-to-pass and pass-to-pass executable grading.
- NIST, [Juliet 1.1 Test Suite](https://www.nist.gov/publications/juliet-11-cc-and-java-test-suite). Paired flawed and non-flawed fixtures for TP/FN/FP/TN analysis.
- METR, [Preliminary evaluation of o3 and o4-mini](https://metr.org/evaluations/openai-o3-report/). Repeated attempts, bootstrap confidence intervals.
- METR, [Many SWE-bench-Passing PRs Would Not Be Merged](https://metr.org/notes/2026-03-10-many-swe-bench-passing-prs-would-not-be-merged-into-main/). Passing tests is below maintainer acceptance.
- Shi et al., [Judging the Judges: Position Bias in LLM-as-a-Judge](https://arxiv.org/abs/2406.07791). Position, verbosity, self-preference bias.
- Liu et al., [AgentBench](https://arxiv.org/abs/2308.03688). Evaluating across distinct interactive environments.
- Xia et al., [SWE-rebench](https://arxiv.org/abs/2505.20411). Continuously collected tasks, contamination tracking.

Findings-grading and domain specifics:

- [CASTLE](https://arxiv.org/html/2503.09433v1). Severity-folded single score, and the false-positive-on-unlabeled-findings trap this design avoids.
- [ZeroFalse](https://arxiv.org/abs/2510.02534). Precision, recall, F1, false-positive reduction for findings.
- [LLMs vs Static Code Analysis Tools](https://arxiv.org/html/2508.04448v1).
- [LLM-as-a-Judge in 2026, DeepEval](https://deepeval.com/blog/llm-as-a-judge). Reference-based vs referenceless judges, never letting the agent write its own ground truth.
- [Gas-expensive patterns detection, ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S1568494623005604). 25 categorized gas-inefficient patterns, a fixture-pattern checklist, not a golden set.
- [SolEval](https://arxiv.org/pdf/2502.18793). Real-world Solidity benchmark construction.
