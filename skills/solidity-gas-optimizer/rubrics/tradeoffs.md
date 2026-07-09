# Tradeoff rubric

How to challenge gas findings. Used by the tradeoff analyzer in a fresh context, after the optimizer pass has measured everything. The burden of proof is on the optimization, not on the status quo. Idiomatic Solidity is the default; if raw gas were the only value, the code would be written in Huff or raw Yul.

## Role

You are not the optimizer and you did not write these changes. For each finding, state the strongest case against it first. Only then issue a verdict. Use only the measured numbers in the report; if a finding has no measurement, say so and treat its impact as unproven.

## Dimensions

1. **Readability.** Can a mid-level Solidity developer understand the optimized code in one pass? Count the cost of assembly lines, bit tricks, do-while loops, branchless arithmetic, and any deviation from the idiom the surrounding codebase uses.
2. **Auditability.** Time-to-verify for an auditor. Well-known named patterns are cheap to audit even when subtle; novel cleverness is expensive. Every assembly block enlarges the audit surface, and each `memory-safe` annotation is a manual proof obligation.
3. **Security.** New failure modes: `unchecked` overflow arguments, dirty upper bits from packing, reentrancy-window changes from caching across external calls, behavior on edge values the tests do not cover.
4. **Maintainability and compatibility.** Storage-layout freezing, public API stability, downstream inheritors (library code is inherited and overridden), opcode support across target chains (PUSH0, MCOPY, transient storage), and L1 versus L2 gas models.
5. **Context weighting.** Who pays and how often: a user-facing hot path on L1 justifies more than an admin function called yearly. Deploy-only savings matter for factory/clone targets, not one-off deployments.

## Decision matrix

| Measured savings | Complexity cost | Verdict |
|---|---|---|
| Any | Security-relevant and unmitigated | reject |
| Below noise (~50 gas/call) | Any nonzero | reject |
| Small (50–200 gas/call) on cold paths | Any nonzero | reject |
| Meaningful on hot paths | None (Tier A idiom) | recommend |
| Meaningful on hot paths | Real (Tier B) | team-decision |
| Deploy-only | Any | recommend only for factory/clone-deployed contracts |

Verdicts: `recommend`, `team-decision`, `reject`. Every `team-decision` must carry a one-line price tag: "saves X gas per call on <path> at the cost of <N assembly lines / a packed struct / a non-idiomatic loop>". A verdict without a price tag is unfinished work.

## Calibration examples

1. Caching a repeated storage read into a local variable, measured −194 gas on a hot transfer path, no readability cost: **recommend**.
2. Assembly keccak of two words in an admin-only function, measured −190 gas: **reject**. Cold path; nine lines of assembly buy nothing anyone pays for.
3. Struct packing in a released upgradeable contract, measured −2 100 gas per call: **reject** regardless of savings; storage-layout compatibility is absolute. Note it as a candidate for the next major version.
4. `unchecked` increment in a bounded loop on a hot path, measured −60 gas per iteration, invariant documented at the site: **recommend**.

## Org policy

This file is policy, not data: the maintaining team edits it to encode what the organization values over raw gas. A target repo's `.claude/gas-policy.md` overrides this file where they conflict.
