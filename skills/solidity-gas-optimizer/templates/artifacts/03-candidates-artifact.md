<!-- 03-candidates.md: one row per candidate, the run's conservation record.
     Written in Phase 3 (state = candidate), advanced in Phase 4 (state, measured
     delta), finalized in Phases 5-6 (classification). The classifications and the
     conservation rules live in `SKILL.md` (Phases 3-6); this is only the row shape.
     Style: no dashes as sentence connectors. -->

| candidate id | card | location | expensive resource | redundant operation | semantic constraint | why it applies | estimated impact | kind | coverage | state | measured delta | classification |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| {{short id, also in the raising inventory row}} | {{card ID or `uncarded`}} | {{where}} | {{class wasted}} | {{what the fix removes}} | {{what the fix must preserve}} | {{one line}} | {{magnitude class, never a precise figure}} | {{transform | advisory}} | {{exercised | none}} | {{candidate → measured result}} | {{runtime and deploy, Phase 4}} | {{one of the six, Phase 5-6}} |

The `(location, expensive resource, redundant operation, semantic constraint)` tuple is the dedup key.
