<!-- PR body for a measured gas-optimization audit. Fill placeholders, delete
     rows/sections that don't apply, keep it concise.
     Title: "{{target}} gas optimization (AI-generated)"
     Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

> [!NOTE]
> **AI-generated** with the [Solidity Gas Optimizer skill](https://github.com/gonzaotc/solidity-gas-optimizer-skill). Findings were measured as positive gains and all tests still pass, but it's encouraged to review before merging to confirm behavior is unaffected.

| Measurement | Scope | Tests |
|---|---|---|
| {{framework}}, solc {{ver}}, runs {{runs}}, via-IR {{bool}} | {{file count and roots, e.g. "12 files across src/multisig/"}} | {{suite}} suite, {{T}} passing |

<!-- Scope cell: the one-line summary of the report's confirmed Phase 0 scope tree (all
     files examined), never narrowed to the file a finding touched. When the full set is
     more than a handful of files, reproduce the report's Scope tree below this table so
     the exact set is in the PR too. Folders fully in scope collapse to the folder; a
     partially included folder lists its in-scope files individually. -->

{{N}} independent gas optimization candidates were found, one commit each and keyed by the IDs below. It's recommended to review them one by one, via the [commits view]({{commits-url}}).

<!-- Keep the line above to one or two lines: candidate count plus at most one sentence
     of takeaway. Do NOT add a separate audit-summary or editorializing paragraph here
     (e.g. "the path is close to idiomatic-optimal", "micro-tricks measured flat and were
     dropped"). That analysis belongs in the report, not the PR body. -->


| ID | Change | Function | Δ runtime /call | Δ deploy gas |
|----|--------|----------|-----------------|--------------|
| {{GAS-x-NN}} | {{change}} | {{fn}} | {{±N}} | {{±N}} |
| | **{{group}} subtotal** | | **{{±N}}** | **{{±N}}** |

<!-- Use the report's finding IDs (GAS-H/M/L-NN) so each change is discussable and
     matches its commit message. Group rows by struct/consumer when their deploy
     costs are independent, with a subtotal per group. The per-group subtotals are
     the real per-call figures; don't sum runtime across groups when no single call
     spans them. -->

<!-- One self-contained section per change, keyed by ID, so a reviewer can judge it
     in place without cross-referencing. Three lines each. Keep the mechanism concrete
     (the SLOAD/branch/opcode removed, not just "it's faster") and the tradeoff honest
     (payback, size cost, any invariant a reader must now hold, cherry-pick independence). -->

#### {{GAS-x-NN}} · {{change}} (`{{fn}}`)
- **What it does:** {{the concrete edit.}}
- **Why it's cheaper:** {{the mechanism: which read/branch/opcode is removed and why the saving follows; note the safety argument if behavior-adjacent.}}
- **Tradeoff:** {{payback vs. deploy-gas cost, any implicit invariant now relied on, whether it cherry-picks independently, or "none (safe idiom)" when there is no real cost.}}

{{attribution line}}
