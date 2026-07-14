# CLAUDE.md: solidity-gas-optimizer

Three Claude skills and a technique catalog for measured gas-optimization audits. The rules below bind every session in this repo, not just skill invocations; read them before editing the catalog.

## Hard rules

1. `skills/solidity-gas-optimizer/catalog/INDEX.md` is generated. Never edit it by hand; edit the cards and run `skills/solidity-gas-reference-creator/scripts/build-index.sh`.
2. Card IDs are append-only: never renumber, reuse, or reorder. Retired IDs stay recorded in `SOURCES.md` so they are never reassigned.
3. Every card follows the schema in `skills/solidity-gas-reference-creator/references/card-spec.md`, and `skills/solidity-gas-reference-creator/scripts/validate-references.sh` must pass before committing any change to the catalog (`skills/solidity-gas-optimizer/catalog/`).
4. Stay faithful to the source. Keep a card's wording, values, and code examples as close to the source as possible; quoting or copying verbatim is fine and preferred over inventing equivalents. Attribution (the card's `Source` field, `SOURCES.md`) is good-will credit, not a requirement: a card built from a pasted snippet with no known source is valid.
5. `SOURCES.md` is an optional attribution and coverage aid: keep it in sync when you choose to use it, and keep retired IDs recorded there so they are never reassigned. When you systematically mine a named source, log it in `skills/solidity-gas-optimizer/catalog/SOURCE-LOG.md` whatever the outcome (pull date and new-card result), so a dry source is never re-mined blindly. The README "Acknowledged sources" list and `SOURCES.md` credit only sources that produced at least one original card; the source log records every source mined. This does not make attribution mandatory (rule 4): a pasted snippet with no source needs no entry anywhere.
6. `skills/solidity-gas-tradeoffs-analysis/SKILL.md` holds the target-neutral default rubric; keep it generic. It is policy: change it deliberately, never as a side effect of another edit. Project-specific values do not go here; they belong in an audited repo's gas policy (`.claude/gas-policy.md` or a root `gas-policy.md`), whose schema is `skills/solidity-gas-optimizer/templates/gas-policy.md`.

## Where things live

- Audit loop and rules: `skills/solidity-gas-optimizer/SKILL.md`
- Default tradeoff rubric: `skills/solidity-gas-tradeoffs-analysis/SKILL.md`
- Target policy schema (copied into an audited repo's `.claude/gas-policy.md` or a root `gas-policy.md`): `skills/solidity-gas-optimizer/templates/gas-policy.md`
- Card schema and routing tree: `skills/solidity-gas-reference-creator/references/card-spec.md`
- Log of every mined source (all outcomes): `skills/solidity-gas-optimizer/catalog/SOURCE-LOG.md`
- Contribution process: `CONTRIBUTING.md`
