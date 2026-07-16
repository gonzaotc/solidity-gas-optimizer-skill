# Contributing

Two kinds of contributions are welcomed: technique references for the catalog, and skill improvements.

## Adding a technique reference

Use the `solidity-gas-reference-creator` skill (installed by the README's steps): describe the technique or paste a snippet. It deduplicates against the catalog, routes and numbers the card, regenerates `INDEX.md`, and runs the validator. It refuses a mechanism already carded, reporting the existing card. Naming a source is optional; when given, it records the mapping in `SOURCES.md` and logs a whole-source mining pass in `SOURCE-LOG.md`.

To contribute by hand, follow the schema and routing tree in [`card-spec.md`](./skills/solidity-gas-reference-creator/references/card-spec.md) and regenerate the index with `skills/solidity-gas-reference-creator/scripts/build-index.sh`. Either way, `skills/solidity-gas-reference-creator/scripts/validate-references.sh` gates PRs, failing on duplicate card IDs, a prefix mismatching its file, a card missing any schema field, or a stale `INDEX.md`.

## Improving a skill

Edit the skill's files directly and open a PR:

- `skills/solidity-gas-optimizer/` — the audit loop, its rules, and the measurement scripts.
- `skills/solidity-gas-tradeoffs-analysis/SKILL.md` — policy: what the organization values over raw gas.
- `skills/solidity-gas-reference-creator/` — the contribution flow and the card spec.

Keep instructions imperative with the reason attached, and run a full audit against a sample repo when changing the loop's phases or rules.
