# solidity-gas-optimizer

**Automated gas optimization for Solidity code.** Scans against a curated catalog, commits one candidate at a time, verifies the tests pass, measures the real delta, and challenges each with an adversarial tradeoff analysis. The deliverable is an audit-style report plus a work branch for humans to cherry-pick from. Every candidate is decided by the project's own tests and measurements, not the model's judgment.

## Prerequisites

- **Foundry or Hardhat.** For Foundry, `forge` on PATH (`forge snapshot` is preferred when both are present); for Hardhat, `hardhat-gas-reporter` installed, which covers only the functions the tests exercise.
- **A green test suite with good coverage of the target code.** The baseline must pass before any change, and thin coverage lets an optimization alter behavior without failing a test, risking silent bugs.

## How a run works

| Phase | What happens | Stops when |
|-------|--------------|------------|
| 0 Discover | Detect toolchain, compiler settings, gas policy | Cannot measure |
| 1 Baseline | Full test suite + gas snapshot | Tests red |
| 2 Scan | Walk code against `references/INDEX.md` | |
| 3 Verify | One candidate per commit: targeted tests, measure, keep or revert | |
| 4 Report | Severity-ranked report with measured deltas, negatives included | |
| 5 Challenge | Fresh-context analyzer argues against every finding | |

Every finding ends with a verdict (`recommend` / `team-decision` / `reject`) and a measured delta; humans decide every merge. Tiers gate what the skill may attempt: A = no cost, B = real tradeoff, C = never applied.

## Install and use

```sh
$ git clone <this repo>
$ ln -s "$(pwd)/solidity-gas-optimizer/skills/"* ~/.claude/skills/
```

Installs the three skills globally. To scope them to one project, copy the folders into its `.claude/skills/` instead, keeping `solidity-gas-optimizer` and `solidity-gas-tradeoffs-analysis` together, since the challenge reads the latter from its sibling directory. Then ask Claude Code:

> "Run a gas audit on `src/Vault.sol`."
> "Is packing this struct worth the readability cost?"
> "Challenge the findings in `gas-report-vault-2026-07-09.md`."

## Layout

```
skills/
├── solidity-gas-optimizer/       the audit skill
│   ├── SKILL.md                  the loop and its rules
│   ├── references/               technique catalog (INDEX.md, SOURCES.md, cards)
│   ├── templates/report.md       report skeleton
│   └── scripts/                  detection, baseline, compare
├── solidity-gas-tradeoffs-analysis/
│   └── SKILL.md                  adversarial challenge; org policy on tradeoffs
└── solidity-gas-reference-creator/
    ├── SKILL.md                  contributes cards: dedup, route, write, validate
    ├── references/card-spec.md   card schema, routing tree, rules
    └── scripts/                  index generation + validation (PR gate)
```

## Contributing

To add a technique card, use the `solidity-gas-reference-creator` skill; [CONTRIBUTING.md](./CONTRIBUTING.md) covers the process, the by-hand path, and skill improvements.

## Provenance

Seed catalog distilled (paraphrased, cited per card) from the [RareSkills Book of Gas Optimization](https://www.rareskills.io/post/gas-optimization), with post-2023 EVM changes annotated.

## Roadmap

- Benchmark repo: a fixture codebase of known inefficiencies; comparing two runs' reports shows a PR's effect.
