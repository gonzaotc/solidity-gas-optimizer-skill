# Contributing

The catalog lives in `skills/solidity-gas-optimizer/references/`: one file per category, one card per technique. Cards are data; keep opinions in `rubrics/tradeoffs.md`.

## Adding a technique

1. **Dedup first.** Search `references/INDEX.md` for your technique's keywords, then read the category file the routing tree (below) points to. If a card already covers the mechanism, improve that card instead of adding one.
2. **Route it.** First match wins:
   1. Fundamentally unsafe, deprecated, or no longer effective → `forbidden.md` (FBD)
   2. Only affects deployment cost → `deployment.md` (DEP)
   3. Requires inline assembly / Yul → `assembly.md` (ASM)
   4. Changes system design: which contracts, standards, or layers exist → `architecture.md` (ARC)
   5. Changes how contracts call each other → `external-calls.md` (XC)
   6. Reduces storage reads/writes or slot count → `storage.md` (ST)
   7. Reduces calldata size or cost → `calldata.md` (CD)
   8. Anything else (local codegen/execution) → `execution.md` (EXE)
3. **Take the next free number** in that file. IDs are append-only: never renumber, reuse, or reorder. Reports reference IDs forever.
4. **Fill every field** of the schema below.
5. **Update `INDEX.md`** with the card's one-line row. If the technique is distilled from a published source, add the mapping to `SOURCES.md`.
6. **Run `scripts/validate-references.sh`.** It gates PRs.

Note on the seed catalog: cards distilled from the RareSkills article keep the article's ordering inside each category, so a few sit where the tree would not file them today (e.g. a Tier C card under `deployment.md`). Tier, not file location, gates application. The tree governs new additions.

## Card schema

```markdown
## <PREFIX>-<NN> · <Short imperative name>
- **Kind**: transform | advisory
- **Tier**: A | B | C
- **Detect**: <concrete code patterns to look for; greppable cues when possible>
- **Transform**: <the exact change; for advisory cards, the design recommendation>
- **Savings**: <magnitude and the EVM/opcode mechanism producing it>
- **Preconditions**: <when it actually works: optimizer settings, value ranges, context>
- **Risks**: <semantic changes, security implications, readability cost; "none" only if truly none>
- **Source**: <publication and item, or "original contribution">
```

Rules:

- **Kind.** `transform` = mechanically applicable as a local diff, verifiable by tests and measurement. `advisory` = design decision; reported, never auto-applied.
- **Tier.** A cost prior for the optimizer, not a merge permission (humans decide every merge). `A` = no meaningful readability/auditability/security cost; applied and kept on the work branch when it measures an improvement. `B` = real tradeoff; flagged for explicit team review. `C` = never applied; security hazards, deprecated mechanics, API or storage-layout breakers.
- **Stay current.** If a technique's validity changed with an EVM upgrade or compiler version, the card must say so in Risks with the EIP or solc version. A card that overstates savings is worse than no card.
- **Paraphrase.** Never copy text or code from a source verbatim; write original minimal examples and cite the source in the Source field.
- Cards are self-contained (no "see card X") and at most ~18 lines.

## Roadmap: gas-reference-creator skill

This process is the spec for a future skill that automates it: take a technique description, dedup against INDEX.md, route it with the tree, write the card, validate, open a PR.
