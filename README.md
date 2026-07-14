# solidity-gas-optimizer

**Automated gas optimization for Solidity code.** Scans a target against a curated catalog of gas optimization techniques, applies and commits one candidate at a time, verifies the tests still pass, measures the real delta, and challenges each candidate with a fresh-context tradeoff analysis (cross-model challenge is on the roadmap).

For developers who already write Solidity.

The deliverable is an audit-style report plus a work branch to cherry-pick from.

Two sources of knowledge enrich the audit, kept apart with different purposes:

- A **catalog** (`skills/solidity-gas-optimizer/catalog/`) of gas optimization techniques, one card per technique, seeded from the RareSkills Book of Gas Optimization. Each card is a fact about Solidity and the EVM, free of opinion, so it holds for any project. Savings magnitudes on a card are source-claimed; every audit re-measures them on the target.
- A **gas policy** (`.claude/gas-policy.md`) per project: how much a saving is worth against readability or auditability is an opinion that differs by project, so the skills ship a minimal default for you to extend, the decision matrix in `skills/solidity-gas-tradeoffs-analysis/SKILL.md`.

## Prerequisites

- **Claude Code (or any agent tool with a skills directory).** A skill is a self-contained folder of instructions and scripts an agent loads on demand. See https://code.claude.com/docs/en/skills.
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

Phase 5 re-judges each finding's worth against the rubric and gas policy; it does not re-run tests or re-measure gas, it weighs the deltas Phase 3 already recorded.

Every finding ends with a verdict and a measured delta; humans decide every merge. By default the audit never applies a change that alters storage layout or the public ABI; those findings are report-only until a gas policy opts in.

| Verdict | Meaning |
|---|---|
| `recommend` | measured win with no real downside |
| `team-decision` | real win that carries a tradeoff; a human weighs it |
| `reject` | not worth the cost, or unsafe; reverted |

## Install and use

```sh
$ git clone https://github.com/gonzaotc/solidity-gas-optimizer-skill.git solidity-gas-optimizer && cd solidity-gas-optimizer
$ mkdir -p ~/.claude/skills
$ ln -s "$(pwd)/skills/"* ~/.claude/skills/
$ ls -l ~/.claude/skills/solidity-gas-*   # verify the three skills are linked
```

Installs all three skills globally for Claude Code: `solidity-gas-optimizer` (the audit), `solidity-gas-tradeoffs-analysis` (the challenge), and `solidity-gas-reference-creator` (catalog upkeep). Each skill is a self-contained folder of Markdown and scripts, so any agent tool with a skills directory can use them by pointing at these folders, adapting the path to that tool's convention.

Then ask Claude Code:

> "Run a gas audit on `src/Vault.sol`."

The audit runs the tradeoffs challenge automatically as Phase 5; invoke `solidity-gas-tradeoffs-analysis` directly only to re-challenge an existing report.

You can also browse the catalog by asking, for example, "what gas techniques exist for storage?", and the agent reads the cards.

## Customizing the gas policy

We recommend customizing the gas policy to match your project's needs and conventions, both about gas and about what you are willing to trade for it, such as readability. Copy [`templates/gas-policy.md`](./skills/solidity-gas-optimizer/templates/gas-policy.md) to `.claude/gas-policy.md` and keep the parts that apply; each field is documented in place.

Some things you might tell it:

- "We don't use inline assembly." The audit then suggests assembly tricks but never applies them.
- "Don't touch our storage layout." Struct-packing shows up as a suggestion, not a change.
- "Every bit of gas counts." The audit stops discarding tiny savings as noise.

The skill resolves the policy in order: one you name when invoking it; otherwise the target's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo root; otherwise the shipped defaults, the decision matrix in `skills/solidity-gas-tradeoffs-analysis/SKILL.md`.

## Layout

```
skills/
├── solidity-gas-optimizer/       the audit skill
│   ├── SKILL.md                  the loop and its rules
│   ├── SOURCE-LOG.md             every source mined, with date and card outcome
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

`temp/` (source working copies) is gitignored scratch and never committed. Audit reports default to a `gas-reports/` directory inside the audited repo, not here.

## Contributing

To add a technique card, use the `solidity-gas-reference-creator` skill; [CONTRIBUTING.md](./CONTRIBUTING.md) covers the process, the by-hand path, and skill improvements.

## Roadmap

- Benchmark repo: a fixture codebase of known inefficiencies; comparing two runs' reports shows a PR's effect.
- Independent judge across providers: run the audit on Claude and the Phase 5 challenge on a different model, for genuine model diversity rather than fresh-context isolation. Likely an opt-in Bash seam (`GAS_CHALLENGE_CMD`) that passes the rubric, policy, report, and diffs to an external CLI and merges its verdicts back.

## Acknowledged sources

The catalog is seeded from public gas-optimization work. Full item-to-card coverage is mapped in [`catalog/SOURCES.md`](./skills/solidity-gas-optimizer/catalog/SOURCES.md).

- [RareSkills Book of Gas Optimization](https://www.rareskills.io/post/gas-optimization)
- [WTF-gas-optimization (WTF Academy)](https://github.com/WTFAcademy/WTF-gas-optimization)
- [kadenzipfel/gas-optimizations](https://github.com/kadenzipfel/gas-optimizations)
- [OpenZeppelin Forum: A Collection of Gas Optimisation Tricks](https://forum.openzeppelin.com/t/a-collection-of-gas-optimisation-tricks/19966)
