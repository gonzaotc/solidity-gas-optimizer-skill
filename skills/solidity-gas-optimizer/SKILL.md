---
name: solidity-gas-optimizer
description: Run a measured gas-optimization audit on Solidity code. Use when asked to gas-optimize contracts or run a gas audit, reduce deployment or creation gas, profile gas usage, or re-run or extend an existing gas audit. To persist a technique into the catalog for reuse, use solidity-gas-reference-creator instead.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Agent
argument-hint: "[files or directories to audit; defaults to the main contracts directory]"
---

# Solidity Gas Optimizer

Produce an audit-style gas report for a Solidity codebase. Every claimed saving is measured with the project's own toolchain and checked against its tests, then challenged by a separate-context tradeoff analysis (a different model or provider where one is available, a labeled self-review otherwise). Idiomatic Solidity is the default: an optimization must pay for its complexity or it is rejected. A candidate no test exercises cannot be measured, so it is surfaced as a coverage gap; the audit thus also flags where the codebase is under-tested.

Paths below are relative to this skill's directory. This skill audits an existing project; it does not scaffold one.

**Prerequisites.** A Foundry or Hardhat project with a working gas reporter, a green test suite exercising the target, and the sibling skill `../solidity-gas-tradeoffs-analysis` (Phase 6 and the default policy). If one is missing, stop and say so rather than estimate.

## Non-negotiables

1. Report only gas numbers you measured and verified; label every advisory estimate as an estimate.
2. A transform finding requires a measurement: never estimate one. A supported toolchain with a working gas reporter is a prerequisite; if it is missing, stop (Phase 0).
3. Stop on a failing baseline: if the suite fails before you change anything, report that instead.
4. One transform per commit. Gas attribution and human cherry-picking both depend on it.
5. Findings are valid only for the compiler settings they were measured under, recorded in `meta.json`.
6. Conserve every optimization candidate: each ends in exactly one classification, never quietly discarded. A negative result counts: a flat, regression, or below-threshold measurement is a classification, reported with its number.
7. Keep discovery and measurement separate: no candidate is edited into code, run against a test, or given a measured gas number before the Phase 4 verify loop. Until then it carries only an estimated magnitude, never a real number.
8. Never replace an artifact with a summary; each stays intact so the pipeline can be debugged. The report is a curated view built from the artifacts, not a substitute for them.

## Artifacts

The run is a pipeline of files under one run directory, not state held in context: each phase reads named artifacts and writes others, and a phase is done only when its artifacts exist on disk. Each phase below opens with a **Requires / Produces / Done when** line naming its edges, and each artifact's structure and meaning is its template in `templates/artifacts/`. The layout:

```
gas-reports/<target>-<date>/
  report.md                 # deliverable
  meta.json                 # run manifest
  artifacts/
    01-baseline/     # gas-report.txt, gas.snapshot, sizes
    02-inventory.md
    03-candidates.md # candidates -> states -> classifications
    04-measurements/ # per-candidate compare output and diff
    05-verdicts.md   # tradeoff challenge output, verbatim
```

Keep the run directory untracked in the audited repo: add `gas-reports/` to its `.git/info/exclude`, or tell the user it must stay uncommitted.

Three trust levels, one hard rule: **machine** artifacts (`01-baseline/`, `04-measurements/`) are written only by scripts, and the model reads them but never rewrites or summarizes them, since they are the run's only ground truth. **Judgment** artifacts (the inventory, candidates), **Verdict** artifacts (the challenge output, the report) are model-written and schema-constrained by their templates. The whole `artifacts/` folder optionally ships with the report so the process is auditable end to end.

## Intake

Print the banner and tagline below as the very first output of the run, before any tool call: nothing ahead of it. Step 2 needs the repo enumerated, but that happens after the banner is on screen. Then gather our required answers in one exchange: skip any question whose answer was already explicitly discussed and prompt for confirmation rather than re-ask in that case; if the user said to just go, take the defaults and proceed. Do not start Phase 0 until scope is settled.

Print exactly (before anything else):

```
  _____           ____       __  _       _            
 / ___/__ ____   / __ \___  / /_(_)_ _  (_)__ ___ ____
/ (_ / _ `(_-<  / /_/ / _ \/ __/ /  ' \/ /_ // -_) __/
\___/\_,_/___/  \____/ .__/\__/_/_/_/_/_//__/\__/_/   
                    /_/                                  
```

Then print exactly this line, nothing more:

```
Automated ai-assisted solidity gas optimizer.
```

Then ask all of the following in a single message so the user answers in one round:

1. **Target.** What to audit: a repo URL, a local folder, or a single file. Clone a URL locally before Phase 0.
2. **Scope.** Token usage grows with scope, so never audit a whole repo blindly. Distinguish explicit from unfocused scope:
   - **Named files:** confirm that exact set.
   - **A thematic named scope** ("every multisig module", "all the vesting contracts"): already scoped by the user. Honor it in full: enumerate every matching module, list them, and confirm the complete set; do not narrow it to the largest one or two. If cost forces batching, run serial batches but keep the whole matched set as the declared scope and name what is deferred. Never drop members or shrink scope to where a finding landed.
   - **No target, or a whole repo or bare directory:** unfocused. Warn about the potential costs and inefficiency, enumerate the candidate contracts, propose a scoped subset to run first (a few contracts, favoring the largest or most call-heavy surface), and ask the user to confirm or adjust. The "few contracts at a time" bias applies here only.
3. **Gas policy.** Ask whether they have a particular gas policy. A policy encodes the project's constraints (layout freeze, assembly style, hot paths, noise floor) and sharpens every verdict, so recommend it, though it is optional. One the target ships (`.claude/gas-policy.md` or a root `gas-policy.md`) is picked up automatically in Phase 0.
4. **Report location.** Ask for a preferred output location; it can override the Phase 5 default (a `gas-reports/` directory in the audited repo, plus an archive copy in this skill's folder).

## Phase 0: Discover

_Requires: — · Produces: `meta.json` · Done when: the scope tree is confirmed with the user and written to `meta.json` alongside the toolchain and policy._

1. Run `scripts/detect-toolchain.sh <repo-root>`. It reports the framework, test and measurement commands, and compiler settings, and exits nonzero when the repo cannot be measured (unsupported toolchain, missing `forge`, or Hardhat without `hardhat-gas-reporter`). A nonzero exit means the prerequisites are unmet: stop and report what is missing.
2. Choose the measurement tool per target, not per repo: pass the target to `detect-toolchain.sh` as its second argument so it sets `MEASURE_WITH` from the target's actual coverage, since a repo-wide preference mismeasures a target its own toolchain does not cover. For Hardhat, prefer the gas command the detector reports as `HARDHAT_GAS_CMD`: a project-declared script (`test:gas` and similar) or, on Hardhat 3, the native `--gas-stats` flag. The legacy `hardhat-gas-reporter` plugin, toggled by an env var (`REPORT_GAS`, a `GAS` yargs option, or a config flag), is one path among several, not the only one; do not assume it or its env var name. When the detector reports no gas command, read `package.json` scripts yourself before concluding the prerequisite is unmet, since teams wire their real measurement command there. When both toolchains are present, measure under the solc settings of whichever covers the target, record them, and warn if the other's settings (version, optimizer runs, via-IR) diverge.
3. Resolve the gas policy, first match wins: (1) a policy the user named when invoking the skill; (2) the target repo's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo root; (3) the shipped defaults, which are the decision matrix in `../solidity-gas-tradeoffs-analysis/SKILL.md`, not a loadable file. For options (1)–(2), `templates/gas-policy.md` is the blank schema to fill. Also read the target's `package.json` scripts, CLAUDE.md, README.md, TESTING.md, and GUIDELINES/CONTRIBUTING for constraints and context where the team may have disclosed about their gas optimizations and measurement preferences. The `package.json` scripts are the primary record of how the team runs and measures the project; read them before assuming a command does not exist. Apply the policy's hard constraints and report-only reclassifications (a storage-layout freeze makes packing report-only; an assembly-averse style makes ASM cards report-only), and carry its context weighting and noise threshold into Phase 6.
4. Fix scope: the files the user named, the full set matching a thematic scope (Intake step 2), or otherwise the contracts directory from config (Foundry `src` via `forge config`; Hardhat `paths.sources`). For a thematic scope, resolve the complete member set by grep (name pattern, shared base, imports); a match the user would expect but you skipped is a scope miss, not a saving. When several source roots exist, or none is configured, ask rather than guess.
5. Confirm the scope with the user before the next step. Render the resolved set as an indented file tree, the way an IDE shows folders and their files: collapse a folder to its name only when every file under it is in scope, and list a partially included folder's in-scope files individually so inclusions and exclusions are unambiguous (seven of eight files means list the seven, not the folder). A vague intent like "the multisig modules" resolves here to an exact list, and the user signs off on that list, not the phrasing. Do not start Phase 1 until the user confirms this tree. The confirmed tree is the scope of record and goes verbatim into the report and any PR, no exceptions.
6. Write `meta.json` (`templates/artifacts/meta-artifact.md`): framework, measure-with, solc settings, resolved policy path, the confirmed scope as an exact file list, base commit, and date. Every later phase reads its in-scope set from `meta.json` (`scope`), never from context.

## Phase 1: Baseline

_Requires: `meta.json` · Produces: `01-baseline/` · Done when: `gas-baseline.sh` exits 0 and the snapshot exists._

Baseline measures the current state and nothing else: it produces the machine artifact Phase 2 reads.

1. Run the test suite once; if it fails, stop and report. When the scope is specific contracts nothing else in the repo imports (verify with a grep), narrow the baseline and validation to the target's test files plus a full compile, and record that narrowing. The grep is a heuristic that misses interface-only calls, address casts, and re-exports, so fall back to the full suite when in doubt. In large repos a full-suite run per candidate is prohibitive, and a scoped, recorded validation beats a skipped one.
2. Run `scripts/gas-baseline.sh <framework> <baseline-dir> <repo-root>` with the baseline dir set to the run's `artifacts/01-baseline/`. For Hardhat, pass the detected `HARDHAT_GAS_CMD` via `GAS_CMD` (e.g. `GAS_CMD='npm run test:gas'`). Only when no gas command was detected and the plugin path applies, fall back to `GAS_ENV` for a non-default reporter toggle (e.g. `GAS_ENV=GAS`). If the baseline command fails, stop: without a baseline there is nothing to measure against. This writes the per-function report (`gas-report.txt` for Foundry, the reporter table for Hardhat) and `gas.snapshot`; those files, not memory, are what Phase 2 reads and Phase 4 measures against. The per-function report doubles as the coverage signal: a function it lists was exercised by a test.

## Phase 2: Inventory

_Requires: `01-baseline/` · Produces: `02-inventory.md` · Done when: every in-scope function is enumerated to its resource sites, each row's coverage is set from the baseline, and no cell carries candidate language._

Build the resource inventory, the written work list the scan consumes: written to disk before the scan and read back from there, never carried forward in context, since an unwritten row is one the scan can silently skip.

Enumerate **every** in-scope function (the `scope` list in `meta.json`), one row per resource site (a specific SLOAD, call, or loop); a function with no notable site still gets one row so it is accounted for. Completeness is the point; analysis depth is what tapers later, not enumeration. Set each row's `coverage` from the baseline gas report, a heuristic first signal: a function it lists is `exercised`; a public or external function absent from it is `none` (its selector was never called). An internal function has no own report line, so mark it `exercised` when an exercised caller reaches it, never a hard `none`. Coverage steers Phase 3 routing (a confidently uncovered site becomes a coverage-gap candidate rather than a measured one), but Phase 4 measurement is the authoritative check: a candidate that measures zero because no test drives it is reclassified to coverage-gap there. Fill `templates/artifacts/02-inventory-artifact.md`.

Enumeration only: record raw facts, never a judgment about waste or a fix. A slot read is a `storage-read` row, not a "cache this" candidate; a value fixed at deployment but derived at runtime is a `storage-read` row whose multiplicity flags repeated reads, not an "`immutable` candidate" (that choice is discovery, Phase 3). The inventory is the completeness obligation Phase 3 answers to: every row must be examined and closed (a candidate, or a recorded reason it raised none), while `candidate IDs` may stay empty.

## Phase 3: Scan

_Requires: `02-inventory.md`, `catalog/INDEX.md`, `references/gas-mindset.md` · Produces: `03-candidates.md`, updates `02-inventory.md` · Done when: every inventory row is examined (catalog match at minimum) and closed with a candidate or a recorded reason it raised none, every candidate carries a state, and dedup is applied._

The scan walks the Phase 2 inventory row by row, guided by two references (both read in full now):

- `catalog/INDEX.md` lists every technique: ID, kind, detect hint. Open a category file (`catalog/storage.md` etc.) when its hints match the code under review. This is the pattern layer: WHAT to look for.
- `references/gas-mindset.md` is the cost-accounting method for waste no card covers: trace where every gas unit goes on the hot path and ask whether that cost needs to exist there. This is the reasoning layer: HOW to find the uncarded.

Never scan from memory alone; walk both. A candidate's **kind** is `transform` (enters the verify loop, then the Phase 6 challenge) or `advisory` (reported as a labeled estimate, never applied by the run); every applied change gets a Phase 6 verdict and merges only by human decision. (Full card schema: `../solidity-gas-reference-creator/references/card-spec.md`. To add or regenerate cards, use the `solidity-gas-reference-creator` skill; this skill is read-only over the catalog.)

Candidates raised here are **conserved**: each ends in exactly one classification, none dropped. The record is the candidates list (`03-candidates.md`), one row per candidate, that Phase 4 advances with a `state` and Phases 5 and 6 finalize with a `classification`. The six classifications: `kept` and `team-decision` (measured survivors, the report's findings), `advisory` (estimated, never applied), `coverage-gap` (no test exercises it, never measurable), `rejected` (measured and did not earn a keep, or dropped downstream, with a recorded reason), and `duplicate` (merged at dedup). Each maps to a report population, defined in `templates/report.md`. Discovery raises candidates and validation measures them; the two are firewalled (non-negotiable 7).

The inventory is the scan's work list: examine every row, recording the passes applied in `completed passes`, and close each with a candidate or a one-line reason it raised none. A catalog match is the floor on every row; the two mindset passes run where the row's facts warrant. A row left unexamined is a **scan omission**, not a silent skip: reconcile it before leaving Phase 3. A scan omission (the scanner never looked at the row) is distinct from a coverage gap (no test exercises the code):

1. **Examine every row; depth follows the row's facts.** A catalog match runs on every row. Run the two mindset passes when the row's resource facts warrant the cost: multiplicity above one (a loop, a per-call charge), an expensive class (SSTORE, external call, a storage read inside a loop), or a paired path worth diffing. A cheap row (a single warm read, a one-off with no reuse) closes after the catalog match with a one-line reason it raised no candidate, not a forced full trace. This taper is driven by the row's own resource facts, never by how often the test suite happens to call it. Mark the passes applied in `completed passes`:
   - **Catalog match.** When a Detect hint matches or sounds slightly relevant, open the category file and check the card's full Preconditions before recording a candidate.
   - **Resource-flow pass** (`references/gas-mindset.md`, Pass A). Ask of each row "does this cost need to exist here?" Record every site paid more often, colder, wider, or earlier than the semantics require.
   - **Lifecycle pass** (Pass B). Diff paired paths (view/write, deposit/withdraw, happy/revert, first/subsequent, constructor/runtime, one-call/many-call) and account for the delta; record avoidable work on the heavier side.
2. The catalog is the minimum scan set, not a ceiling, and may be incomplete. A candidate the mindset passes surface with no matching card is recorded as `uncarded`; it earns a finding only by passing the same Phase 4 verify loop and Phase 6 challenge as any card. Follow the mindset file's greedy-finder discipline: record the candidate, do not self-censor, and give `estimated impact` as a rough magnitude class, never a precise gas figure. Never claim a saving from memory without measuring it. Flag survivors for a follow-up card via the reference-creator skill.
3. Record each candidate as a row in `03-candidates.md` (`templates/artifacts/03-candidates-artifact.md`), `state` = `candidate`. The `(location, expensive resource, redundant operation, semantic constraint)` tuple is the dedup key: `expensive resource` is the resource class being wasted (SLOAD, SSTORE, CALL, memory copy, ...), `redundant operation` is what the fix removes (a repeated read, a re-decode, a re-hash), `semantic constraint` is what the fix must preserve (same result, events, reverts, layout). Write each candidate's id into the `candidate IDs` column of the inventory row that raised it, so every candidate traces to a site and every site shows what it produced.
4. **Dedup by mechanism.** Once the full candidate set is recorded, dedup before any routing or ordering below. Two candidates that share the dedup tuple *and* propose the same transform merge into one (record the merged-away IDs, classify the absorbed ones `duplicate`), so the same transform is never measured, reported, or counted twice. Candidates that share the tuple but propose *different* transforms are competing fixes, not duplicates: keep each as its own candidate in a shared `competes-with` group (Phase 4 measures each from an identical baseline, Phase 6 picks the winner), which keeps the funnel arithmetic honest.
5. Advisory candidates (including any the policy reclassified to report-only) skip Phase 4 and go straight to the report.
6. A transform candidate whose target has `coverage: none` cannot be measured. Do not push it through Phase 4 and do not drop it: route it to the coverage-gap section (Phase 5) with its labeled estimate and the specific tests that would make it measurable. This is the audit's coverage-probe value: unmeasurable hot code is under-tested code, and the report says so.
7. Order the remaining (`exercised`) transform candidates for Phase 4 by expected value: per-call savings on frequently-called paths before deploy-only or rarely-called ones.

## Phase 4: Verify loop

_Requires: `03-candidates.md`, `01-baseline/` · Produces: updates `03-candidates.md`, `04-measurements/` · Done when: every exercised transform carries a measured delta and a classification, and the full suite is green._

Work on a dedicated branch (`gas/<scope>`). This is the first phase allowed to edit code or attach a gas number (non-negotiable 7): each candidate advances from `candidate` to `measured result` here. Record each candidate's measured delta and classification in `03-candidates.md`, and write each `gas-compare.sh` output and diff to `04-measurements/`. For each transform candidate, strictly one at a time:

1. Apply the minimal diff for this one card.
2. Compile. A compile failure means the diff is malformed for this codebase: retry once, then revert and record `rejected (compile failure)`. Then run targeted tests: files matching the contract name, plus any that import or deploy it (grep the test directory). Failing tests mean a bad application or a real behavior change: retry once, then revert and record `rejected (broke targeted tests)`. If the passing tests cover only part of the lines the diff touches, record that rather than call the transform fully verified.
3. Measure with `scripts/gas-compare.sh <framework> <baseline-dir> <repo-root>` against `01-baseline/`. Record the deployment/code-size delta alongside the runtime delta: bigger code is a real cost, and for internal-function libraries it lands in every consumer. The Foundry snapshot diff is deterministic; the Hardhat reporter output is not line-deterministic, so for Hardhat read the diff and extract each function's before/after by hand, and label such a finding manually extracted. When both toolchains cover the target, prefer the Foundry measurement.
4. If the improvement is above the policy's noise threshold (default: 10 gas per call unless the policy sets otherwise; a heuristic, not a measured bound), run the project's formatter and linter on the touched file, then commit as `gas: <CARD-ID> <file>: <summary> (<delta>)`. If the project defines no formatter or linter, run `forge fmt` on the touched file and skip linting. Every measured outcome gets a classification; none is dropped:
   - A regression: revert and record `rejected (regression)`.
   - A positive delta below the noise threshold: revert and record `rejected (below noise floor)` with the measured number, so a real but trivial saving is accounted for.
   - A genuine flat result (moves zero on a path a test does drive): revert and record `rejected (flat)`.
   - Exactly zero because no test drives the touched path: not a measured no-gain but a coverage gap; do not record it as rejected, reclassify it to the coverage-gap section with the tests it needs.
   - Competing transforms for the same waste (a `competes-with` group) touch the same location and cannot be stacked. Measure each option from an identical baseline: reset the working tree to the group's shared parent between options, never applying one on top of another. Record every option's number. Do not choose here: provisionally commit the largest-saving option, leave the others uncommitted with their recorded deltas, and hand the group to Phase 6, which picks the winner on tradeoff grounds. A sibling that measures flat or regresses is rejected normally; only saving siblings compete.
   If a pre-commit hook fails for reasons unrelated to the change, record the hook's full failure output and the specific reason it is unrelated, then commit with `--no-verify`; when in doubt whether the failure is related, fail loudly and stop rather than bypass.
5. Every surviving change stays on the branch for explicit review; never present a survivor as settled. The merge decision is the team's for every finding.

After the last candidate, run the **full** suite (the integration transition). If it fails, bisect the kept commits to find the offending interaction, drop that commit as `rejected (integration)` (it passed alone but broke the suite in combination), and re-run. Repeat attribution, removal, and re-validation until the suite is green: one removal does not guarantee it, since several kept commits may interact. Keep the loop serial: interleaved candidates corrupt gas attribution.

## Phase 5: Draft report

_Requires: `03-candidates.md` · Produces: `report.md` (draft) · Done when: the funnel, built from the candidates, is in the draft and the draft is written to the run directory._

Build the **discovery funnel** from `03-candidates.md` through the integration transition and put it in the draft (template section: Discovery funnel). It is per-transition, not one final tally; the exits at each transition are enumerated in the report's Discovery funnel table (`templates/report.md`). Leave the final `challenge → report` transition blank: it is pending until Phase 6. This is a draft: the funnel is not yet reconciled and no verdict is final until Phase 6 closes it.

Fill `templates/report.md` as `report.md` in the run directory; the template defines every section and population (findings, advisory, coverage-gap, rejected) and their rules, including that coverage-gap is its own population and never merged into rejected. The run directory is the location the user named in Phase 0, else a `gas-reports/<target>-<date>/` inside the audited repo. Also copy the finished run directory into a `gas-reports/` inside this skill's own folder as a cross-run archive; that copy is best-effort, so when the skill's folder is not writable, skip it and warn instead of failing. Hand the user the run directory path explicitly at the end, never leave it only in scratch space.

Severity (impact axis):

- **High**: ≥500 gas per call on a hot user path, ≥5% of a function's cost, or ≥10k deploy gas on factory/clone-deployed contracts.
- **Medium**: 100–500 gas per call on regular paths.
- **Low**: <100 gas per call, admin or rare paths, deploy-only savings on one-off deployments.

## Phase 6: Tradeoff challenge

_Requires: `report.md`, `03-candidates.md`, the kept diffs · Produces: `05-verdicts.md`, final `report.md`, updates `03-candidates.md` · Done when: every finding has a verdict, the funnel reconciles (candidates raised equal the sum of classifications), and the report is final._

The optimizer MUST NOT grade its own work. Spawn a fresh-context agent (Agent tool), routed to a different model or provider than the scanner where the environment allows (e.g. Claude scans, OpenAI or Grok runs the adversarial pass); a fresh context on the same model is the last resort. Give it the tradeoff rubric (`../solidity-gas-tradeoffs-analysis/SKILL.md`), the gas policy resolved in Phase 0, the draft report, and the diffs (`git show` of each kept commit). Its job is to argue against each finding first, then issue `recommend` / `team-decision` / `reject` verdicts, each with a price tag. Save its output verbatim to `05-verdicts.md` (`templates/artifacts/05-verdicts-artifact.md`), then merge its verdicts and rationale into the report; do not soften them. For `reject`, revert that commit and move the finding to the rejected table with the analyzer's reason.

For a `competes-with` group, the challenge also picks the winning transform, since the winner is a tradeoff call, not a gas call: weigh each option's measured saving against its simplicity, compatibility, and risk, so a smaller but simpler transform can win. The chosen option becomes the finding; the others become `rejected (superseded by <id>)` with the reason. The options are mutually exclusive (one waste, one committed fix), so if the winner is not the one provisionally committed in Phase 4, revert that commit, apply the winner, and re-run the full suite before finalizing, the same green-gate as the integration step.

If no Agent tool is available (worst case), do the challenge in a separate pass: re-read `../solidity-gas-tradeoffs-analysis/SKILL.md`, adopt the skeptic role, and write the case against each finding before issuing any verdict. This same-context pass is not independent: label every verdict it produces `self-reviewed` and state that the findings were not independently challenged. Only a fresh-context agent (preferably a different model or provider) yields an independent verdict.

**Close the funnel and finalize.** The challenge is the last transition, so only now can the funnel reconcile. Fill the `challenge → report` exits (`rejected (challenge)`, `rejected (superseded)`, `kept`, `team-decision`) and run the reconciliation gate: every transition must balance (in equals passed-on plus exited-here) and total candidates raised must equal the sum of the six classifications. A row that does not balance means a candidate vanished, so find it before finalizing. Only after the funnel reconciles is the report final; hand over its path per the Phase 5 write locations.

## Deliverable

The run directory (`report.md` plus the `artifacts/` trail, so the process is auditable end to end) and the work branch with one commit per surviving change. Humans decide what merges; the `team-decision` findings are the agenda for that review.

A PR is never required. After handing over the report, mention that the user can, if they want, open a **draft PR** of the work branch, filled from `templates/pull-request.md` (push to the user's fork; target the branch the work was based on, so the diff is exactly the optimizations). Only do it if the user asks: opening it is outward-facing, so confirm first, keep the AI-generated note, and never present suggestions on someone else's PR as merged changes.
