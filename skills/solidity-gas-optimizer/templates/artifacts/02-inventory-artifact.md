<!-- 02-inventory.md: the resource inventory, the scan's work list. Written in Phase 2,
     its pass column filled in Phase 3. Enumeration only: raw resource facts, never a
     judgment about waste. Every in-scope function is enumerated equally, one row per
     resource site; a function with no notable site still gets one row so it is
     accounted for. Style: no dashes as sentence connectors. -->

| site | class | multiplicity | completed passes | candidate IDs | coverage |
|------|-------|--------------|------------------|---------------|----------|
| {{`contract.function` + line/block}} | {{one or more classes, below}} | {{fixed count / loop bound / call count / per-call}} | {{blank at Phase 2}} | {{blank at Phase 2}} | {{exercised | none}} |

**class** is one or more of: storage-read (SLOAD), storage-write (SSTORE), external call (CALL/STATICCALL), delegatecall (DELEGATECALL), value-bearing call, contract creation (CREATE/CREATE2), loop/control, calldata/memory copy, returndata copy, hashing (KECCAK256), event/log (LOG), revert-data construction, deploy/code-size.

`coverage` is a heuristic from the baseline gas report: a function it lists is `exercised`; a public or external function absent from it is `none`. An internal function has no report line, so mark it `exercised` when an exercised caller reaches it, never a hard `none`. Phase 4 measurement is the authoritative check. In Phase 3 every row gets at least a catalog match and closes with a candidate or a recorded no-candidate reason; the resource-flow and lifecycle passes run where the row's facts warrant. `candidate IDs` may stay empty.
