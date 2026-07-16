<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

# Gas Optimization Report: {{scope}}

| | |
|---|---|
| Repo | {{repo}} @ {{commit}} |
| Scope | {{file count and roots, e.g. "12 files across src/multisig/"; full tree in the Scope section}} |
| Date | {{date}} |
| Toolchain | {{framework}}, solc {{version}}, optimizer runs {{runs}}, via-IR {{bool}} |
| Baseline | tests green @ {{commit}}, snapshot {{path}} |
| Work branch | {{branch}} |
| Active policy | {{resolved gas policy: the path used, or "defaults"}} |

## Scope

The exact files audited, confirmed with the user in Phase 0. Folders fully in scope are collapsed to the folder; a partially included folder lists its in-scope files individually.

```
{{IDE-style file tree of the confirmed scope}}
```

## Summary

| ID | Candidate ID | Technique (card) | Location | Δ gas (measured) | Tests | Verdict |
|----|--------------|------------------|----------|------------------|-------|---------|
| [GAS-H-01](#gas-h-01) | | | | | | |

Each ID encodes severity (`H`/`M`/`L` per the skill rubric) and links to its finding below. `Candidate ID` is the identity that traces the entry back through the discovery funnel to the site that raised it; `Technique (card)` is the catalog card that matched, provenance only, or `uncarded`. Verdict comes from the Phase 6 tradeoff analysis; when that ran in the same context rather than a fresh-context agent, mark the verdict `self-reviewed`.

## Discovery funnel

Every candidate raised in the scan is accounted for. At each transition, candidates in equals candidates passed on plus candidates exiting to a classification here. If any row does not balance, a candidate vanished: reconcile before trusting the findings below. Competing transforms for one waste count as separate candidates (kept apart at dedup), so three transforms for a single waste are three candidates in.

| Transition | In | Passed on | Exited here | Classification of exits |
|---|---|---|---|---|
| Scan → dedup | | | | — |
| Dedup → policy/coverage routing | | | | duplicate |
| Routing → application | | | | advisory (design-level, policy-blocked), coverage-gap (known from baseline gas report) |
| Application → measurement | | | | rejected (compile failure, broke targeted tests) |
| Measurement → integration | | | | rejected (regression, flat, below noise floor), coverage-gap (discovered missing) |
| Integration → challenge | | | | rejected (integration) |
| Challenge → report | | | | rejected (challenge), rejected (superseded), kept, team-decision |

Candidates raised: {{n}}. Sum of classifications (kept + team-decision + advisory + coverage-gap + rejected + duplicate): {{n}}. These must be equal.

## Findings

Each finding reads top to bottom: what the code does, why it can be optimized, the proposed change, the reason to hold back, and a recommendation for this context. The header carries the measured facts; the evidence line records how the change was verified. IDs run `GAS-<H|M|L>-NN`, numbered within each severity; give every finding an `<a id="gas-<h|m|l>-NN">` anchor matching its Summary link.

<a id="gas-h-01"></a>
### GAS-H-01 · {{title}}

`{{file:line}}` · candidate {{candidate-id}} · card {{card-id or "uncarded"}} · **{{before}} → {{after}} ({{delta}})** measured via {{method}}

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

## Advisory entries

Estimated opportunities the run does not apply, so they are not findings. Two kinds live here: design-level suggestions that no local diff expresses, and local transforms a hard policy constraint forbids (a layout or ABI freeze, an assembly-averse style). The second kind is a real, applicable diff held back by policy, not by non-locality; note the blocking constraint and frame it as "you would save this if the constraint were lifted."

| Candidate ID | Card | Suggestion | Est. impact | Blocked by / consideration |
|--------------|------|------------|-------------|----------------------------|

## Coverage-gap candidates

Real optimization candidates that could not be measured because no test exercises their code. These were never measured, so they are not rejections. Each is an estimate, and each doubles as a coverage signal: unmeasurable hot code is under-tested code. **Add the tests below and re-run the audit** to turn these into measured findings.

Ordered by estimated impact (highest first).

| Candidate ID | Card | Location | Est. impact (estimate) | Tests needed to measure |
|--------------|------|----------|------------------------|-------------------------|

## Rejected candidates

Candidates that were measured and did not earn a keep, or were rejected downstream. Some carry a measured number (`flat`, `regression`, `below noise floor`); others fail before a number exists (`compile failure`, `broke targeted tests`, `integration`) or are rejected on judgment (`challenge`, `superseded by <id>`), so the Result column reads `no measured number` for those. Candidates that were never measurable belong in the coverage-gap section above, not here.

| Candidate ID | Card | Location | Reason | Result | Note |
|--------------|------|----------|--------|--------|------|
