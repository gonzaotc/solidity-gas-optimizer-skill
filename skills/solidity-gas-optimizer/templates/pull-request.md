<!-- PR body for a measured gas-optimization audit. Fill placeholders, delete
     rows/sections that don't apply, keep it concise.
     Title: "{{target}} gas optimization" (the AI-generated note banner below carries the attribution; keep it out of the title)
     Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

> [!NOTE]
> **AI-generated** with the [Solidity Gas Optimizer skill](https://github.com/gonzaotc/solidity-gas-optimizer-skill). Findings were measured as positive gains and all tests still pass, but it's encouraged to review before merging to confirm behavior is unaffected.

<!-- Vertical field/value table (HTML so the Scope row can hold the tree). The Scope
     row holds only the tree: the confirmed Phase 0 scope set (all files examined),
     never narrowed to the file a finding touched. Folders fully in scope collapse to
     the folder; a partially included folder lists its in-scope files individually.
     The Tests row states explicitly which suite ran: the full project suite or the
     target-scoped subset, with pass counts, so a reader knows the breadth of validation. -->

<table>
<tr><td><b>Measurement</b></td><td>{{framework}}, solc {{ver}}, runs {{runs}}, via-IR {{bool}}</td></tr>
<tr><td><b>Scope</b></td><td>
<pre>
{{IDE-style scope tree of the confirmed set}}
</pre></td></tr>
<tr><td><b>Tests</b></td><td>{{explicit suite: full project suite or the target-scoped subset, with pass counts, e.g. "Full project suite: 681 passing (115 exercising the target)" or "Target-scoped: 115 passing"}}</td></tr>
</table>

{{count spelled as a word, e.g. "Two"}} independent gas optimization candidates were found, one commit each and keyed by the IDs below. It's recommended to review them one by one, via the [commits view]({{this PR's commits page, e.g. https://github.com/<owner>/<repo>/pull/<n>/commits}}).

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
