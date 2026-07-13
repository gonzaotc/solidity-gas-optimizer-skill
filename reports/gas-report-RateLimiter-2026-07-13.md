# Gas Optimization Report: RateLimiter.sol (PR #6490)

| | |
|---|---|
| Repo | openzeppelin-contracts @ 1f2dbd311 (feature/ratelimiter) |
| Scope | contracts/utils/RateLimiter.sol |
| Date | 2026-07-13 |
| Toolchain | hardhat + hardhat-gas-reporter (`GAS=true`), solc 0.8.35, optimizer runs 200, via-IR false |
| Baseline | 42 tests green, scoped to test/utils/RateLimiter.test.js (no other contract imports the library; verified by grep) + full compile |
| Work branch | gas/ratelimiter-rerun @ 73365edc5 (2 commits) |
| Active policy | OZ GUIDELINES/CLAUDE.md: readability-first, no assembly without cause, `unchecked` requires a documented invariant; library unreleased, so internal restructuring is allowed |

## Summary

| ID | Technique | Location | Severity | Δ gas (measured, avg) | Tests | Verdict |
|----|-----------|----------|----------|-----------------------|-------|---------|
| GAS-01 | Inline `state()`, cache `latest()` once and reuse as push base | `SlidingWindow.tryConsume` | Medium | consume −294, tryConsume −205 | 42/42 green | **team-decision** |
| GAS-02 | `unchecked` elapsed-time subtraction | `RefillingBucket.state` | Low | consume −54, tryConsume −47, sync −56 | 42/42 green | **recommend** |

Severity is impact (High/Medium/Low per the skill rubric). Verdict comes from the fresh-context tradeoff analysis, never from the optimizer pass.

## Findings

### GAS-01 · SlidingWindow.tryConsume reuses cached `latest()` as the push base

- **Severity**: Medium
- **Location**: contracts/utils/RateLimiter.sol, `SlidingWindow.tryConsume`
- **Measured**: consume 59,503 → 59,209 (−294); tryConsume 55,577 → 55,372 (−205) via hardhat-gas-reporter avg
- **Tests**: test/utils/RateLimiter.test.js 42/42 green; touched lines covered: yes (consume/tryConsume SlidingWindow suites exercise both the reset and non-reset branches)
- **Change**: commit 73365edc5. The original called `state()` (which reads `item_.latest()`), then re-read `item_.latest()` in the `push` argument, and `_insert` read the last checkpoint a third time. Inlining `state()` captures `latest_` once and reuses it as the push base, setting it to 0 on the `used_ == 0` reset path. A `// keep in sync with state()` marker was added at the analyzer's request.
- **Tradeoff analysis**: **team-decision**. "Savings are well above noise on the expensive user-facing strategy, cost is Tier B (code duplication, no assembly/bit-tricks). Behavioral equivalence verified: the `available_` check is identical; on `used_ == 0` both paths push `(now, quantity)` (confirmed `latest()` returns 0 on an emptied trace), and on `used_ != 0` the cached `latest_` equals the original re-read since nothing writes the trace before the push. Cheap mitigation the team should require before merging: a `// keep in sync with state()` marker at the inlined block, or extract a shared `_used(item_, window)` helper (though the latter may claw back some of the gain under the legacy optimizer, which is the whole reason for inlining)." Price tag: ~294 gas/consume and ~205/tryConsume saved at the cost of a second copy of `state()`'s used/available math that can silently diverge.

### GAS-02 · `unchecked` elapsed-time subtraction in RefillingBucket.state

- **Severity**: Low
- **Location**: contracts/utils/RateLimiter.sol, `RefillingBucket.state`
- **Measured**: consume 44,497 → 44,443 (−54); tryConsume 41,080 → 41,033 (−47); sync 30,024 → 29,968 (−56) via hardhat-gas-reporter avg
- **Tests**: test/utils/RateLimiter.test.js 42/42 green, including the `window saturation prevents underflow when block.timestamp < window` case; touched lines covered: yes
- **Change**: commit 0d34758f0. `Time.timestamp() - lastTimepoint_` is wrapped in `unchecked` with the documented invariant that `lastTimepoint_` is always a past timepoint. A fresh entry has `lastTimepoint_ == 0 <= now`, so the subtraction cannot underflow.
- **Tradeoff analysis**: **recommend**. "Invariant `lastTimepoint_ <= Time.timestamp()` is airtight: every writer sets `_lastTimepoint` to `Time.timestamp()` (`tryConsume`, `sync`) or to 0 (`reset` via `delete`, and the fresh-entry default); `updateSettings` never touches it; `Time.timestamp()` is monotonically nondecreasing on-chain, so any stored value is `<= now`. The only way to break it is manual struct tampering, which the struct WARNING already places out of contract. No bug. This is the calibration example almost verbatim (unchecked on a hot path, ~50 gas, invariant documented at the site, idiomatic OZ)." Price tag: saves 47–56 gas per call at the cost of 4 lines and one `unchecked` block whose no-underflow invariant is documented and proven.

## Advisory findings

Design-level opportunities that cannot be applied as a local diff. Estimates, not measurements. Each opens with "Consider" and carries the reason.

| Card | Suggestion | Est. impact | Cost / consideration |
|------|------------|-------------|-----------------------|
| ST | Consider whether the packed config slot (`_capacity`/`_window`, `_limit`/`_window`) is worth reading via a single `sload` in assembly. | ~100 gas/call under legacy pipeline | Rejected in spirit: assembly violates the OZ style guide here, and via-IR already coalesces the reads. Report only. |

## Rejected candidates

Measured no-gain, regressions, broken tests, or tradeoff-analyzer rejections. Kept so the next run does not repeat them.

| Card | Location | Result | Note |
|------|----------|--------|------|
| Pointer/inline caching | `RefillingBucket.state` + `SlidingWindow.state` | **Regression** | Replacing the local `window_`/`limit_`/field caches with a cached struct pointer + inline `self._window`/`self._limit` reads measured WORSE: consume RefillingBucket +99, sync +105, tryConsume +87, consume SlidingWindow +61. The legacy optimizer already CSEs the mapping-slot keccak; hoisting storage reads into locals is what actually helps, so removing those locals regresses. Reverted. (This was the change sitting uncommitted in the working tree.) Tradeoff analyzer: reject sound; a measured negative delta is an automatic reject. Caveat: the sign could flip under `viaIR: true`, but this audit is pinned to viaIR false, so the reject stands unconditionally within the measured config. |

## Methodology

Baseline and deltas measured with hardhat-gas-reporter (`GAS=true`), one transform per commit on `gas/ratelimiter-rerun`, each measured against the 1f2dbd311 baseline. Numbers are valid only for the compiler settings above (solc 0.8.35, optimizer 200, via-IR false). The gas-reporter tables only cover functions the tests exercise. The `$RateLimiter` mock is a hardhat-exposed wrapper: its deployment size is a proxy, not the library's real per-consumer cost, since internal library functions inline into callers.
