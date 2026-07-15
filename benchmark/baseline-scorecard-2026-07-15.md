<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->
<!-- HIDDEN grader artifact. Contains answer-key ceilings. Lives above fixtures/,
     never exposed to a producer run. -->

# Blessed baseline scorecard (v0)

Date: 2026-07-15
Status: in progress (producers running, grading as they land)

## Producer mechanism (held constant for any future paired comparison)

- Producer: blind `general-purpose` subagent, fresh context (never sees `answer-key.md`, `plan.md`, or this scorecard).
- Instruction: follow the real `skills/solidity-gas-optimizer/SKILL.md` + catalog + scripts, non-interactively, one tier per run.
- Model: inherited from the orchestrating session (Opus 4.8, 1M).
- Isolation: each tier copied alone into scratchpad (only its own contract + interface + a single-tier conformance test + symlinked `lib/forge-std`), own git root, so sibling tiers cannot leak the answer.
- Policy: `allow-abi-changes` (clean recall read, per the answer key's deploy caveat). Visibility flips (FBD-08) must never be applied regardless.
- Grader: this session (contaminated by the key, so it only grades, never produces). Re-measures every number with `forge test --gas-report`; producer-claimed gas is never transcribed.
- Phase 5: if the subagent cannot nest a fresh-context tradeoff agent, its self-reviewed pass is noted as degraded. Gas-gap closure comes from Phase 3 measurement, not Phase 5 verdicts.

Pinned settings: solc 0.8.30, optimizer on, runs 200, evm cancun, forge 1.5.1.

Closure formula (per function and for deployment):

```
closure = (tier_gas - grader_measured) / (tier_gas - good_gas)
```

Closure above 100% beat the Good tier: a true positive to fold into the key (unplanted-finding rule), never an error.

## Finding-count ladder (expected, monotone by construction)

| Standard | Bad | Medium | Good |
|---|---|---|---|
| ERC20 | 6 | 2 | 0 |
| AccessControl | 4 | 2 | 0 |

## ERC20

Ceilings from the key (`Good` is the target):

| Metric | Bad | Medium | Good (ceiling) |
|---|---|---|---|
| Deployment | 561521 | 415250 | 357100 |
| transfer (cold, max) | 51509 | 51325 | 51159 |
| transferFrom (cold, max) | 57681 | 57247 | 56981 |
| transferFrom (warm, min) | 26892 | 26832 | 24614 |
| approve (max, precision probe, ~flat) | 45959 | 45959 | 45958 |

### ERC20 Bad run

| Metric | Bad (tier) | Good (ceiling) | Grader-measured after | Closure |
|---|---|---|---|---|
| Deployment | 561521 | 357100 | _pending_ | _pending_ |
| transfer (cold, max) | 51509 | 51159 | _pending_ | _pending_ |
| transferFrom (cold, max) | 57681 | 56981 | _pending_ | _pending_ |
| transferFrom (warm, min) | 26892 | 24614 | _pending_ | _pending_ |
| approve (precision) | 45959 | 45958 | _pending_ | claims here must measure |

Techniques caught (diagnostic, does not feed closure): _pending_. Expected separators Bad→Good: ST-06, DEP-08/EXE-23, DEP-10, ST-02, EXE-07, DEP-02.

### ERC20 Medium run

_pending (fan out after Bad validates)_

## AccessControl

Ceilings from the key:

| Metric | Bad | Medium | Good (ceiling) |
|---|---|---|---|
| Deployment | 331802 | 251267 | 250398 |
| grantRole (cold, max) | 50960 | 50942 | 48705 |
| revokeRole (cold, max) | 29144 | 29115 | 26878 |
| renounceRole (precision probe, flat) | 24650 | 24649 | 24649 |

### AccessControl Bad run

_pending_

### AccessControl Medium run

_pending_

## PriceGuard (abstention)

Expected: abstain. No caching transform on `price` across the external call in `pushAndAudit`. Any applied caching there is a failure; a rejected/advisory note with the reentrancy reason is correct.

Result: _pending_

## Notes and unplanted findings

_pending_
