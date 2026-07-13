# solidity-gas-optimizer

**Automated gas optimization for Solidity code.** Scans a target against a curated catalog of gas optimization techniques, applies and commits one candidate at a time, verifies the tests still pass, measures the real delta, and challenges each candidate with an adversarial tradeoff analysis.

The deliverable is an audit-style report plus a work branch to cherry-pick from.

Two sources of knowledge enrich the audit, kept apart with different purposes:

- A **catalog** (`catalog/`) of gas optimization techniques: an open, community-driven database, one card per technique. Each card is a fact about Solidity and the EVM, free of opinion, so it holds for any project.
- A **gas policy** (`.claude/gas-policy.md`) per project: how much a saving is worth against readability or auditability is an opinion that differs by project, so the skills ship a minimal default for you to extend.

## Prerequisites

- **A gas measuring tool: Foundry or Hardhat.** For Foundry, `forge` on PATH (`forge snapshot` is preferred when both are present); for Hardhat, `hardhat-gas-reporter` installed, which covers only the functions the tests exercise.
- **A thorough passing test suite.** Thin coverage lets an optimization alter behavior without failing a test, risking silent bugs.

## How a run works

| Phase | What happens |
|-------|--------------|
| 0 Discover | Detect toolchain, compiler settings, gas policy |
| 1 Baseline | Full test suite + gas snapshot |
| 2 Scan | Scan code against `catalog/INDEX.md` |
| 3 Verify | One candidate per commit: apply the change, run tests, measure, keep or revert |
| 4 Report | Severity-ranked report with measured deltas, negatives included |
| 5 Challenge | Fresh-context analyzer argues against every finding |

Every finding ends with a verdict and a measured delta; humans decide every merge.

| Verdict | Meaning |
|---|---|
| `recommend` | measured win with no real downside |
| `team-decision` | real win that carries a tradeoff; a human weighs it |
| `reject` | not worth the cost, or unsafe; reverted |

## Install and use

```sh
$ git clone <this repo>
$ ln -s "$(pwd)/solidity-gas-optimizer/skills/"* ~/.claude/skills/
```

Installs all three skills globally for Claude Code: `solidity-gas-optimizer` (the audit), `solidity-gas-tradeoffs-analysis` (the challenge), and `solidity-gas-reference-creator` (catalog upkeep). Each skill is a self-contained folder of Markdown and scripts, so any agent tool with a skills directory can use them by pointing at these folders, adapting the path to that tool's convention.

Then ask Claude Code:

> "Run a gas audit on `src/Vault.sol`."

## Customizing the gas policy

We recommend customizing the gas policy to match your project's needs and conventions, both about gas and about what you are willing to trade for it, such as readability. Copy [`templates/gas-policy.md`](./skills/solidity-gas-optimizer/templates/gas-policy.md) to `.claude/gas-policy.md` and keep the parts that apply; each field is documented in place.

Some things you might tell it:

- "We don't use inline assembly." The audit then suggests assembly tricks but never applies them.
- "Don't touch our storage layout." Struct-packing shows up as a suggestion, not a change.
- "Every bit of gas counts." The audit stops discarding tiny savings as noise.

The skill resolves the policy in order: one you name when invoking it; otherwise the target's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo root; otherwise the shipped defaults.

## Layout

```
skills/
├── solidity-gas-optimizer/       the audit skill
│   ├── SKILL.md                  the loop and its rules
│   ├── catalog/                  technique catalog (INDEX.md, SOURCES.md, cards)
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
- Independent judge across providers: run the audit on Claude and the Phase 5 challenge on a different model, for genuine model diversity rather than fresh-context isolation. Likely an opt-in Bash seam (`GAS_CHALLENGE_CMD`) that passes the rubric, policy, report, and diffs to an external CLI and merges its verdicts back.
