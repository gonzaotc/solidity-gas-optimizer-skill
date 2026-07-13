# Card spec

The authoritative spec for catalog cards: routing, IDs, and the schema. The catalog lives in `skills/solidity-gas-optimizer/references/`: one file per category, one card per technique. Cards are data; keep opinions in `skills/solidity-gas-tradeoffs-analysis/SKILL.md`.

## Routing

Route a new card to its category file; first match wins:

1. Fundamentally unsafe, deprecated, or no longer effective → `forbidden.md` (FBD)
2. Only affects deployment cost → `deployment.md` (DEP)
3. Requires inline assembly / Yul → `assembly.md` (ASM)
4. Changes system design: which contracts, standards, or layers exist → `architecture.md` (ARC)
5. Changes how contracts call each other → `external-calls.md` (XC)
6. Reduces storage reads/writes or slot count → `storage.md` (ST)
7. Reduces calldata size or cost → `calldata.md` (CD)
8. Anything else (local codegen/execution) → `execution.md` (EXE)

Take the next free number in that file. IDs are append-only: never renumber, reuse, or reorder. Reports reference IDs forever.

Each category file opens with a one-paragraph description of what the category covers; its first sentence becomes the category's row in the index, so keep that sentence self-contained.

Note on the seed catalog: cards distilled from the RareSkills article keep the article's ordering inside each category, so a few sit where the tree would not file them today (e.g. an advisory card under `deployment.md`). Kind, not file location, gates application. The tree governs new additions.

## Schema

```markdown
## <PREFIX>-<NN> · <Short imperative name>
- **Kind**: transform | advisory
- **Detect**: <concrete code patterns to look for; greppable cues when possible>
- **Hint**: <the Detect field compressed to one short line; becomes the card's row in the technique index>
- **Transform**: <the exact change; for advisory cards, the design recommendation>
- **Savings**: <magnitude and the EVM/opcode mechanism producing it>
- **Preconditions**: <when it actually works: optimizer settings, value ranges, context>
- **Risks**: <semantic changes, security implications, readability cost; "none" only if truly none>
- **Source**: <publication and item, or "original contribution">
```

Rules:

- **Kind.** `transform` = mechanically applicable as a local diff, verifiable by tests and measurement; enters the verify loop and the Phase 5 challenge. `advisory` = reported as a labeled estimate, never auto-applied. Use `advisory` for design-level changes that are not a local diff, and for techniques that must not be applied mechanically: security hazards, deprecated mechanics, API or storage-layout breakers, and contest-only cleverness.
- **Hint.** One short line, since the whole index is read at scan time. `INDEX.md` is generated from the cards by `scripts/build-index.sh`; never edit it by hand.
- **Stay current.** If a technique's validity changed with an EVM upgrade or compiler version, the card must say so in Risks with the EIP or solc version. A card that overstates savings is worse than no card.
- **Paraphrase.** Never copy text or code from a source verbatim; write original minimal examples and cite the source in the Source field.
- Cards are self-contained (no "see card X") and at most ~18 lines.
