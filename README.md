# solidity-gas-optimizer

A Claude Code skill that turns a curated catalog of Solidity gas-optimization techniques into measured, audit-style reports. It scans code against the catalog, applies candidate optimizations one commit at a time, verifies tests still pass, measures the real delta with the project's own toolchain (Foundry or Hardhat), and then challenges every surviving change with an adversarial tradeoff analysis before anything reaches a human.

Idiomatic Solidity is the default. An optimization must pay for its complexity. If gas were the only value, we would not be writing Solidity.

## How a run works

| Phase | What happens | Gate |
|-------|--------------|------|
| 0 Discover | Detect Foundry/Hardhat, compiler settings, repo gas policy | No toolchain → stop |
| 1 Baseline | Full test suite + gas snapshot | Red suite → stop |
| 2 Scan | Walk code against `references/INDEX.md` (84 techniques, 8 categories) | |
| 3 Verify | One candidate per commit: targeted tests → measure → keep or revert | Flat or regression → revert and log |
| 4 Report | Audit-style report: severity-ranked, measured deltas, negative results included | |
| 5 Challenge | Fresh-context tradeoff analyzer argues against every finding, issues verdicts | `reject` → reverted |

The deliverable is a report plus a work branch with one commit per surviving change. Tier B findings ship as `team-decision` with a measured price tag; humans decide what merges.

## Install

```sh
git clone <this repo>
ln -s "$(pwd)/solidity-gas-optimizer/skills/solidity-gas-optimizer" ~/.claude/skills/solidity-gas-optimizer
```

Or copy `skills/solidity-gas-optimizer/` into a project's `.claude/skills/`.

## Use

Ask Claude Code things like "run a gas audit on `src/Vault.sol`", "gas-optimize the token contracts", or "is this assembly block worth it".

## Layout

```
skills/solidity-gas-optimizer/
├── SKILL.md              the loop and its rules
├── references/           the technique catalog (data; team and community maintained)
│   ├── INDEX.md          one line per technique; the only file always loaded
│   └── <category>.md     full cards, loaded on demand
├── rubrics/tradeoffs.md  what the org values over raw gas (policy)
├── templates/report.md   audit-style report skeleton
└── scripts/              toolchain detection, baseline, compare, catalog validation
```

## Maintenance model

- **`references/` is data.** Anyone can add a technique; see [CONTRIBUTING.md](./CONTRIBUTING.md). IDs are append-only and `scripts/validate-references.sh` gates PRs.
- **`rubrics/tradeoffs.md` is policy.** The maintaining team edits it to encode judgment: when assembly is acceptable, what counts as noise, who pays the gas.
- **Reports are decisions.** The tradeoff analyzer prices each finding; humans accept or reject.

## Provenance

The seed catalog is distilled from the [RareSkills Book of Gas Optimization](https://www.rareskills.io/post/gas-optimization): paraphrased and restructured, not copied, with every card citing its source item. Cards note where post-2023 EVM changes (EIP-6780, Dencun/EIP-4844, EIP-7623, PUSH0) affect a technique's validity.

## Roadmap

- `gas-reference-creator` skill: guided card authoring with dedup against INDEX.md, schema validation, and PR creation
- CI running `validate-references.sh` on every PR
- Claude Code plugin packaging
