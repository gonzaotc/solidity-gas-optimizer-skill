<!-- PR body for a measured gas-optimization audit. Fill placeholders, delete
     rows/sections that don't apply, keep it concise.
     Title: "{{target}} gas optimization (AI-generated)" -->

> [!NOTE]
> **This PR was AI-generated.** The findings come from a measured, automated gas-optimization audit run with the [Solidity Gas Optimizer skill](https://github.com/gonzaotc/solidity-gas-optimizer-skill): every delta below was measured with this repo's own toolchain, validated against {{suite}} ({{N}} tests pass), and challenged by a separate adversarial review. Please review the changes before merging.

{{One short sentence: what changes, that behavior is unchanged, one commit per change.}}

**Measured under:** {{framework}}, solc {{ver}}, runs {{runs}}, via-IR {{bool}}.
**Δ runtime** = gas per call ({{reporter column}}). **Δ deploy gas** = one-time cost
when a consumer embedding this code is deployed (~200 gas per runtime byte; a
code-size proxy, not bytes).

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
- **Why it's cheaper:** {{the mechanism — which read/branch/opcode is removed and why the saving follows; note the safety argument if behavior-adjacent.}}
- **Tradeoff:** {{payback vs. deploy-gas cost, any implicit invariant now relied on, whether it cherry-picks independently, or "none — safe idiom" when there is no real cost.}}

{{attribution line}}
