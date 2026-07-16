<!-- meta.json: the run manifest. Written in Phase 0, read by every later phase.
     `scope` is the confirmed exact file set, the scope of record: every later phase
     reads the in-scope set from here, never from context. -->

```json
{
  "framework": "foundry | hardhat",
  "measure_with": "foundry | hardhat",
  "solc": { "version": "", "optimizer_runs": 0, "via_ir": false },
  "policy": "<resolved gas-policy path, or \"defaults\">",
  "scope": ["<exact in-scope file path>", "..."],
  "base_commit": "<git sha the audit branched from>",
  "date": "<YYYY-MM-DD>"
}
```
