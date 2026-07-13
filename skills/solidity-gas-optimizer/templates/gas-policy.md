# Gas policy: {{project}}

Copy this file to `.claude/gas-policy.md` at the root of the audited repository. The gas-optimizer and tradeoff-analysis skills read it as an extension of their built-in defaults: the defaults give general orientation, and the rules here add your project's specifics on top. Absent this file, the skills use their defaults on their own.

Every section is optional. Delete what does not apply; the skills treat an empty or missing section as leaving the defaults in place.

## Hard constraints

Absolute rejects, regardless of measured savings. State the rule, then the reason.

- Storage layout is frozen for released and upgradeable contracts. Any layout change is rejected and noted as a next-major-version candidate.
- Public and external signatures, events, and errors are stable across a major version.
- Inline assembly is allowed only under {{vetted paths, e.g. `contracts/utils/`}}; elsewhere it is rejected.

## Tier adjustments

Promote or demote catalog techniques for this project. The left column matches an ID or category prefix from `references/INDEX.md` (`ST`, `ASM`, `ST-03`, ...). For a listed technique, this tier applies in place of the card's default.

| Technique / category | Tier | Reason |
|----------------------|------|--------|
| ST-03, ST-04 | C | storage-layout freeze forbids repacking |
| ASM | C | assembly-averse house style |

## Context weighting

What the analyzer uses to judge whether a saving is worth its cost.

- **Target chains**: {{e.g. L1 mainnet, Arbitrum, Base}}. Note opcode availability that affects cards: PUSH0, MCOPY, transient storage.
- **Cost model**: who pays and how often. Name the hot paths of record: {{functions}}.
- **Deployment weight**: {{one-off deployment, or factory/clone-heavy}}. Deploy-only savings matter only for the latter.

## Thresholds

- **Measurement noise**: gas deltas at or below this are treated as zero. Default is single-digit gas per call; raise it for a project that tolerates more churn.
