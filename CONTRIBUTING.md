# Contributing

Two kinds of contributions are welcomed: new technique references for the catalog, and improvements to the skills themselves.

## Adding a technique reference

Use the `solidity-gas-reference-creator` skill (install it like the audit skill: symlink `skills/solidity-gas-reference-creator` into `~/.claude/skills/`): describe the technique and its source, and it deduplicates against the catalog, routes and numbers the card, regenerates `INDEX.md`, updates `SOURCES.md`, and runs the validator. It refuses a technique whose mechanism is already carded and reports the existing card instead.

To contribute by hand, follow the card schema and routing tree in [`skills/solidity-gas-reference-creator/references/card-spec.md`](./skills/solidity-gas-reference-creator/references/card-spec.md), and regenerate the index with `skills/solidity-gas-reference-creator/scripts/build-index.sh`. Either way, `skills/solidity-gas-reference-creator/scripts/validate-references.sh` gates PRs: it fails on duplicate card IDs, an ID whose prefix does not match its file, a card missing any schema field, or a stale `INDEX.md`.

## Improving a skill

Edit the skill's files directly and open a PR:

- `skills/solidity-gas-optimizer/` — the audit loop, its rules, and the measurement scripts.
- `skills/solidity-gas-tradeoffs-analysis/SKILL.md` — policy: edit it to change what the organization values over raw gas.
- `skills/solidity-gas-reference-creator/` — the contribution flow and the card spec.

Keep instructions imperative with the reason attached, and run a full audit against a sample repo when changing the loop's phases or rules.
