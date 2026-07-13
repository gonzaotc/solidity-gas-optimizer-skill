# Gas policy: {{project}}

What this project values over raw gas. The gas-optimizer and tradeoff-analysis skills read it as an extension of their defaults: every section is optional, and anything left empty keeps the default behavior.

## Hard constraints

Absolute rejects, regardless of measured savings. State the rule, then the reason. Typical entries: storage-layout freeze on released or upgradeable contracts, public/external API and event/error stability, paths where inline assembly is disallowed.

## Report-only techniques

Catalog techniques this project never wants applied mechanically, only reported. The left column matches an ID or category prefix from `references/INDEX.md` (`ST`, `ASM`, `ST-03`, ...).

| Technique / category | Reason |
|----------------------|--------|

## Context weighting

What the analyzer uses to judge whether a saving is worth its cost: the target chains (and opcode availability that gates cards, e.g. PUSH0, MCOPY, transient storage), who pays and how often, the hot paths of record, and whether deployment is one-off or factory/clone-heavy.

## Thresholds

Measurement noise: gas deltas at or below this are treated as zero. Default is single-digit gas per call; raise it for a project that tolerates more churn.
