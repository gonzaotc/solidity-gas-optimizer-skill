---
name: solidity-gas-optimizer
description: Run a measured gas-optimization audit on Solidity code. Use when asked to gas-optimize contracts, reduce gas costs, run a gas audit, find gas savings, reduce deployment or creation gas, make a contract cheaper to deploy, or profile gas usage; also for re-running or extending an existing gas audit. Works on Foundry and Hardhat projects. To persist a technique into the catalog for reuse, use solidity-gas-reference-creator instead.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Agent
argument-hint: "[files or directories to audit; defaults to the main contracts directory]"
---

# Solidity Gas Optimizer

Produce an audit-style gas report for a Solidity codebase. Every claimed saving is measured with the project's own toolchain and checked against its tests; every surviving change is then challenged by a separate-context tradeoff analysis (a different model or provider where the environment offers one, or a labeled self-review as a last resort). Idiomatic Solidity is the default: an optimization must pay for its complexity or it is rejected. A candidate that cannot be measured because no test exercises it is never silently dropped: it is surfaced as a coverage gap, so the audit also flags where the codebase is under-tested.

**Audience and invocation.** This is an agent skill: the human states the intent ("gas-optimize this contract") and the agent runs the audit; the scripts are not meant to be run by hand. It assumes Solidity familiarity and does not scaffold a project. Paths below are relative to this skill's directory.

**Prerequisites.** An existing Foundry or Hardhat project with a working gas reporter, a green test suite that exercises the target, and the sibling skill `../solidity-gas-tradeoffs-analysis` (required by Phase 5 and the default policy). If a prerequisite is missing, stop and tell the user what is missing rather than estimating.

## Non-negotiables

1. Never report a gas number you did not measure and verified. Advisory findings may carry estimates, which MUST clearly labeled as estimates.
2. Do not run without measurement. Prerequisites: a supported toolchain (Foundry or Hardhat) with a working gas reporter (`forge snapshot`, or `hardhat-gas-reporter` for Hardhat-only projects). If `detect-toolchain.sh` exits nonzero, stop and tell the user what is missing; never fall back to estimating transform findings.
3. Do not proceed on a failing baseline. If the test suite fails before you change anything, stop and report that instead.
4. One transform per commit. Gas attribution and human cherry-picking both depend on it.
5. Revert anything that measures flat or worse, or breaks a test, and record it in the report's rejected table. Negative results are findings.
6. Passing tests are necessary, not sufficient, and an unmeasurable candidate is a finding, not a discard. A real candidate whose target no test exercises cannot be measured: never call it verified, never fold it into the rejected table, and never silently drop it. Route it to the coverage-gap section of the report (Phase 4) with a labeled estimate and the specific tests needed to make it measurable. If a transform only partially touches untested lines, say so in the finding instead of calling it verified.
7. Findings are valid only for the compiler settings they were measured under. Record solc version, optimizer runs, and via-IR in the report.

## Reference catalog and gas mindset

The scan has two inputs, both read in full at scan time (Phase 2):

- `catalog/INDEX.md` lists every technique: ID, kind, detect hint. Open a category file (`catalog/storage.md` etc.) only when its hints match the code under review. This is the pattern layer: WHAT to look for.
- `references/gas-mindset.md` is the cost-accounting method for waste no card names: trace where every gas unit goes on the hot path and ask whether that cost needs to exist there. This is the reasoning layer: HOW to find the uncarded.

Never scan from memory alone; walk both.

- **Kind**: `transform` enters the verify loop, then the Phase 5 challenge; `advisory` is reported as a labeled estimate and never applied by the run. Every applied change gets a Phase 5 verdict and merges only by human decision. (Full schema: `../solidity-gas-reference-creator/references/card-spec.md`. To add or regenerate cards, use the `solidity-gas-reference-creator` skill; this skill is read-only over the catalog.)

## Intake

The banner is the first thing the user sees. Print it, then the tagline, as the very first output of the run, before any tool call: no clone, no `ls`, no advisor, no questions, no thinking-aloud ahead of it. The scope proposal in step 2 needs the repo enumerated, but that enumeration happens after the banner is on screen, not before. Then gather scope in one exchange. Skip any question the user already answered when invoking the skill, and confirm rather than re-ask. If the user said to just go, take the defaults below and proceed. Do not start Phase 0 until scope is settled.

Print exactly (before anything else):

```
  _____           ____       __  _       _                      
 / ___/__ ____   / __ \___  / /_(_)_ _  (_)__ ___ ____          
/ (_ / _ `(_-<  / /_/ / _ \/ __/ /  ' \/ /_ // -_) __/          
\___/\_,_/___/ _\____/ .__/\__/_/_/_/_/_//__/\__/_/      ___    
  / /  __ __  / __ \/_/  ___ ___/_  / ___ ___  ___  ___ / (_)__ 
 / _ \/ // / / /_/ / _ \/ -_) _ \/ /_/ -_) _ \/ _ \/ -_) / / _ \
/_.__/\_, /  \____/ .__/\__/_//_/___/\__/ .__/ .__/\__/_/_/_//_/
     /___/       /_/                   /_/  /_/                 
```

Then print exactly one short line, no more, no preamble:

```
Automated ai-assisted solidity gas optimizer.
```

Then ask all of the following in a single message so the user answers in one round:

1. **Target.** What to audit: a repo URL, a local folder, or a single file. If the target is a URL, clone it locally before Phase 0.
2. **Scope.** Token usage grows with scope, so never audit a whole repo blindly. Distinguish an explicit scope from an unfocused one:
   - **Named files:** confirm that exact set.
   - **A thematic named scope** ("every module related to multisig", "all the vesting contracts"): the user has already scoped it. Honor it in full: enumerate every module matching the theme, list them, and confirm the complete set. Do not narrow it to the largest one or two. If cost forces batching, run the set in serial batches but keep the whole matched set as the declared scope and name what is deferred; never silently drop members or reduce scope to where a finding happened to land.
   - **No target, or a whole repo or bare directory:** this is unfocused. Enumerate the candidate contracts and propose a scoped subset to run first (a few contracts, favoring the largest or most call-heavy surface), then ask them to confirm or adjust before starting. The "few contracts at a time" bias applies here only.
3. **Gas policy.** Ask whether they have a policy to provide. Explain that a policy encodes the project's constraints (layout freeze, assembly style, hot paths, noise floor) and sharpens every verdict, so it is recommended, but it is optional; note that if the target already ships one (`.claude/gas-policy.md` or a root `gas-policy.md`) it is picked up automatically in Phase 0.
4. **Report location.** Ask for a preferred output location. By default the report is written to two places: a `gas-reports/` directory inside the audited repo, and a `gas-reports/` directory inside this skill's own folder as a cross-run archive. A location the user names here overrides both.
5. **Model.** If running in Claude Code, note that stronger models tend to find and judge more, so the strongest available is recommended. A running session cannot switch its own model: if they want a different one, they select it (`/model` or relaunch) before continuing. If the environment can route the Phase 5 challenge to a different provider, mention that too.

## Phase 0: Discover

1. Run `scripts/detect-toolchain.sh <repo-root>`. It reports the framework, test commands, measurement commands, and compiler settings, and exits nonzero when the repo cannot be measured (unsupported toolchain, missing `forge`, or Hardhat without `hardhat-gas-reporter`). Nonzero exit means the prerequisites are not met: stop and report what is missing.
2. Choose the measurement tool per target, not per repo: find where the target's tests actually live. Pass the target to `detect-toolchain.sh` as its second argument so it decides `MEASURE_WITH` from the target's actual coverage. A repo-wide Foundry preference is wrong when the target is only covered by Hardhat tests, and vice versa. For Hardhat, read the config to learn how the gas reporter is enabled (`REPORT_GAS`, a `GAS` yargs env option, or a config flag); do not assume the env var name. When both toolchains are present, findings are measured under the solc settings of whichever toolchain covers the target; record those settings and, if the other toolchain's solc settings (version, optimizer runs, via-IR) diverge, warn in the report that the numbers would differ there.
3. Resolve the gas policy, first match wins: (1) a policy the user named when invoking the skill; (2) the target repo's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo; (3) the shipped defaults, which are the decision matrix in `../solidity-gas-tradeoffs-analysis/SKILL.md`, not a loadable file. For options (1)–(2), `templates/gas-policy.md` is the blank schema to fill, not the defaults themselves. Also read the target's CLAUDE.md (if existant), README.md, TESTING.md (if existant) and GUIDELINES/CONTRIBUTING (if existant) for constraints. Apply the policy's hard constraints and report-only reclassifications (a storage-layout freeze makes packing report-only; an assembly-averse style makes ASM cards report-only), and carry its context weighting and noise threshold into Phase 5. Compatibility is frozen by default: unless the policy sets `allow-layout-changes` or `allow-abi-changes`, treat any transform that changes storage layout or a `public`/`external` signature, event, or error as report-only. This is a semantic rule keyed on what the transform does, not a fixed card list: ST-03, ST-04, DEP-08, and ST-06 on upgradeable contracts are non-exhaustive examples, and other cards (e.g. ST-01, ST-07, ST-09, ST-14, ST-15) warn of the same breakage in their Risks. Judge by effect, not by whether the card is named here. Record which policy was used in the report.
4. Fix scope: the files the user named, or the full set matching a thematic named scope (Intake step 2), otherwise the project's contracts directory resolved from config (Foundry `src` via `forge config`; Hardhat `paths.sources`). For a thematic scope, resolve the complete member set by grep (name pattern, shared base contract, imports) and list every member before starting; a match the user would expect and you skipped is a scope miss, not a saving. When several source roots exist, or none is configured, ask the user rather than guessing. List the files explicitly before starting.

## Phase 1: Baseline

1. Run the test suite once; if it fails, stop and report. When the user scopes the audit to specific contracts and nothing else in the repo imports them (verify with a grep), scope the baseline and validation to the target's test files plus a full compile instead of the whole suite, and record the narrowed validation in the report. Treat the grep as a heuristic: it misses interface-only calls, address casts, and re-exports, so when in doubt fall back to the full suite. In large repositories a full-suite run per candidate is prohibitive; a scoped and recorded validation is preferable to a skipped one.
2. Run `scripts/gas-baseline.sh <framework> <baseline-dir> <repo-root>` with the baseline dir in scratch space outside the repo (e.g. `BASELINE_DIR=$(mktemp -d)`), never inside the repo. For Hardhat, when the detected `HARDHAT_GAS_TOGGLE` variable is not `REPORT_GAS`, pass it via `GAS_ENV` (e.g. `GAS_ENV=GAS`). If the baseline command fails, stop; without a baseline there is nothing to measure against.
3. Rank the in-scope functions by measured cost (and call frequency where the reporter shows it) from the per-function report the baseline captured: `gas-report.txt` (the `RANKING` output) for Foundry, the reporter table for Hardhat. Rank only from this artifact: `gas.snapshot` is the diff baseline of record, and its per-test totals are not comparable to the per-function report, so never mix the two numbers. This ranking, not the catalog order, drives the scan in Phase 2: gas lives in a few hot functions, so look there first. From the ranking, define the **hot set** with a recorded rule so two runs on the same target agree: default to the functions comprising the top 80% of cumulative measured gas, plus any in-scope function a static read flags as heavy (many storage touches, loops, or external calls) even if it is untested and so absent from the ranking. Including untested-but-heavy functions is deliberate: unmeasurable hot code is exactly the coverage-gap value this audit exists to surface, and a measured-gas-only rule would drop it to the cold tier. State the rule used and list the members; keep the set tight (a large scope yields more hot functions, not a fixed cap). Everything in scope but outside the hot set is the cold remainder. This split sets each function's tier in the inventory (step 5) and the hot-deep/cold-wide order in Phase 2.
4. Build a coverage map of the in-scope functions: which ones a test actually exercises (grep the test directory for calls and deployments; a function absent from the baseline per-function report is a strong signal nothing exercises it). This map decides, in Phase 2, whether a candidate can be measured at all. Functions with no exercising test cannot yield a measured finding; their candidates become coverage-gap candidates rather than being dropped.
5. Build the resource inventory: enumerate before matching cards, so the scan has a complete work list to answer to. Enumerate **every** in-scope function, not just the hot ones; completeness is the point, and analysis depth (not enumeration) is what tapers later. Row grain follows the tier, because the passes work at different grains: the resource-flow and lifecycle passes interrogate individual sites, while a catalog match reads a whole function and matches detect-hints. So:
   - **Hot functions: one row per resource site** (a specific SLOAD, a specific call, a specific loop), since each site is interrogated three ways and needs its own disposition.
   - **Cold functions: one row per function**, listing the resource classes it contains, since its one required pass is a single catalog read of the function.

   Columns:
   - **site** — for a hot row, `contract.function` and the line or block; for a cold row, `contract.function` and the resource classes present
   - **class** — one or more of: storage-read (SLOAD), storage-write (SSTORE), external call (CALL/STATICCALL), delegatecall (DELEGATECALL), value-bearing call, contract creation (CREATE/CREATE2), loop/control, calldata/memory copy, returndata copy, hashing (KECCAK256), event/log (LOG), revert-data construction, deploy/code-size
   - **multiplicity** — how many times it is paid: a fixed count, a loop bound, a call count, or per-call overhead (this column feeds Phase 2's expected-value ordering)
   - **tier** — `hot` or `cold`, from the step-3 hot set
   - **required passes** — from the tier: a hot site requires catalog + resource-flow + lifecycle; a cold function requires the catalog walk
   - **completed passes** — left blank here; Phase 2 fills it as each required pass runs
   - **candidate IDs** — left blank here; Phase 2 fills it with any candidates raised (may stay empty; a row can be examined and yield nothing)
   - **coverage** — `exercised` or `none`, carried from step 4

   This step is enumeration only: record raw facts, never a judgment about waste or a fix. A slot read is a `storage-read` row, not a "cache this" candidate; a value fixed at deployment but derived at runtime is a `storage-read` row whose multiplicity flags repeated reads, not an "`immutable` candidate" (that choice is discovery, made in Phase 2). Write the inventory as a run artifact in scratch space so the work list is complete and on paper before scanning begins; an unwritten row is one the scan can silently skip. The inventory is the coverage obligation Phase 2 answers to: `completed passes` must reach `required passes` for every row, while `candidate IDs` may be empty.

## Phase 2: Scan

Read `catalog/INDEX.md` and `references/gas-mindset.md` in full at scan time. The catalog is the pattern layer (WHAT to look for); the mindset is the cost-accounting layer (HOW to find waste no card names). The Phase 1 resource inventory is the scan's work list: for every row, the scan must run the passes named in its `required passes` and record each in `completed passes`. A row whose `completed passes` never reaches its `required passes` is a **scan omission**, not a silent skip: reconcile it before leaving Phase 2. (`scan omission` means the scanner never examined the row; it is distinct from a coverage gap, which means a test never exercises the code.) Scan hottest functions first and deep, then the cold remainder wide:

1. **Hot rows, all three passes.** Take the `hot`-tier rows and run each through all three, since that is where tracing every gas unit repays most. Mark each pass in `completed passes` as it runs:
   - **Catalog match.** When a Detect hint matches or sounds slightly relevant, open the category file and check the card's full Preconditions before recording a candidate.
   - **Resource-flow pass** (`references/gas-mindset.md`, Pass A). Interrogate each row: ask "does this cost need to exist here?" Record every site paid more often, colder, wider, or earlier than the semantics require.
   - **Lifecycle pass** (Pass B). Diff paired paths (view/write, deposit/withdraw, happy/revert, first/subsequent, constructor/runtime, one-call/many-call) and account for the delta; record avoidable work on the heavier side.
2. **Cold rows, catalog sweep.** Each `cold`-tier row is a whole function. Read it against the full INDEX so no card is missed, opening a category file on any hint match to check its Preconditions, then mark the catalog pass complete on that row. Enumeration already listed these functions and their resource classes; the sweep is their one required pass, not an optional skim.
3. The catalog is the minimum scan set, not a ceiling and may be incomplete. A candidate the mindset passes surface with no matching card is recorded as `uncarded`; it earns a finding only by passing the same Phase 3 verify loop and Phase 5 challenge as any card. Follow the mindset file's greedy-finder discipline: record the candidate, do not self-censor, and give `estimated impact` as a rough magnitude class, never a precise gas figure. Never claim a saving from memory without measuring it. Flag survivors for a follow-up card via the reference-creator skill.
4. Record candidates as `{candidate id, card ID or "uncarded", location, why it applies, estimated impact, kind after policy, coverage}`. Give each a short `candidate id` and write it into the `candidate IDs` column of the inventory row that raised it, so every candidate traces to a site and every site shows what it produced. `coverage` (`exercised` or `none`) is the inventory row's own column, carried from the Phase 1.4 map.
5. Advisory candidates (including any the policy reclassified to report-only) skip Phase 3 and go straight to the report.
6. A transform candidate whose target has `coverage: none` cannot be measured. Do not push it through Phase 3 and do not drop it: route it to the coverage-gap section (Phase 4) with its labeled estimate and the specific tests that would make it measurable. This is the audit's coverage-probe value: unmeasurable hot code is under-tested code, and the report says so.
7. Order the remaining (`exercised`) transform candidates for Phase 3 by expected value: hot paths and per-call savings before deploy-only and cold paths.

## Phase 3: Verify loop

Work on a dedicated branch (`gas/<scope>`). For each transform candidate, strictly one at a time:

1. Apply the minimal diff for this one card.
2. Compile, then run targeted tests: test files matching the contract name, plus any test file that imports or deploys the contract (grep the test directory). Failing tests mean either a bad application or a real behavior change; retry once, then revert and record.
3. Measure with `scripts/gas-compare.sh <framework> <baseline-dir> <repo-root>` against the baseline dir from Phase 1.2. Record the deployment/code-size delta alongside the runtime delta: bigger code is a real cost, and for internal-function libraries it lands in every consumer contract. The Foundry snapshot diff is deterministic; the Hardhat reporter output is not line-deterministic, so for Hardhat read the diff and extract each function's before/after by hand, and label any finding measured that way as manually extracted. When both toolchains cover the target, prefer the Foundry measurement.
4. If the improvement is above the policy's noise threshold (default: 10 gas per call unless the policy sets otherwise; this default is a heuristic, not a measured bound), run the project's formatter and linter on the touched file, then commit as `gas: <CARD-ID> <file>: <summary> (<delta>)`. If the project defines no formatter or linter, run `forge fmt` on the touched file and skip linting. If the measurement is a regression, revert and record it as rejected. If it is flat, revert; a genuine flat result is rejected, but a change that should move gas yet measures exactly zero because no test drives the touched path is a coverage gap, not a measured no-gain: reclassify it to the coverage-gap section with the tests it needs. If a pre-commit hook fails for reasons unrelated to the change, record the hook's full failure output and the specific reason it is unrelated in the report, then commit with `--no-verify`; when in doubt whether the failure is related, fail loudly and stop rather than bypass.
5. Every surviving change stays on the branch for explicit review; never present a survivor as settled. The merge decision is the team's for every finding.

After the last candidate, run the **full** suite once. If it fails, bisect the kept commits to find the interaction and drop the offender. Keep the loop serial: interleaved candidates corrupt gas attribution.

## Phase 4: Report

Fill `templates/report.md` and write it as `gas-report-<target>-<date>.md`. If the user named a location in Phase 0, write there. Otherwise write it to two places: a `gas-reports/` directory inside the audited repo (created if absent), and a `gas-reports/` directory inside this skill's own folder (created if absent) as a cross-run archive. The audited-repo copy is the deliverable and must always be written; the skill-folder archive is best-effort: when the skill's own folder is not writable (a read-only or shared install), skip the archive copy and warn instead of failing. Keep the audited-repo copy untracked: add `gas-reports/` to that repo's `.git/info/exclude`, or tell the user it must stay uncommitted. The report is the primary deliverable: hand the user its path explicitly at the end, never leave it only in scratch space. Findings are numbered `GAS-<H|M|L>-NN` (severity in the ID, numbered within each severity), ordered by severity. Include all five populations: applied-and-measured, team-decision, advisory, rejected (with their measured evidence), and coverage-gap. The coverage-gap section is its own population, never merged into rejected: rejected candidates were measured and failed, coverage-gap candidates were never measurable. List each coverage-gap entry with the function, the technique that would apply, a labeled estimated impact, and the specific tests needed, then rank them by estimated impact so a hot uncovered function reads as urgent and a cold rare one does not. Close the section by telling the user to add those tests and re-run the audit.

Severity (impact axis):

- **High**: ≥500 gas per call on a hot user path, ≥5% of a function's cost, or ≥10k deploy gas on factory/clone-deployed contracts.
- **Medium**: 100–500 gas per call on regular paths.
- **Low**: <100 gas per call, admin or rare paths, deploy-only savings on one-off deployments.

## Phase 5: Tradeoff challenge

The optimizer MUST NOT grade its own work. Spawn a fresh-context agent (Agent tool). If your environment can route it to a different model or provider than the scanner, prefer that (e.g. Claude scans, a different provider runs such as openai or grok the adversarial tradeoff pass); otherwise a fresh context on the same model is fine as a last resort. Give it: the tradeoff rubric (`../solidity-gas-tradeoffs-analysis/SKILL.md`), the gas policy resolved in Phase 0, the draft report, and the diffs (`git show` of each kept commit). Its job is to argue against each finding first, then issue `recommend` / `team-decision` / `reject` verdicts, each with a price tag. Merge its verdicts and rationale into the report verbatim; do not soften them. For `reject`, revert that commit and move the finding to the rejected table with the analyzer's reason.

If no Agent tool is available (worst case), do the challenge in a separate pass: re-read `../solidity-gas-tradeoffs-analysis/SKILL.md`, adopt the skeptic role, and write the case against each finding before issuing any verdict. This same-context pass is not independent: label every verdict it produces `self-reviewed` in the report and state that the findings were not independently challenged. Only a fresh-context agent (preferably a different model or provider) yields an independent verdict.

## Deliverable

The filled report plus the work branch with one commit per surviving change. Humans decide what merges; the `team-decision` findings are the agenda for that review.

A PR is never required. After handing over the report, just mention that the user can, if they want, open a **draft PR** of the work branch, filled from `templates/pull-request.md` (push to the user's fork; target the branch the work was based on, so the diff is exactly the optimizations). Only do it if the user asks: opening it is outward-facing, so confirm first, keep the AI-generated note, and never present suggestions on someone else's PR as merged changes.
