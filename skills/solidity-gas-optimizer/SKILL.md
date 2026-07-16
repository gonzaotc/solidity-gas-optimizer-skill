---
name: solidity-gas-optimizer
description: Run a measured gas-optimization audit on Solidity code. Use when asked to gas-optimize contracts or run a gas audit, reduce deployment or creation gas, profile gas usage, or re-run or extend an existing gas audit. To persist a technique into the catalog for reuse, use solidity-gas-reference-creator instead.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Agent
argument-hint: "[files or directories to audit; defaults to the main contracts directory]"
---

# Solidity Gas Optimizer

Produce an audit-style gas report for a Solidity codebase. Every claimed saving is measured with the project's own toolchain and checked against its tests, then challenged by a separate-context tradeoff analysis (a different model or provider where one is available, a labeled self-review otherwise). Idiomatic Solidity is the default: an optimization must pay for its complexity or it is rejected. A candidate no test exercises cannot be measured, so it is surfaced as a coverage gap; the audit thus also flags where the codebase is under-tested.

Paths below are relative to this skill's directory. This skill audits an existing project; it does not scaffold one.

**Prerequisites.** A Foundry or Hardhat project with a working gas reporter, a green test suite exercising the target, and the sibling skill `../solidity-gas-tradeoffs-analysis` (Phase 5 and the default policy). If one is missing, stop and say so rather than estimate.

## Non-negotiables

1. Report only gas numbers you measured and verified; label every advisory estimate as an estimate.
2. A transform finding requires a measurement: never estimate one. A supported toolchain with a working gas reporter is a prerequisite; if it is missing, stop (Phase 0).
3. Stop on a failing baseline: if the suite fails before you change anything, report that instead.
4. One transform per commit. Gas attribution and human cherry-picking both depend on it.
5. Revert anything that measures flat or worse, or breaks a test, and record it in the report's rejected table. Negative results are findings.
6. Conserve every candidate: each ends in exactly one disposition (`references/candidate-lifecycle.md`). A real candidate no test exercises is a coverage-gap finding, not a discard: route it to the coverage-gap section (Phase 4) with a labeled estimate and the tests needed to measure it. If a transform only partially touches untested lines, say so rather than call it verified.
7. Findings are valid only for the compiler settings they were measured under. Record solc version, optimizer runs, and via-IR in the report.
8. Firewall discovery from validation on the candidate lifecycle, not on phase numbers: no candidate is edited into code, exercised by a test, or given a measured gas number until the Phase 3 verify loop; during discovery it carries only an estimated-impact magnitude class. Baseline measurement of existing code (Phase 1) is not candidate measurement.

## Reference catalog and gas mindset

The scan has two inputs, both read in full at scan time (Phase 2):

- `catalog/INDEX.md` lists every technique: ID, kind, detect hint. Open a category file (`catalog/storage.md` etc.) only when its hints match the code under review. This is the pattern layer: WHAT to look for.
- `references/gas-mindset.md` is the cost-accounting method for waste no card names: trace where every gas unit goes on the hot path and ask whether that cost needs to exist there. This is the reasoning layer: HOW to find the uncarded.

Never scan from memory alone; walk both.

**Kind**: `transform` enters the verify loop, then the Phase 5 challenge; `advisory` is reported as a labeled estimate and never applied by the run. Every applied change gets a Phase 5 verdict and merges only by human decision. (Full schema: `../solidity-gas-reference-creator/references/card-spec.md`. To add or regenerate cards, use the `solidity-gas-reference-creator` skill; this skill is read-only over the catalog.)

## Discovery ledger

Candidates are **conserved**: each ends in exactly one disposition. The ledger is the Phase 2 candidate record carried forward, one row per candidate, that Phase 3 advances with a `state` and Phases 4 and 5 finalize with a `disposition`.

The states, the six dispositions (`kept`, `team-decision`, `advisory`, `coverage-gap`, `rejected`, `duplicate`), dedup-by-mechanism, and the discovery-funnel arithmetic are the single source of truth in `references/candidate-lifecycle.md`; read it when Phase 2 begins. Discovery raises candidates and validation measures them; the two are firewalled (non-negotiable 8).

## Intake

Print the banner and tagline below as the very first output of the run, before any tool call: no clone, no `ls`, no advisor, no questions, nothing ahead of it. Step 2 needs the repo enumerated, but that happens after the banner is on screen. Then gather scope in one exchange: skip any question already answered at invocation and confirm rather than re-ask; if the user said to just go, take the defaults and proceed. Do not start Phase 0 until scope is settled.

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
   - **No target, or a whole repo or bare directory:** unfocused. Enumerate the candidate contracts, propose a scoped subset to run first (a few contracts, favoring the largest or most call-heavy surface), and ask the user to confirm or adjust. The "few contracts at a time" bias applies here only.
3. **Gas policy.** Ask whether they have a policy. A policy encodes the project's constraints (layout freeze, assembly style, hot paths, noise floor) and sharpens every verdict, so recommend it, though it is optional. One the target ships (`.claude/gas-policy.md` or a root `gas-policy.md`) is picked up automatically in Phase 0.
4. **Report location.** Ask for a preferred output location; it overrides the Phase 4 default (a `gas-reports/` directory in the audited repo, plus an archive copy in this skill's folder).
5. **Model.** In Claude Code, stronger models find and judge more, so recommend the strongest available. A session cannot switch its own model: the user selects it (`/model` or relaunch) before continuing. Mention provider routing for the Phase 5 challenge if the environment offers it.

## Phase 0: Discover

1. Run `scripts/detect-toolchain.sh <repo-root>`. It reports the framework, test and measurement commands, and compiler settings, and exits nonzero when the repo cannot be measured (unsupported toolchain, missing `forge`, or Hardhat without `hardhat-gas-reporter`). A nonzero exit means the prerequisites are unmet: stop and report what is missing.
2. Choose the measurement tool per target, not per repo: pass the target to `detect-toolchain.sh` as its second argument so it sets `MEASURE_WITH` from the target's actual coverage, since a repo-wide preference mismeasures a target its own toolchain does not cover. For Hardhat, read the config for how the gas reporter is enabled (`REPORT_GAS`, a `GAS` yargs env option, or a config flag); do not assume the env var name. When both toolchains are present, measure under the solc settings of whichever covers the target, record them, and warn if the other's settings (version, optimizer runs, via-IR) diverge.
3. Resolve the gas policy, first match wins: (1) a policy the user named when invoking the skill; (2) the target repo's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo root; (3) the shipped defaults, which are the decision matrix in `../solidity-gas-tradeoffs-analysis/SKILL.md`, not a loadable file. For options (1)–(2), `templates/gas-policy.md` is the blank schema to fill. Also read the target's CLAUDE.md, README.md, TESTING.md, and GUIDELINES/CONTRIBUTING for constraints. Apply the policy's hard constraints and report-only reclassifications (a storage-layout freeze makes packing report-only; an assembly-averse style makes ASM cards report-only), and carry its context weighting and noise threshold into Phase 5. Compatibility is frozen by default (`../solidity-gas-tradeoffs-analysis/SKILL.md`): judge by what a transform does, not by card name, and treat any change to storage layout or a `public`/`external` signature, event, or error as report-only unless the policy sets `allow-layout-changes` or `allow-abi-changes`. Record which policy was used in the report.
4. Fix scope: the files the user named, the full set matching a thematic scope (Intake step 2), or otherwise the contracts directory from config (Foundry `src` via `forge config`; Hardhat `paths.sources`). For a thematic scope, resolve the complete member set by grep (name pattern, shared base, imports) and list every member; a match the user would expect but you skipped is a scope miss, not a saving. When several source roots exist, or none is configured, ask rather than guess. List the files before starting.

## Phase 1: Baseline

1. Run the test suite once; if it fails, stop and report. When the scope is specific contracts nothing else in the repo imports (verify with a grep), narrow the baseline and validation to the target's test files plus a full compile, and record that narrowing. The grep is a heuristic that misses interface-only calls, address casts, and re-exports, so fall back to the full suite when in doubt. In large repos a full-suite run per candidate is prohibitive, and a scoped, recorded validation beats a skipped one.
2. Run `scripts/gas-baseline.sh <framework> <baseline-dir> <repo-root>` with the baseline dir in scratch space outside the repo (e.g. `BASELINE_DIR=$(mktemp -d)`), never inside it. For Hardhat, when the detected `HARDHAT_GAS_TOGGLE` is not `REPORT_GAS`, pass it via `GAS_ENV` (e.g. `GAS_ENV=GAS`). If the baseline command fails, stop: without a baseline there is nothing to measure against.
3. Rank the in-scope functions by measured cost (and call frequency where the reporter shows it) from the per-function report the baseline captured: `gas-report.txt` (the `RANKING` output) for Foundry, the reporter table for Hardhat. Rank only from this artifact: `gas.snapshot` is the diff baseline of record and its per-test totals are not comparable, so never mix the two. This ranking, not the catalog order, drives the scan, since gas lives in a few hot functions. Define the **hot set** by a recorded rule so two runs agree: the functions making up the top 80% of cumulative measured gas, plus any in-scope function a static read flags as heavy (many storage touches, loops, external calls) even if untested and absent from the ranking. Including untested-but-heavy functions is deliberate: unmeasurable hot code is the coverage-gap value this audit surfaces, which a measured-gas-only rule would miss. State the rule and list the members; keep the set tight. Everything in scope outside it is the cold remainder. The split sets each function's tier in the inventory (step 5) and the hot-deep/cold-wide order in Phase 2.
4. Build a coverage map of the in-scope functions: which ones a test exercises (grep the test directory for calls and deployments; absence from the baseline per-function report is a strong signal nothing exercises it). This decides in Phase 2 whether a candidate can be measured. A function no test exercises cannot yield a measured finding, so its candidates become coverage-gap candidates, not discards.
5. Build the resource inventory: enumerate before matching cards, so the scan has a complete work list. Enumerate **every** in-scope function, not just the hot ones; completeness is the point, and analysis depth, not enumeration, is what tapers later. Row grain follows the tier, because the passes work at different grains (resource-flow and lifecycle interrogate individual sites; a catalog match reads a whole function against detect-hints):
   - **Hot functions: one row per resource site** (a specific SLOAD, call, or loop), since each site is interrogated three ways and needs its own disposition.
   - **Cold functions: one row per function**, listing the resource classes it contains, since its one required pass is a single catalog read.

   Columns:
   - **site** — for a hot row, `contract.function` and the line or block; for a cold row, `contract.function` and the resource classes present
   - **class** — one or more of: storage-read (SLOAD), storage-write (SSTORE), external call (CALL/STATICCALL), delegatecall (DELEGATECALL), value-bearing call, contract creation (CREATE/CREATE2), loop/control, calldata/memory copy, returndata copy, hashing (KECCAK256), event/log (LOG), revert-data construction, deploy/code-size
   - **multiplicity** — how many times it is paid: a fixed count, loop bound, call count, or per-call overhead (feeds Phase 2's expected-value ordering)
   - **tier** — `hot` or `cold`, from the step-3 hot set
   - **required passes** — from the tier: a hot site requires catalog + resource-flow + lifecycle; a cold function requires the catalog walk
   - **completed passes** — blank here; Phase 2 fills it as each pass runs
   - **candidate IDs** — blank here; Phase 2 fills it with any candidates raised (may stay empty)
   - **coverage** — `exercised` or `none`, carried from step 4

   This step is enumeration only: record raw facts, never a judgment about waste or a fix. A slot read is a `storage-read` row, not a "cache this" candidate; a value fixed at deployment but derived at runtime is a `storage-read` row whose multiplicity flags repeated reads, not an "`immutable` candidate" (that choice is discovery, Phase 2). Write the inventory to scratch space before scanning; an unwritten row is one the scan can silently skip. The inventory is the coverage obligation Phase 2 answers to: `completed passes` must reach `required passes` for every row, while `candidate IDs` may stay empty.

## Phase 2: Scan

Read `catalog/INDEX.md` and `references/gas-mindset.md` in full at scan time. The Phase 1 inventory is the scan's work list: for every row, run the passes in its `required passes` and record each in `completed passes`. A row whose `completed passes` never reaches its `required passes` is a **scan omission**, not a silent skip: reconcile it before leaving Phase 2. A scan omission (the scanner never examined the row) is distinct from a coverage gap (no test exercises the code). Scan the hottest functions first and deep, then the cold remainder wide:

1. **Hot rows, all three passes.** Run each `hot`-tier row through all three, since tracing every gas unit repays most there. Mark each pass in `completed passes` as it runs:
   - **Catalog match.** When a Detect hint matches or sounds slightly relevant, open the category file and check the card's full Preconditions before recording a candidate.
   - **Resource-flow pass** (`references/gas-mindset.md`, Pass A). Ask of each row "does this cost need to exist here?" Record every site paid more often, colder, wider, or earlier than the semantics require.
   - **Lifecycle pass** (Pass B). Diff paired paths (view/write, deposit/withdraw, happy/revert, first/subsequent, constructor/runtime, one-call/many-call) and account for the delta; record avoidable work on the heavier side.
2. **Cold rows, catalog sweep.** Each `cold`-tier row is a whole function. Read it against the full INDEX so no card is missed, opening a category file on any hint match to check its Preconditions, then mark the catalog pass complete. Enumeration already listed these functions and their resource classes; the sweep is their one required pass, not an optional skim.
3. The catalog is the minimum scan set, not a ceiling, and may be incomplete. A candidate the mindset passes surface with no matching card is recorded as `uncarded`; it earns a finding only by passing the same Phase 3 verify loop and Phase 5 challenge as any card. Follow the mindset file's greedy-finder discipline: record the candidate, do not self-censor, and give `estimated impact` as a rough magnitude class, never a precise gas figure. Never claim a saving from memory without measuring it. Flag survivors for a follow-up card via the reference-creator skill.
4. Record candidates as `{candidate id, card ID or "uncarded", location, expensive resource, redundant operation, semantic constraint, why it applies, estimated impact, kind after policy, coverage, state}`. The `(location, expensive resource, redundant operation, semantic constraint)` tuple is the dedup key: `expensive resource` is the resource class being wasted (SLOAD, SSTORE, CALL, memory copy, ...), `redundant operation` is what the fix removes (a repeated read, a re-decode, a re-hash), `semantic constraint` is what the fix must preserve (same result, events, reverts, layout). `state` is `candidate` here; Phase 3 advances it. Give each a short `candidate id` and write it into the `candidate IDs` column of the inventory row that raised it, so every candidate traces to a site and every site shows what it produced. `coverage` (`exercised` or `none`) is carried from the Phase 1.4 map.
5. **Dedup by mechanism.** Once the full candidate set is recorded, apply dedup-by-mechanism (`references/candidate-lifecycle.md`) before any routing or ordering below, so the same transform is never measured, reported, or counted twice.
6. Advisory candidates (including any the policy reclassified to report-only) skip Phase 3 and go straight to the report.
7. A transform candidate whose target has `coverage: none` cannot be measured. Do not push it through Phase 3 and do not drop it: route it to the coverage-gap section (Phase 4) with its labeled estimate and the specific tests that would make it measurable. This is the audit's coverage-probe value: unmeasurable hot code is under-tested code, and the report says so.
8. Order the remaining (`exercised`) transform candidates for Phase 3 by expected value: hot paths and per-call savings before deploy-only and cold paths.

## Phase 3: Verify loop

Work on a dedicated branch (`gas/<scope>`). This is the first phase allowed to edit code or attach a gas number (non-negotiable 8): each candidate advances from `candidate` to `measured result` here. For each transform candidate, strictly one at a time:

1. Apply the minimal diff for this one card.
2. Compile. A compile failure means the diff is malformed for this codebase: retry once, then revert and record `rejected (compile failure)`. Then run targeted tests: files matching the contract name, plus any that import or deploy it (grep the test directory). Failing tests mean a bad application or a real behavior change: retry once, then revert and record `rejected (broke targeted tests)`.
3. Measure with `scripts/gas-compare.sh <framework> <baseline-dir> <repo-root>` against the Phase 1.2 baseline dir. Record the deployment/code-size delta alongside the runtime delta: bigger code is a real cost, and for internal-function libraries it lands in every consumer. The Foundry snapshot diff is deterministic; the Hardhat reporter output is not line-deterministic, so for Hardhat read the diff and extract each function's before/after by hand, and label such a finding manually extracted. When both toolchains cover the target, prefer the Foundry measurement.
4. If the improvement is above the policy's noise threshold (default: 10 gas per call unless the policy sets otherwise; a heuristic, not a measured bound), run the project's formatter and linter on the touched file, then commit as `gas: <CARD-ID> <file>: <summary> (<delta>)`. If the project defines no formatter or linter, run `forge fmt` on the touched file and skip linting. Every measured outcome gets a disposition; none is dropped:
   - A regression: revert and record `rejected (regression)`.
   - A positive delta below the noise threshold: revert and record `rejected (below noise floor)` with the measured number, so a real but trivial saving is accounted for.
   - A genuine flat result (moves zero on a path a test does drive): revert and record `rejected (flat)`.
   - Exactly zero because no test drives the touched path: not a measured no-gain but a coverage gap; do not record it as rejected, reclassify it to the coverage-gap section with the tests it needs.
   - Competing transforms for the same waste (a `competes-with` group) touch the same location and cannot be stacked. Measure each option from an identical baseline: reset the working tree to the group's shared parent between options, never applying one on top of another. Record every option's number. Do not choose here: provisionally commit the largest-saving option, leave the others uncommitted with their recorded deltas, and hand the group to Phase 5, which picks the winner on tradeoff grounds. A sibling that measures flat or regresses is rejected normally; only saving siblings compete.
   If a pre-commit hook fails for reasons unrelated to the change, record the hook's full failure output and the specific reason it is unrelated, then commit with `--no-verify`; when in doubt whether the failure is related, fail loudly and stop rather than bypass.
5. Every surviving change stays on the branch for explicit review; never present a survivor as settled. The merge decision is the team's for every finding.

After the last candidate, run the **full** suite (the integration transition). If it fails, bisect the kept commits to find the offending interaction, drop that commit as `rejected (integration)` (it passed alone but broke the suite in combination), and re-run. Repeat attribution, removal, and re-validation until the suite is green: one removal does not guarantee it, since several kept commits may interact. Keep the loop serial: interleaved candidates corrupt gas attribution.

## Phase 4: Draft report

Build the **discovery funnel** through the integration transition and put it in the draft (template section: Discovery funnel). It is per-transition, not one final tally; the exits at each transition are enumerated in `references/candidate-lifecycle.md`. Leave the final `challenge → report` transition blank: it is pending until Phase 5. This is a draft: the funnel is not yet reconciled and no verdict is final until Phase 5 closes it.

Fill `templates/report.md` and write it as `gas-report-<target>-<date>.md`; the template defines every section and population (findings, advisory, coverage-gap, rejected) and their rules, including that coverage-gap is its own population and never merged into rejected. If the user named a location in Phase 0, write there. Otherwise write to two places: a `gas-reports/` directory inside the audited repo (created if absent), and a `gas-reports/` directory inside this skill's own folder as a cross-run archive. The audited-repo copy is the deliverable and must always be written; the archive is best-effort, so when the skill's folder is not writable, skip it and warn instead of failing. Keep the audited-repo copy untracked: add `gas-reports/` to that repo's `.git/info/exclude`, or tell the user it must stay uncommitted. Hand the user the report path explicitly at the end, never leave it only in scratch space.

Severity (impact axis):

- **High**: ≥500 gas per call on a hot user path, ≥5% of a function's cost, or ≥10k deploy gas on factory/clone-deployed contracts.
- **Medium**: 100–500 gas per call on regular paths.
- **Low**: <100 gas per call, admin or rare paths, deploy-only savings on one-off deployments.

## Phase 5: Tradeoff challenge

The optimizer MUST NOT grade its own work. Spawn a fresh-context agent (Agent tool), routed to a different model or provider than the scanner where the environment allows (e.g. Claude scans, OpenAI or Grok runs the adversarial pass); a fresh context on the same model is the last resort. Give it the tradeoff rubric (`../solidity-gas-tradeoffs-analysis/SKILL.md`), the gas policy resolved in Phase 0, the draft report, and the diffs (`git show` of each kept commit). Its job is to argue against each finding first, then issue `recommend` / `team-decision` / `reject` verdicts, each with a price tag. Merge its verdicts and rationale into the report verbatim; do not soften them. For `reject`, revert that commit and move the finding to the rejected table with the analyzer's reason.

For a `competes-with` group, the challenge also picks the winning transform, since the winner is a tradeoff call, not a gas call: weigh each option's measured saving against its simplicity, compatibility, and risk, so a smaller but simpler transform can win. The chosen option becomes the finding; the others become `rejected (superseded by <id>)` with the reason. The options are mutually exclusive (one waste, one committed fix), so if the winner is not the one provisionally committed in Phase 3, revert that commit, apply the winner, and re-run the full suite before finalizing, the same green-gate as the integration step.

If no Agent tool is available (worst case), do the challenge in a separate pass: re-read `../solidity-gas-tradeoffs-analysis/SKILL.md`, adopt the skeptic role, and write the case against each finding before issuing any verdict. This same-context pass is not independent: label every verdict it produces `self-reviewed` and state that the findings were not independently challenged. Only a fresh-context agent (preferably a different model or provider) yields an independent verdict.

**Close the funnel and finalize.** The challenge is the last transition, so only now can the funnel reconcile. Fill the `challenge → report` exits (`rejected (challenge)`, `rejected (superseded)`, `kept`, `team-decision`) and run the reconciliation gate (`references/candidate-lifecycle.md`): every transition must balance and total candidates raised must equal the sum of the six dispositions. A row that does not balance means a candidate vanished, so find it before finalizing. Only after the funnel reconciles is the report final; hand over its path per the Phase 4 write locations.

## Deliverable

The filled report plus the work branch with one commit per surviving change. Humans decide what merges; the `team-decision` findings are the agenda for that review.

A PR is never required. After handing over the report, mention that the user can, if they want, open a **draft PR** of the work branch, filled from `templates/pull-request.md` (push to the user's fork; target the branch the work was based on, so the diff is exactly the optimizations). Only do it if the user asks: opening it is outward-facing, so confirm first, keep the AI-generated note, and never present suggestions on someone else's PR as merged changes.
