# Gas policy: {{project}}

We recommend and encourage customizing the gas policies according to your project needs and conventions. This file tells the gas-optimizer and tradeoff-analysis skills what your project cares about besides saving gas. Every section is optional. Leave one empty and the skills fall back to their defaults.

## Hard constraints

Things you never want changed, no matter how much gas it would save. Write the rule, then why. For example:

- Don't touch the storage layout: the contracts are already deployed and upgradeable.
- Don't change any `public`/`external` function signatures, events, or errors: other contracts and off-chain tools depend on them.
- No inline assembly in the `governance/` folder: it needs to stay easy to audit.

## Report-only techniques

Techniques you want flagged in the report but never applied automatically. Put the card ID or category prefix from `catalog/INDEX.md` in the left column (`ST`, `ASM`, `ST-03`, ...). For example:

| Technique / category | Reason |
|----------------------|--------|
| ASM | We avoid assembly unless a reviewer signs off first. |
| ST-03 | Reordering storage slots is risky on our upgradeable contracts. |

## Context weighting

Background the skills use to decide whether a saving is worth the cost. For example:

- Which chains you deploy to, and whether they support opcodes some cards need (PUSH0, MCOPY, transient storage).
- Who pays the gas and how often: end users on every call, or an admin once a week?
- The functions that run most often, where savings matter most.
- Whether you deploy a contract once, or spin up many via a factory or clones (which makes deployment cost matter more).

## Thresholds

The smallest gas saving worth reporting. Deltas at or below this are treated as noise and ignored. The default is single-digit gas per call. Set it to zero to count every saving (useful for a library where tiny wins on hot paths add up), or raise it if you don't want to hear about small changes.
