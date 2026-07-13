# solidity-gas-optimizer

**Automated gas optimization for Solidity code.** 

Scans the target against a curated open source gas optimization techniques catalog, implements the optimizations, commits one candidate at a time, verifies the tests pass, measures the real delta, and challenges each optimization candidate with an adversarial tradeoff analysis. 

The deliverable is an audit-style report plus a work branch for humans to cherry-pick from. Every candidate is decided by the target project's own tests and measurements, not the model's judgment.

## Prerequisites

- **Foundry or Hardhat.** For Foundry, `forge` on PATH (`forge snapshot` is preferred when both are present); for Hardhat, `hardhat-gas-reporter` installed, which covers only the functions the tests exercise.
- **A thorough passing test suite.** Thin coverage lets an optimization alter behavior without failing a test, risking silent bugs.

## How a run works

| Phase | What happens |
|-------|--------------|
| 0 Discover | Detect toolchain, compiler settings, gas policy |
| 1 Baseline | Full test suite + gas snapshot |
| 2 Scan | Walk code against `references/INDEX.md` |
| 3 Verify | One candidate per commit: targeted tests, measure, keep or revert |
| 4 Report | Severity-ranked report with measured deltas, negatives included |
| 5 Challenge | Fresh-context analyzer argues against every finding |

Every finding ends with a verdict (`recommend` / `team-decision` / `reject`) and a measured delta; humans decide every merge.

## Install and use

```sh
$ git clone <this repo>
$ ln -s "$(pwd)/solidity-gas-optimizer/skills/"* ~/.claude/skills/
```

Installs all three skills globally: `solidity-gas-optimizer` (the audit), `solidity-gas-tradeoffs-analysis` (the challenge), and `solidity-gas-reference-creator` (catalog upkeep). Each skill is a self-contained folder of Markdown and scripts, so any agent tool with a skills directory can use them by pointing at these folders, adapting the path to that tool's convention.

Then ask Claude Code:

> "Run a gas audit on `src/Vault.sol`."

## Target policy

Each project values an optimization against readability differently, so the tradeoff is a per-project call. The skills ship target-neutral defaults; a project extends them with a `.claude/gas-policy.md` at its repo root.

The policy states hard constraints (storage-layout freeze, API stability, assembly-restricted paths), catalog techniques the project keeps report-only, the target chains and hot paths that weight the analysis, and the measurement-noise threshold. Copy [`skills/solidity-gas-optimizer/templates/gas-policy.md`](./skills/solidity-gas-optimizer/templates/gas-policy.md) to `.claude/gas-policy.md` and delete what does not apply; each field is documented in place.

## Layout

```
skills/
├── solidity-gas-optimizer/       the audit skill
│   ├── SKILL.md                  the loop and its rules
│   ├── references/               technique catalog (INDEX.md, SOURCES.md, cards)
│   ├── templates/                report skeleton + gas-policy template
│   └── scripts/                  detection, baseline, compare
├── solidity-gas-tradeoffs-analysis/
│   └── SKILL.md                  adversarial challenge; default tradeoff rubric
└── solidity-gas-reference-creator/
    ├── SKILL.md                  contributes cards: dedup, route, write, validate
    ├── references/card-spec.md   card schema, routing tree, rules
    └── scripts/                  index generation + validation (PR gate)
```

## Contributing

To add a technique card, use the `solidity-gas-reference-creator` skill; [CONTRIBUTING.md](./CONTRIBUTING.md) covers the process, the by-hand path, and skill improvements.

## Roadmap

- Benchmark repo: a fixture codebase of known inefficiencies; comparing two runs' reports shows a PR's effect.
- Independent judge across providers: run the audit on Claude and the Phase 5 tradeoff challenge on a different model, for genuine model diversity rather than fresh-context isolation. Likely mechanism is a Bash seam (`GAS_CHALLENGE_CMD`, e.g. `codex exec` / `llm` / `openai`) that feeds the rubric, policy, report, and diffs to the external CLI and merges its verdicts back, with the report recording which model audited and which judged. External judge stays opt-in; absent config, Phase 5 is unchanged.
