---
name: solidity-gas-reference-creator
description: Add a technique card to the solidity-gas-optimizer reference catalog. Use when asked to contribute a gas-optimization technique, add a reference card, distill an article or code-review observation into the catalog, save or record or remember a gas trick for later, or add a gas optimization to the shared catalog. Refuses duplicates; if the mechanism is already carded, it reports the existing card instead.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
argument-hint: "[technique description: the change, why it saves gas, and the source publication if any]"
---

# Gas Reference Creator

Turn a technique description into a validated card. `references/card-spec.md` is the authoritative spec for the schema, routing tree, and catalog rules; this skill automates the process and enforces its gates. Paths below are relative to this skill's directory; the catalog is `../solidity-gas-optimizer/catalog/`.

## Non-negotiables

1. One card per mechanism; if the catalog already covers it, stop and report the duplicate.
2. IDs are append-only: take the next free number in the target file; never renumber, reuse, or reorder. Reports cite IDs forever.
3. Stay faithful to the source: keep wording, values, and examples close to it; copying verbatim is fine. Crediting the source (the `Source` field, `SOURCES.md`) is optional good-will.
4. The contribution is done only when `scripts/validate-references.sh` passes.

## Steps

1. **Read the spec.** Read `references/card-spec.md` in full: schema, routing tree, kind rules.
2. **Deduplicate.** State the mechanism in one sentence: the EVM or compiler behavior that produces the saving, not the technique's name. Search `INDEX.md` for its keywords, then read every related category file.
   - If an existing card covers the same mechanism, stop. Report the card ID, the overlap in one sentence ("duplicate of ST-02: both cache storage reads to avoid repeated SLOADs"), and what the new material adds. If it adds a precondition, risk, or updated measurement, edit the existing card (no new ID) and continue at step 6. Otherwise continue.
3. **Route and number.** Walk the routing tree top to bottom; first match wins. Take the next free ID in that category file.
4. **Write the card.** Fill every schema field, following the spec's rules on kind, hint, currency, and length.
5. **Update the catalog files.**
   - Regenerate the index: run `scripts/build-index.sh`, which rewrites `INDEX.md` from the cards.
   - Optionally credit the source in the card's `Source` field; omit it for pasted material with no known source. Cross-catalog recording is covered under Mining a whole source below.
6. **Validate.** Run `scripts/validate-references.sh`. Fix every violation; if the card cannot satisfy the schema, revert every file touched and report why.

## Mining a whole source

Mining a named source (article, repo, or thread) runs the steps above zero or more times; most items are duplicates. After enumerating and deduping the whole source, record it:

- **Always**, even when the source produced no card: add one row to `../solidity-gas-optimizer/catalog/SOURCE-LOG.md` with the pull date, the count and IDs of new cards, and a one-line outcome. This stops a dry source from being blindly re-mined, so it runs on the all-duplicate path too.
- **Only when the source produced at least one original card**: record its item-to-card mapping in `SOURCES.md` (with `Pulled: YYYY-MM-DD`, so a later revision can be diffed) and, for a public source, add a line under "Acknowledged sources" in the top-level README. Sources that added no card stay out of both.

This applies to systematic mining; a one-off pasted technique with no named source needs none of it (attribution stays optional, non-negotiable 3).

## Deliverable

The changed files (`<category>.md`, `INDEX.md`, plus `SOURCE-LOG.md` and `SOURCES.md` when a source was mined), a passing validator, and a short summary: the card's ID, its routing rationale, and the dedup evidence (which cards were checked, why they miss the mechanism). A rejected duplicate ships the overlap report instead.
