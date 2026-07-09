# solidity-gas-optimizer

A skill that runs measured gas-optimization audits on Solidity code: scan against a curated techniques catalog, apply candidates one commit at a time, verify tests, measure the real delta, and then challenge every survivor with an adversarial tradeoff analysis. The deliverable is an audit-style report plus a work branch; humans decide what merges.

Idiomatic Solidity is the default. An optimization must pay for its complexity.

## Prerequisites

The skill only reports measured numbers, so it refuses to run when it cannot measure:

- **A supported toolchain**: Foundry or Hardhat are supported.
  - Foundry: `forge` on PATH. `forge snapshot` is the measurement tool, and is preferred when both frameworks are present.
  - Hardhat: `hardhat-gas-reporter` installed (plus `node_modules`). The reporter only covers functions the tests exercise.
- **A green test suite.** The baseline must pass before any change is attempted.

No toolchain or no gas reporter stops the run at discovery. A red baseline stops it before any code is touched.

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
git clone <this repo>
ln -s "$(pwd)/solidity-gas-optimizer/skills/solidity-gas-optimizer" ~/.claude/skills/solidity-gas-optimizer
```

Or copy `skills/solidity-gas-optimizer/` into a project's `.claude/skills/`. Then ask Claude Code: "run a gas audit on `src/Vault.sol`".

## Layout

```
skills/solidity-gas-optimizer/
├── SKILL.md              the loop and its rules
├── references/           technique catalog (data): INDEX.md always loaded, category files on demand
├── rubrics/tradeoffs.md  what the org values over raw gas (policy)
├── templates/report.md   report skeleton
└── scripts/              toolchain detection, baseline, compare, catalog validation
```

## Maintenance

- `references/` is data: add techniques per [CONTRIBUTING.md](./CONTRIBUTING.md); IDs are append-only; `scripts/validate-references.sh` gates PRs.
- `rubrics/tradeoffs.md` is policy: the maintaining team edits it to encode judgment.
- Reports are decisions: humans accept or reject each priced finding.

## Provenance

Seed catalog distilled (paraphrased, cited per card) from the [RareSkills Book of Gas Optimization](https://www.rareskills.io/post/gas-optimization), with post-2023 EVM changes annotated where they affect a technique's validity.

## Roadmap

`gas-reference-creator` skill (dedup + card authoring + PR), CI on the validator, plugin packaging.
