---
name: solidity-gas-optimizer
description: Run a measured gas-optimization audit on Solidity code. Use when asked to gas-optimize contracts, reduce gas costs, run a gas audit, find gas savings, or profile gas usage. Works on Foundry and Hardhat projects. To persist a technique into the catalog for reuse, use solidity-gas-reference-creator instead.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Agent
argument-hint: "[files or directories to audit; defaults to the main contracts directory]"
---

# Solidity Gas Optimizer

Produce an audit-style gas report for a Solidity codebase. Every claimed saving is verified by tests and measured with the project's own toolchain; every surviving change is then challenged by an adversarial tradeoff analysis. Idiomatic Solidity is the default: an optimization must pay for its complexity or it is rejected.

## Non-negotiables

1. Never report a gas number you did not measure and verified. Advisory findings may carry estimates, which MUST clearly labeled as estimates.
2. Do not run without measurement. Prerequisites: a supported toolchain (Foundry or Hardhat) with a working gas reporter (`forge snapshot`, or `hardhat-gas-reporter` for Hardhat-only projects). If `detect-toolchain.sh` exits nonzero, stop and tell the user what is missing; never fall back to estimating transform findings.
3. Do not proceed on a failing baseline. If the test suite fails before you change anything, stop and report that instead.
4. One transform per commit. Gas attribution and human cherry-picking both depend on it.
5. Revert anything that measures flat or worse, or breaks a test, and record it in the report's rejected table. Negative results are findings.
6. Passing tests are necessary, not sufficient. If a transform touches lines no test exercises, say so in the finding instead of calling it verified and recommend to add tests.
7. Findings are valid only for the compiler settings they were measured under. Record solc version, optimizer runs, and via-IR in the report.

## Reference catalog

`catalog/INDEX.md` lists every technique: ID, kind, detect hint. Read INDEX.md in full at scan time. Open a category file (`catalog/storage.md` etc.) only when its hints match the code under review. Never scan from memory alone; walk the checklist.

- **Kind**: `transform` enters the verify loop, then the Phase 5 challenge; `advisory` is reported as a labeled estimate and never applied by the run. Every applied change gets a Phase 5 verdict and merges only by human decision. (Full schema: `card-spec.md` in the reference-creator skill.)

## Phase 0: Discover

1. Run `scripts/detect-toolchain.sh <repo-root>`. It reports the framework, test commands, measurement commands, and compiler settings, and exits nonzero when the repo cannot be measured (unsupported toolchain, missing `forge`, or Hardhat without `hardhat-gas-reporter`). Nonzero exit means the prerequisites are not met: stop and report what is missing.
2. Choose the measurement tool per target, not per repo: find where the target's tests actually live. Pass the target to `detect-toolchain.sh` as its second argument so it decides `MEASURE_WITH` from the target's actual coverage. A repo-wide Foundry preference is wrong when the target is only covered by Hardhat tests, and vice versa. For Hardhat, read the config to learn how the gas reporter is enabled (`REPORT_GAS`, a `GAS` yargs env option, or a config flag); do not assume the env var name. When both toolchains are present, findings are measured under the solc settings of whichever toolchain covers the target; record those settings and, if the other toolchain's solc settings (version, optimizer runs, via-IR) diverge, warn in the report that the numbers would differ there.
3. Resolve the gas policy, first match wins: (1) a policy the user named when invoking the skill; (2) the target repo's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo; (3) the shipped defaults in the tradeoffs skill. Its schema is `templates/gas-policy.md`. Also read the target's CLAUDE.md (if existant), README.md, TESTING.md (if existant) and GUIDELINES/CONTRIBUTING (if existant) for constraints. Apply the policy's hard constraints and report-only reclassifications (a storage-layout freeze makes packing report-only; an assembly-averse style makes ASM cards report-only), and carry its context weighting and noise threshold into Phase 5. Compatibility is frozen by default: unless the policy sets `allow-layout-changes` or `allow-abi-changes`, treat transforms that change storage layout or a `public`/`external` signature, event, or error (e.g. ST-03, ST-04, DEP-08, and ST-06 on upgradeable contracts) as report-only. Record which policy was used in the report.
4. Fix scope: the files the user named, otherwise the main contracts directory. List the files explicitly before starting.

## Phase 1: Baseline

1. Run the test suite once; if it fails, stop and report. When the user scopes the audit to specific contracts and nothing else in the repo imports them (verify with a grep), scope the baseline and validation to the target's test files plus a full compile instead of the whole suite, and record the narrowed validation in the report. Treat the grep as a heuristic: it misses interface-only calls, address casts, and re-exports, so when in doubt fall back to the full suite. In large repositories a full-suite run per candidate is prohibitive; a scoped and recorded validation is preferable to a skipped one.
2. Run `scripts/gas-baseline.sh <framework> <baseline-dir> <repo-root>`. Put the baseline dir in scratch space, never inside the repo. For Hardhat, when the detected `HARDHAT_GAS_TOGGLE` variable is not `REPORT_GAS`, pass it via `GAS_ENV` (e.g. `GAS_ENV=GAS`). If the baseline command fails, stop; without a baseline there is nothing to measure against.
3. From the baseline snapshot, rank the in-scope functions by measured cost (and call frequency where the reporter shows it). This ranking, not the catalog order, drives the scan in Phase 2: gas lives in a few hot functions, so look there first.
4. Note in-scope contracts with weak or missing test coverage; their findings can compile and pass tests but cannot be called measured, and must be labeled accordingly.

## Phase 2: Scan

1. Read `catalog/INDEX.md`.
2. Scan hottest-first: take the Phase 1 ranking and walk the catalog against the top functions before anything else, since that is where a matched technique repays most. Then sweep the remaining in-scope code against the full INDEX so nothing is missed. When a Detect hint matches or sounds slightly relevant, open the category file and check the card's full Preconditions before recording a candidate.
3. The catalog is the minimum scan set, not a ceiling and may be incomplete. If you see a real gas waste with no matching card, record it as an `uncarded` candidate; it earns a finding only by passing the same Phase 3 verify loop and Phase 5 challenge as any card. Never claim a saving from memory without measuring it. Flag survivors for a follow-up card via the reference-creator skill.
4. Record candidates as `{card ID or "uncarded", location, why it applies, estimated impact, kind after policy}`.
5. Advisory candidates (including any the policy reclassified to report-only) skip Phase 3 and go straight to the report.
6. Order the collected transform candidates for Phase 3 by expected value: hot paths and per-call savings before deploy-only and cold paths.

## Phase 3: Verify loop

Work on a dedicated branch (`gas/<scope>`). For each transform candidate, strictly one at a time:

1. Apply the minimal diff for this one card.
2. Compile, then run targeted tests: test files matching the contract name, plus any test file that imports or deploys the contract (grep the test directory). Failing tests mean either a bad application or a real behavior change; retry once, then revert and record.
3. Measure with `scripts/gas-compare.sh` against the baseline. Record the deployment/code-size delta alongside the runtime delta: bigger code is a real cost, and for internal-function libraries it lands in every consumer contract.
4. If the improvement is above the policy's noise threshold (default: single-digit gas per call, unless the policy sets otherwise; this default is a heuristic, not a measured bound), run the project's formatter and linter on the touched file, then commit as `gas: <CARD-ID> <file>: <summary> (<delta>)`. If the measurement is flat or a regression, revert and record. If a pre-commit hook fails for reasons unrelated to the change, record the hook's actual failure output and why it is unrelated in the report, then commit with `--no-verify`.
5. Every surviving change stays on the branch for explicit review; never present a survivor as settled. The merge decision is the team's for every finding.

After the last candidate, run the **full** suite once. If it fails, bisect the kept commits to find the interaction and drop the offender. Keep the loop serial: interleaved candidates corrupt gas attribution.

## Phase 4: Report

Fill `templates/report.md` and write it as `gas-report-<target>-<date>.md` to the location the user named, otherwise a `gas-reports/` directory inside the audited repo (created if absent), never this skill's repo. Keep it untracked: add `gas-reports/` to the audited repo's `.git/info/exclude`, or tell the user it must stay uncommitted. The report is the primary deliverable: hand the user its path explicitly at the end, never leave it only in scratch space. Findings are numbered `GAS-<H|M|L>-NN` (severity in the ID, numbered within each severity), ordered by severity. Include all four populations: applied-and-measured, team-decision, advisory, and rejected with their measured evidence.

Severity (impact axis):

- **High**: ≥500 gas per call on a hot user path, ≥5% of a function's cost, or ≥10k deploy gas on factory/clone-deployed contracts.
- **Medium**: 100–500 gas per call on regular paths.
- **Low**: <100 gas per call, admin or rare paths, deploy-only savings on one-off deployments.

## Phase 5: Tradeoff challenge

The optimizer MUST NOT grade its own work. Spawn a fresh-context agent (Agent tool). If your environment can route it to a different model or provider than the scanner, prefer that (e.g. Claude scans, a different provider runs such as openai or grok the adversarial tradeoff pass); otherwise a fresh context on the same model is fine as a last resort. Give it: the tradeoff rubric (`../solidity-gas-tradeoffs-analysis/SKILL.md`), the gas policy resolved in Phase 0, the draft report, and the diffs (`git show` of each kept commit). Its job is to argue against each finding first, then issue `recommend` / `team-decision` / `reject` verdicts, each with a price tag. Merge its verdicts and rationale into the report verbatim; do not soften them. For `reject`, revert that commit and move the finding to the rejected table with the analyzer's reason.

If no Agent tool is available (worst case), do the challenge in a separate pass: re-read `../solidity-gas-tradeoffs-analysis/SKILL.md`, adopt the skeptic role, and write the case against each finding before issuing any verdict.

## Deliverable

The filled report plus the work branch with one commit per surviving change. Humans decide what merges; the `team-decision` findings are the agenda for that review.
