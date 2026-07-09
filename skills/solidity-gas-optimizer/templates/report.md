# Gas Optimization Report — {{scope}}

| | |
|---|---|
| Repo | {{repo}} @ {{commit}} |
| Scope | {{files}} |
| Date | {{date}} |
| Toolchain | {{framework}}, solc {{version}}, optimizer runs {{runs}}, via-IR {{bool}} |
| Baseline | tests green @ {{commit}}, snapshot {{path}} |
| Work branch | {{branch}} |
| Active policy | {{repo gas policy constraints, or "defaults"}} |

## Summary

| ID | Technique | Location | Severity | Δ gas (measured) | Tests | Verdict |
|----|-----------|----------|----------|------------------|-------|---------|

Severity is impact (High/Medium/Low per the skill rubric). Verdict comes from the tradeoff analysis, never from the optimizer pass.

## Findings

### GAS-01 · {{title}} ({{card-id}})

- **Severity**: {{H/M/L}}
- **Location**: {{file:line}}
- **Measured**: {{before}} → {{after}} ({{delta}}) via {{method}}
- **Tests**: {{targeted suites run}}; full suite {{status}}; touched lines covered: {{yes/no}}
- **Change**: {{commit ref or diff summary}}
- **Tradeoff analysis**: {{verdict}} — {{analyzer rationale, verbatim}}

## Advisory findings

Design-level opportunities that cannot be applied as a local diff. Estimates, not measurements.

| Card | Suggestion | Est. impact | Cost / consideration |
|------|------------|-------------|-----------------------|

## Rejected candidates

Measured no-gain, regressions, broken tests, or tradeoff-analyzer rejections. Kept so the next run does not repeat them.

| Card | Location | Result | Note |
|------|----------|--------|------|

## Methodology

Baseline and deltas measured with {{tool}}. Numbers are valid only for the compiler settings above. {{hardhat caveat: reporter tables only cover functions the tests exercise, if applicable}}
