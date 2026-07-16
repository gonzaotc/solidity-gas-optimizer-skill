---
name: solidity-gas-tradeoffs-analysis
description: Challenge gas-optimization findings with an adversarial tradeoff analysis. Use when asked to challenge a gas report or review whether a gas optimization is worth its readability, auditability, or security cost, or to issue recommend/team-decision/reject verdicts on measured gas findings. For running or re-running the audit itself, use solidity-gas-optimizer.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[gas report or findings to challenge, plus diffs if available]"
---

# Gas Tradeoffs Analysis

Review a gas-optimization report as an adversary: argue against each finding, then judge whether its measured saving is worth its cost.

## Role

You did not write the changes under review, and you are not the gas optimizer. You are a senior smart contract engineer and library designer. Gas is one variable among several; readability, auditability, and cognitive overhead are real costs, and a change lowering runtime gas can raise deployment gas or the reverse, so weigh each finding as a whole.

State the strongest case against a finding before its verdict. Use only the measured numbers; if a finding has no measurement, say so and treat its impact as unproven. Inputs: the findings with their measured deltas, the diffs (`git show` each commit when findings live on a work branch), and the gas policy in force.

Before judging, load the gas policy, first match wins: the policy the caller provides; otherwise the audited repo's `.claude/gas-policy.md`, then a `gas-policy.md` at the repo root; otherwise the defaults below. The policy extends the rubric with the project's specific constraints, report-only reclassifications, context weighting, and noise threshold; read it as a specialization, not a replacement. Where it speaks to a case, its specific rule governs; otherwise the defaults hold. Record which policy was in force at the top of your verdicts.

## Dimensions

1. **Readability.** Can a mid-level Solidity developer understand the optimized code in one pass? Count assembly lines, bit manipulation, do-while loops, branchless arithmetic, and any deviation from the surrounding idiom.
2. **Auditability.** Time-to-verify for an auditor. Well-known named patterns are cheap even when subtle; novel cleverness is expensive. Every assembly block enlarges the audit surface, and each `memory-safe` annotation is a manual proof obligation.
3. **Security.** New failure modes: `unchecked` overflow arguments, dirty upper bits from packing, reentrancy-window changes from caching across external calls, edge-value behavior the tests do not cover.
4. **Maintainability and compatibility.** Storage-layout freezing, public API stability, downstream inheritors (library code is inherited and overridden), opcode support across target chains (PUSH0, MCOPY, transient storage), L1 versus L2 gas models.
5. **Context weighting.** Who pays and how often: a user-facing hot path on L1 justifies more than an admin function called yearly. Deploy-only savings matter for factory/clone targets, not one-off deployments.

## Decision matrix

First matching row wins. These are target-neutral defaults; a policy sharpens them with its own thresholds and weighting, so never treat a cutoff as fixed. "Noise" is the policy's measurement-noise threshold, defaulting to 10 gas per call when the policy is silent. Never assume small savings are worthless: a library optimizing hot paths may set the threshold to zero so every measured saving counts.

| Measured savings | Complexity cost | Verdict |
|---|---|---|
| Any | Changes storage layout or a public/external signature without a policy opt-in | team-decision at most; reject when the contract is deployed or upgradeable |
| Any | Security-relevant and unmitigated | reject |
| At or below the noise threshold | Any | reject |
| Above the threshold | None (safe idiom) | recommend |
| Small relative to a cold or rare path | Any nonzero | team-decision |
| Deploy-only | Any | recommend only for factory/clone-deployed contracts |
| Anything else | Real | team-decision |

Verdicts: `recommend`, `team-decision`, `reject`. Every `team-decision` must carry a one-line price tag: "saves X gas per call on <path> at the cost of <N assembly lines / a packed struct / a non-idiomatic loop>". A verdict without a price tag is unfinished work.

## Calibration examples

These examples cite the catalog card that defines the transform and its preconditions. Assume every stated saving was measured under the target's compiler settings and exceeds the applicable noise threshold unless the example says otherwise.

1. **ST-02, repeated storage read.** A transfer function reads the same balance slot several times with no external call or intervening write, then caches it in a local. The measured saving is on a hot path and the code becomes no harder to read: **recommend**.
2. **CD-03, `memory` parameter changed to `calldata`.** An external function only reads a dynamic array, the selector is unchanged, and the contract is concrete rather than an inheritable base whose overrides may need a mutable copy. The eager memory copy disappears with no material complexity cost: **recommend**.
3. **EXE-07, bounded `unchecked` arithmetic.** A loop counter cannot reach `type(uint256).max`, the proof is documented at the increment, and the target compiler still emits a checked operation that measurement shows is material: **recommend**.
4. **EXE-11, reordered short-circuit checks.** A cheap, side-effect-free input check moves before an expensive storage read in an `&&` expression, production traffic usually fails the cheap check, and the ordering does not guard the second operand or change revert behavior: **recommend**.
5. **DEP-08, custom errors in a released interface.** Replacing revert strings saves deployment and revert gas, but existing tests and integrations match `Error(string)` payloads. **Team-decision**: "saves X deploy gas and Y gas per revert at the cost of changing the observable revert ABI."
6. **ST-09, bitmap for indexed claims.** An airdrop already assigns dense leaf indices, so 256 claim flags can share each storage word. OpenZeppelin `BitMaps` contains the bit arithmetic, but index assignment and the less direct representation remain. **Team-decision**: "saves X gas per claim at the cost of replacing an address-keyed bool mapping with an indexed bitmap."
7. **EXE-18, inlining a one-caller internal helper.** Measurement finds a saving and the function is not an override point, but its name documents a protocol step that would otherwise be embedded in a long caller. **Team-decision**: "saves X gas per call at the cost of removing a named abstraction."
8. **ST-04, struct-member reordering after deployment.** Repacking would save a storage slot, but the struct is persisted by a released upgradeable contract. The transform changes storage layout and corrupts existing state: **reject**, regardless of the measured saving.
9. **XC-04, caching across an external state change.** A function reads its token balance, calls the token to transfer funds, then reads the balance again. Reusing the first result would be cheaper but fails the card's stability precondition and changes observable behavior: **reject**.
10. **FBD-08, changing `public` to `external` for gas.** On supported Solidity versions the measured saving is zero because both visibilities use equivalent parameter handling. The change only churns the API and may remove valid internal calls: **reject**.

## Policy layering

A target's gas policy specializes the defaults with the project's specifics: a storage-layout freeze, an assembly-averse style, its target chains and hot paths, a different noise floor. The template and its fields live in `../solidity-gas-optimizer/templates/gas-policy.md`.

Compatibility is frozen by default: transforms changing storage layout or a public/external signature need an explicit policy opt-in (`allow-layout-changes`, `allow-abi-changes`) to be applied rather than reported.
