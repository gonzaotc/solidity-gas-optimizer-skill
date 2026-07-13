# solidity-gas-optimizer

**Automated gas optimization for Solidity code.** A skill that scans Solidity code against a curated catalog of gas-optimization techniques, identifies and commits optimization candidates one commit at a time, verifies the test suite passes, measures the real delta, and challenges every candidate with an adversarial tradeoff analysis. The deliverable is an audit-style report plus a work branch from which humans cherry-pick changes.

The (measure->scan->optimize->validate->measure->commit->challenge) loop is what makes this task a good fit for AI automation: every candidate is decided by the project's own tests and measurements, not by the model's judgment. The verification and tradeoff analysis cut the time an engineer spends identifying and validating optimization opportunities.

## Prerequisites

- **A supported gas-measuring toolchain**: Foundry or Hardhat.
  - Foundry: `forge` on PATH. `forge snapshot` is the measurement tool, and is preferred when both frameworks are present.
  - Hardhat: `hardhat-gas-reporter` installed (plus `node_modules`). The reporter only covers functions the tests exercise.
- **A green test suite.** The baseline must pass before any change is attempted.
- **Good coverage of the target code.** Without thorough tests, an optimization can change behavior without any test failing, so weakly covered code risks silent bugs.

## How a run works

| Phase | What happens | Stops when |
|-------|--------------|------------|
| 0 Discover | Detect toolchain, compiler settings, repo gas policy | Cannot measure |
| 1 Baseline | Full test suite + gas snapshot | Tests red |
| 2 Scan | Walk code against `references/INDEX.md` | |
| 3 Verify | One candidate per commit: targeted tests → measure → keep or revert | |
| 4 Report | Severity-ranked report with measured deltas, negative results included | |
| 5 Challenge | Fresh-context tradeoff analyzer argues against every finding | |

Every finding ends with a tradeoff verdict (`recommend` / `team-decision` / `reject`) and a measured delta; humans decide every merge. Tiers only gate what the skill may attempt during the run: A = no complexity cost, B = real tradeoff, C = never applied.

## Install and use

```sh
$ git clone <this repo>
$ ln -s "$(pwd)/solidity-gas-optimizer/skills/"* ~/.claude/skills/
```

Installs the three skills globally, for every project. To scope them to one project, copy the skill folders into that project's `.claude/skills/` instead; keep `solidity-gas-optimizer` and `solidity-gas-tradeoffs-analysis` together, since the audit's tradeoff challenge reads the tradeoffs skill from its sibling directory. Then just ask Claude Code:

> "Run a gas audit on `src/Vault.sol`."
> "Is packing this struct worth the readability cost?"
> "Challenge the findings in `gas-report-vault-2026-07-09.md`."
> "Add this technique to the gas catalog: (description and source)."

The first two run the audit and tradeoffs skills; the last two invoke `solidity-gas-tradeoffs-analysis` and `solidity-gas-reference-creator` directly.

## Layout

```
skills/
├── solidity-gas-optimizer/       the audit skill
│   ├── SKILL.md                  the loop and its rules
│   ├── references/               technique catalog (data)
│   │   ├── INDEX.md              scan checklist, generated from the cards by build-index.sh; read in full at scan time
│   │   ├── SOURCES.md            coverage map: every item of a distilled publication mapped to its card
│   │   └── <category>.md         full cards per category (storage, execution, ...), opened when a detect hint matches
│   ├── templates/report.md       report skeleton
│   └── scripts/                  toolchain detection, baseline, compare
├── solidity-gas-tradeoffs-analysis/
│   └── SKILL.md                  adversarial challenge of gas findings; what the org values over raw gas (policy)
└── solidity-gas-reference-creator/
    ├── SKILL.md                  contributes catalog cards: dedup, route, write, validate
    ├── references/card-spec.md   card schema, routing tree, catalog rules
    └── scripts/                  index generation + catalog validation (PR gate)
```

## Contributing

To add a technique card, use the `solidity-gas-reference-creator` skill; [CONTRIBUTING.md](./CONTRIBUTING.md) covers the process, the by-hand path, and skill improvements.

## Provenance

Seed catalog distilled (paraphrased, cited per card) from the [RareSkills Book of Gas Optimization](https://www.rareskills.io/post/gas-optimization), with post-2023 EVM changes annotated where they affect a technique's validity.

## Roadmap

- Benchmark repo: a fixture codebase seeded with known inefficiencies to run the skills against. Comparing the reports of two runs shows the effect of a PR: techniques gained, lost, or misjudged.
