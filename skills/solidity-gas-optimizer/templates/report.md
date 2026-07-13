# Gas Optimization Report: {{scope}}

| | |
|---|---|
| Repo | {{repo}} @ {{commit}} |
| Scope | {{files}} |
| Date | {{date}} |
| Toolchain | {{framework}}, solc {{version}}, optimizer runs {{runs}}, via-IR {{bool}} |
| Baseline | tests green @ {{commit}}, snapshot {{path}} |
| Work branch | {{branch}} |
| Active policy | {{resolved gas policy: the path used, or "defaults"}} |

## Summary

| ID | Technique | Location | Δ gas (measured) | Tests | Verdict |
|----|-----------|----------|------------------|-------|---------|
| [GAS-H-01](#gas-h-01) | | | | | |

Each ID encodes severity (`H`/`M`/`L` per the skill rubric) and links to its finding below. Verdict comes from the tradeoff analysis, never from the optimizer pass.

## Findings

Each finding reads top to bottom: what the code does, why it can be optimized, the proposed change, the reason to hold back, and a recommendation for this context. The header carries the measured facts; the evidence line records how the change was verified. IDs run `GAS-<H|M|L>-NN`, numbered within each severity; give every finding an `<a id="gas-<h|m|l>-NN">` anchor matching its Summary link.

<a id="gas-h-01"></a>
### GAS-H-01 · {{title}} ({{card-id}})

`{{file:line}}` · **{{before}} → {{after}} ({{delta}})** measured via {{method}}

**What the code does.** {{Plain description of the function or block under review and its role.}}

**How it can be optimized.** {{The inefficiency or the technique that applies, and the mechanism by which it saves gas.}}

**Proposed implementation change.**

```solidity
{{The actual change: before/after or the diff. Real code, not a description.}}
```

{{One line on what changed and why the saving follows.}}

**Why you might not.** {{The cost: readability, auditability, security, maintainability, or compatibility. For a safe idiom with no meaningful cost, say so.}}

**Recommendation.** {{recommend / team-decision / reject}} for this context. {{Analyzer rationale, verbatim.}}

_Evidence: {{targeted suites run}}; full suite {{status}}; touched lines covered: {{yes/no}}; commit {{ref}}._

## Advisory findings

Design-level opportunities that cannot be applied as a local diff. Estimates, not measurements.

| Card | Suggestion | Est. impact | Cost / consideration |
|------|------------|-------------|-----------------------|

## Rejected candidates

Measured no-gain, regressions, broken tests, or tradeoff-analyzer rejections. 

| Card | Location | Result | Note |
|------|----------|--------|------|
