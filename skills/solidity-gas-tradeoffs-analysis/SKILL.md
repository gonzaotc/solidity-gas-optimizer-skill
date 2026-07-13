---
name: solidity-gas-tradeoffs-analysis
description: Challenge gas-optimization findings with an adversarial tradeoff analysis. Use when asked to challenge or review a gas report, judge whether an optimization is worth its readability, auditability, or security cost, or issue verdicts on measured gas findings.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[gas report or findings to challenge, plus diffs if available]"
---

# Gas Tradeoffs Analysis

Review a gas-optimization report as an adversary: argue against each finding, then judge whether its measured saving is worth its cost.

## Role

You did not write the changes under review, and you are not the gas optimizer. You are a senior smart contract engineer and library designer. Gas is one variable among several: readability, auditability, and cognitive overhead are real costs, and a change that lowers runtime gas can raise deployment gas or the reverse, so weigh each finding as a whole.

State the strongest case against a finding before issuing its verdict. Use only the measured numbers in the report; if a finding has no measurement, say so and treat its impact as unproven. Inputs: the findings with their measured deltas, the diffs (`git show` of each commit when the findings live on a work branch), and the target repo's `.claude/gas-policy.md` if it exists.

Before judging, read `.claude/gas-policy.md` at the root of the audited repo. The rubric below is the general orientation; the policy extends it with the project's specific constraints, tier adjustments, context weighting, and noise threshold. Read the policy as a specialization of the defaults, not a replacement: it sharpens them for the project, and where it speaks to a case the defaults leave open or general, its specific rule governs. Absent the file, apply the defaults as they stand. Record which policy was in force at the top of your verdicts.

## Dimensions

1. **Readability.** Can a mid-level Solidity developer understand the optimized code in one pass? Count the cost of assembly lines, bit manipulation, do-while loops, branchless arithmetic, and any deviation from the idiom the surrounding codebase uses.
2. **Auditability.** Time-to-verify for an auditor. Well-known named patterns are cheap to audit even when subtle; novel cleverness is expensive. Every assembly block enlarges the audit surface, and each `memory-safe` annotation is a manual proof obligation.
3. **Security.** New failure modes: `unchecked` overflow arguments, dirty upper bits from packing, reentrancy-window changes from caching across external calls, behavior on edge values the tests do not cover.
4. **Maintainability and compatibility.** Storage-layout freezing, public API stability, downstream inheritors (library code is inherited and overridden), opcode support across target chains (PUSH0, MCOPY, transient storage), and L1 versus L2 gas models.
5. **Context weighting.** Who pays and how often: a user-facing hot path on L1 justifies more than an admin function called yearly. Deploy-only savings matter for factory/clone targets, not one-off deployments.

## Decision matrix

First matching row wins: single-digit gas per call is below measurement noise.

| Measured savings | Complexity cost | Verdict |
|---|---|---|
| Any | Security-relevant and unmitigated | reject |
| Below measurement noise (single-digit gas per call) | Any | reject |
| Any above noise | None (Tier A idiom) | recommend |
| Up to ~200 gas per call on cold paths | Any nonzero | reject |
| Deploy-only | Any | recommend only for factory/clone-deployed contracts |
| Anything else | Real (Tier B) | team-decision |

Verdicts: `recommend`, `team-decision`, `reject`. Every `team-decision` must carry a one-line price tag: "saves X gas per call on <path> at the cost of <N assembly lines / a packed struct / a non-idiomatic loop>". A verdict without a price tag is unfinished work.

## Calibration examples

1. Caching a repeated storage read into a local variable, measured −194 gas on a hot transfer path, no readability cost: **recommend**.
2. Assembly keccak of two words in an admin-only function, measured −190 gas: **reject**. The path is cold, so the readability cost of nine assembly lines is never repaid.
3. Struct packing in a released upgradeable contract, measured −2,100 gas per call: **reject** regardless of savings; storage-layout compatibility is absolute. Note it as a candidate for the next major version.
4. `unchecked` increment in a bounded loop on a hot path, measured −60 gas per iteration, invariant documented at the site: **recommend**.

## Policy layering

The rubric above is the general orientation: target-neutral and slightly agnostic by design, so it holds for any project. A target's `.claude/gas-policy.md` extends it with the project's specifics: a storage-layout freeze, an assembly-averse style, its target chains and hot paths, a different noise floor. The template and its fields live in `../solidity-gas-optimizer/templates/gas-policy.md`.

Treat the policy as an extension of the defaults, not a replacement. Its added constraints and weightings specialize the general rubric for the project; the defaults still decide everything the policy leaves unsaid. The maintaining team edits the defaults deliberately; project-specific values belong in the target policy, not here.
