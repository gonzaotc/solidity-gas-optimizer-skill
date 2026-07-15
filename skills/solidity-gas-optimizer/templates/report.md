<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

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

Each ID encodes severity (`H`/`M`/`L` per the skill rubric) and links to its finding below. Verdict comes from the Phase 5 tradeoff analysis; when that ran in the same context rather than a fresh-context agent, mark the verdict `self-reviewed`.

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

_Evidence: {{targeted suites run}}; full suite {{status}}; touched lines covered (agent-asserted, not tool-measured): {{yes/no}}; commit {{ref}}._

## Advisory findings

Design-level opportunities that cannot be applied as a local diff. Estimates, not measurements.

| Card | Suggestion | Est. impact | Cost / consideration |
|------|------------|-------------|-----------------------|

## Coverage-gap candidates

Real optimization candidates that could not be measured because no test exercises their code. These were never measured, so they are not rejections. Each is an estimate, and each doubles as a coverage signal: unmeasurable hot code is under-tested code. **Add the tests below and re-run the audit** to turn these into measured findings.

Ordered by estimated impact (highest first).

| Card | Location | Est. impact (estimate) | Tests needed to measure |
|------|----------|------------------------|-------------------------|

## Rejected candidates

Measured no-gain, regressions, broken tests, or tradeoff-analyzer rejections. Candidates that were never measurable belong in the coverage-gap section above, not here.

| Card | Location | Result | Note |
|------|----------|--------|------|
