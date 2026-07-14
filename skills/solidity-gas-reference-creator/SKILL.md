---
name: solidity-gas-reference-creator
description: Add a technique card to the solidity-gas-optimizer reference catalog. Use when asked to contribute a gas-optimization technique, add a reference card, distill an article or code-review observation into the catalog, save or record or remember a gas trick for later, or add a gas optimization to the shared catalog. Refuses duplicates; if the mechanism is already carded, it reports the existing card instead.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
argument-hint: "[technique description: the change, why it saves gas, and the source publication if any]"
---

# Gas Reference Creator

Turn a technique description into a validated card in the reference catalog. `references/card-spec.md` is the authoritative spec for the card schema, the routing tree, and the catalog rules; this skill automates that process and enforces its gates. Paths below are relative to this skill's directory: the catalog lives in `../solidity-gas-optimizer/catalog/`.

## Non-negotiables

1. One card per mechanism. If the catalog already covers the technique's mechanism, do not add a card: stop and report the duplicate.
2. IDs are append-only. Take the next free number in the target file; never renumber, reuse, or reorder. Reports reference IDs forever.
3. Stay faithful to the source. Keep wording, values, and examples as close to the source as possible; copying verbatim is fine. Crediting the source (the `Source` field, `SOURCES.md`) is optional good-will, not required.
4. The contribution is done only when `scripts/validate-references.sh` passes.

## Steps

1. **Read the spec.** Read `references/card-spec.md` in full: card schema, routing tree, kind rules.
2. **Deduplicate.** State the technique's mechanism in one sentence: the EVM or compiler behavior that produces the saving, not the technique's name. Search `INDEX.md` for the mechanism's keywords, then read every category file with related cards.
   - If an existing card covers the same mechanism, stop. Report the card ID, the overlap in one sentence ("duplicate of ST-02: both cache storage reads to avoid repeated SLOADs"), and what, if anything, the new material adds. If it adds a precondition, risk, or updated measurement, apply that as an edit to the existing card (no new ID) and continue at step 6.
   - If the mechanism is new, continue.
3. **Route and number.** Walk the routing tree top to bottom; first match wins. Take the next free ID in that category file.
4. **Write the card.** Fill every field of the schema, following the spec's rules on kind, hint, currency, and length.
5. **Update the catalog files.**
   - Regenerate the index: run `scripts/build-index.sh`; it rewrites `INDEX.md` from the cards.
   - Optionally credit the author in the card's `Source` field; omit it when the material was pasted with no known source. Recording the source across the catalog (`SOURCE-LOG.md`, `SOURCES.md`, README) is covered under Mining a whole source below.
6. **Validate.** Run `scripts/validate-references.sh`. Fix every violation it reports; if the card cannot satisfy the schema, revert every file touched and report why.

## Mining a whole source

The steps above add one card per new mechanism. Mining a named source (an article, repo, or thread) runs them zero or more times: some items are new, most are usually duplicates. Whatever the outcome, once you finish enumerating and deduping the whole source, record it:

- **Always**, even for a source that produced no card: add one row to `../solidity-gas-optimizer/SOURCE-LOG.md` with the pull date, the count and IDs of any new cards, and a one-line outcome. This is what stops a dry source from being blindly re-mined, so it must run on the all-duplicate path too, not only when a card was added.
- **Only when the source produced at least one original card**: record its item-to-card mapping in `SOURCES.md` (with `Pulled: YYYY-MM-DD`, so a later revision can be diffed against what was carded) and, for a public source, add a line under "Acknowledged sources" in the top-level README. Sources that added no card stay out of both.

This applies to systematic source mining. A one-off pasted technique with no named source needs none of it; attribution stays optional per non-negotiable 3.

## Deliverable

The changed files (`<category>.md`, `INDEX.md`, plus `SOURCE-LOG.md` and `SOURCES.md` when a source was mined), a passing validator, and a short summary: the new card's ID, the routing rationale, and the dedup evidence (which cards were checked and why they do not cover the mechanism). For a rejected duplicate, the overlap report replaces the card.
