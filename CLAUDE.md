# CLAUDE.md: solidity-gas-optimizer

Three Claude skills and a technique catalog for measured gas-optimization audits. The rules below bind every session in this repo, not just skill invocations; read them before editing the catalog.

## Hard rules

1. `skills/solidity-gas-optimizer/references/INDEX.md` is generated. Never edit it by hand; edit the cards and run `skills/solidity-gas-reference-creator/scripts/build-index.sh`.
2. Card IDs are append-only: never renumber, reuse, or reorder. Retired IDs stay recorded in `SOURCES.md` so they are never reassigned.
3. Every card follows the schema in `skills/solidity-gas-reference-creator/references/card-spec.md`, and `skills/solidity-gas-reference-creator/scripts/validate-references.sh` must pass before committing any change to the catalog (`skills/solidity-gas-optimizer/references/`).
4. Paraphrase. Never copy text or code verbatim from a source into a card; cite the source in the card's Source field.
5. Every item distilled from a publication maps to exactly one card or a recorded omission in `SOURCES.md`. Keep that file in sync when adding or removing cards.
6. `skills/solidity-gas-tradeoffs-analysis/SKILL.md` is policy: it encodes what the organization values over raw gas. Change it deliberately, never as a side effect of another edit.

## Where things live

- Audit loop and rules: `skills/solidity-gas-optimizer/SKILL.md`
- Card schema and routing tree: `skills/solidity-gas-reference-creator/references/card-spec.md`
- Contribution process: `CONTRIBUTING.md`
