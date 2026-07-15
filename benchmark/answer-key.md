<!-- Style: no dashes. Never use em dashes, en dashes, or a hyphen as a sentence
     connector; rephrase into separate clauses or use a comma/colon instead. -->

# Hidden answer key and measured ceilings (v0)

Do not expose this file to a producer run. It lives one directory above `fixtures/`, so a run scoped to `benchmark/fixtures/` never sees it. Honor-system hidden for v0.

**Pinned settings:** solc 0.8.30, optimizer on, runs 200, evm_version cancun, forge 1.5.1. Every number below was measured with `forge test --gas-report`. Numbers are only valid for these settings; re-measure when they change.

## How the tiers are graded

Each standard ships three implementations (`Bad`, `Medium`, `Good`) that pass one shared conformance suite, so they are behaviorally identical and differ only in gas. The `Good` tier's measured gas is the **ceiling**: the target, not an enumerated list. To score a producer run on a lower tier:

```
gap available = tier_gas - good_gas
gap closed    = tier_gas - optimized_gas
closure       = gap closed / gap available   (per function and for deployment)
```

**Which policy the producer runs under must be recorded with the score, because it changes what counts as a miss.** For a clean recall read, run the producer under `allow-abi-changes` so every tier difference is applicable and both axes are pure recall. Under the default compatibility freeze some ceiling gains are correctly report-only, not applied, so score deploy-closure only against policy-applicable gains (see the deploy caveat below); otherwise correct policy restraint reads as a recall miss.

**Headline is runtime closure; annotate deployment closure.** For these standards the cold `SSTORE` dominates the happy path, so the deployment axis carries the largest gradient but is policy-confounded, while the runtime axis (cached reads, `constant` config, the removed `_adminRoles` read) is the cleaner recall signal.

**Deploy caveat (the confounds):** two large deploy gains are not plain applicable savings. DEP-08 (custom errors over require strings) changes revert data and is therefore an ABI change: the policy template classifies it report-only unless `allow-abi-changes` is set. And part of the ERC20 medium-to-good deploy gap comes from `external` vs `public` visibility, which is FBD-08 (forbidden to recommend for gas) and must never be applied. So under the default freeze a correct producer will not apply DEP-08 and will never flip visibility, and deploy-closure will read low for the right reason. Either run under `allow-abi-changes` and subtract the visibility portion, or read the runtime axis as the recall signal. Running under the default freeze is itself a useful policy check: DEP-08 should appear as report-only, not applied, a preview of the Layer 2 ablation.

- **Unplanted-finding rule:** closure above 100% means the run beat the good tier. That is a true positive to fold back into the good tier, never an error. This rule governs: a measured-real, test-passing saving is always a true positive, including on the flat-looking functions below.
- **Precision probes are about unmeasured claims, not measured ones.** `approve` and `renounceRole` are effectively flat across tiers (a `SSTORE` with no surrounding waste). A run that *claims* a saving there which does not measure, or a rewrite that fails to reproduce, is a false positive. A saving that actually measures real on them is still a true positive under the rule above; the probe catches hallucinated or unverified claims, not genuine wins.
- **Technique diagnostic (secondary):** the lists below name what actually separates each tier from good. Use them to see which optimizations a run caught, not to compute the headline score. They never feed closure, so entangled findings cannot corrupt the metric.

## Finding-count ladder (design property)

The tiers are built as a **cumulative opportunity ladder**: `Good` applies every planted technique, `Medium` a subset, `Bad` none. So the number of tier-discriminating transform findings is monotone by construction, `Bad > Medium > Good`, and a blind scan must surface strictly more on the lower tiers. Counts below are discriminating transform findings only; tier-invariant advisories that fire on any ERC20 or AccessControl (ARC-03 permit, XC-05 multicall, EXE-12 public-state-var visibility, and the like) are not counted because they appear on `Good` too and do not discriminate.

| Standard | Bad (planted) | Medium (planted) | Good | Bad (blind-measured) | Medium (blind-measured) |
|---|---|---|---|---|---|
| ERC20 | 6 | 2 | 0 | 7 | 2 |
| AccessControl | 4 | 2 | 0 | 5 | 2 |

The margins are deliberately wide so one missed or spurious detection cannot invert the order. The blind-measured columns are from an answer-key-blind scan scoped to `fixtures/`; it surfaces the planted set plus one soft extra on each `Bad` tier (EXE-01 strict comparison on ERC20, the dead `_adminRoles` read reported as its own card on AccessControl). The exact `Bad`/`Medium` integers carry a point or two of scanner judgment; the `Bad > Medium > Good = 0` gradient does not, and held on both families.

## ERC20 (`src/erc20/`)

Shared suite: `test/erc20/ERC20Tiers.t.sol`. Measured gas:

| Metric | Bad | Medium | Good (ceiling) | OZ reference |
|---|---|---|---|---|
| Deployment | 561521 | 415250 | 357100 | 540849 |
| `transfer` (cold, max) | 51509 | 51325 | 51159 | 51421 |
| `transferFrom` (cold, max) | 57681 | 57247 | 56981 | 57453 |
| `transferFrom` (warm, min) | 26892 | 26832 | 24614 | 24755 |
| `approve` (max) | 45959 | 45959 | 45958 | 46174 |

`approve` is effectively flat across tiers (a single `SSTORE`, ~1 gas spread): use it as a precision probe per the rule above. OZ runtime is within noise of the good tier; OZ deployment sits near the bad tier because OZ carries the metadata interface, zero-address checks, and update hooks the minimal tiers omit (see the OZ note below).

Planted opportunities and where each is fixed:

| Opportunity | Card | Bad | Medium | Good |
|---|---|---|---|---|
| mutable storage metadata (`name`/`symbol`/`decimals`) to `constant` | ST-06 | present | fixed | fixed |
| require strings to custom errors | DEP-08 / EXE-23 | present | fixed | fixed |
| explicit zero-initialization of `totalSupply` | DEP-10 | present | fixed | fixed |
| uncached repeated `balances`/`allowances` reads (Bad also re-reads through the public getter) | ST-02 | present | fixed | fixed |
| checked arithmetic after the guard proves safety | EXE-07 | present | present | fixed |
| non-payable constructor | DEP-02 | present | present | fixed |

So the discriminating counts are Bad 6, Medium 2, Good 0. Bad to medium closes ST-06, DEP-08, DEP-10, ST-02 (this is most of the deploy gap plus the small runtime gap). Medium to good closes EXE-07 and DEP-02 (the runtime floor; the rest of the medium-to-good deploy gap is the `external`/`public` and shared-helper codegen difference, not an applicable finding).

All three tiers decrement allowance identically (no infinite-allowance shortcut), so they are behaviorally identical on every path the shared suite asserts, including events, zero-value, self-transfer, overwrite-approve, and allowance-to-zero.

## AccessControl (`src/accesscontrol/`)

Shared suite: `test/accesscontrol/AccessControlTiers.t.sol`. Measured gas:

| Metric | Bad | Medium | Good (ceiling) | OZ reference |
|---|---|---|---|---|
| Deployment | 331802 | 251267 | 250398 | 304059 |
| `grantRole` (cold, max) | 50960 | 50942 | 48705 | 51250 |
| `revokeRole` (cold, max) | 29144 | 29115 | 26878 | 29308 |
| `renounceRole` | 24650 | 24649 | 24649 | 24727 |

`renounceRole` is flat across the local tiers (same self-check and single `SSTORE`): another precision probe per the rule above. OZ `grantRole` and `revokeRole` are the most expensive of all, above even the bad tier, because OZ supports configurable per-role admins (`_roles[role].adminRole`), an extra storage indirection the local tiers hardcode away (see the OZ note below).

Planted opportunities and where each is fixed:

| Opportunity | Card | Bad | Medium | Good |
|---|---|---|---|---|
| mutable `DEFAULT_ADMIN_ROLE` slot plus dead `_adminRoles` mapping (a runtime `getRoleAdmin` storage read on every grant/revoke) to `constant`, mapping dropped | ST-06 (deploy + runtime) | present | present | fixed |
| `onlyAdmin` modifier inlined at two sites to a shared internal function | DEP-05 | present | fixed | fixed |
| require strings to custom errors | DEP-08 | present | fixed | fixed |
| non-payable constructor | DEP-02 | present | present | fixed |

So the discriminating counts are Bad 4, Medium 2, Good 0. Bad to medium closes DEP-05 and DEP-08, almost all of it deployment (the happy-path runtime barely moves because both tiers still read `_adminRoles`). Medium to good closes the ST-06 remainder, which removes the `getRoleAdmin` storage read on every `grantRole`/`revokeRole` (the ~2.2k runtime win), plus DEP-02.

Note on good-tier design: an earlier good tier inlined the admin check into both functions, which lowered runtime but raised deployment above the medium tier. The committed good tier factors the check into a shared internal function that still uses the `constant` admin, so it is the ceiling on both axes. This is a live example of the runtime-versus-deploy tradeoff the skill's Phase 5 exists to weigh.

## OpenZeppelin reference baseline (`ReferenceERC20`, `ReferenceAccessControl`)

The `OZ reference` columns are OpenZeppelin Contracts v5.1.0 (pinned), wrapped to expose the same interfaces and run through the same shared suites. They are a real-world baseline, **not the optimization target**. Read them three ways:

1. **Sanity check.** The local tiers are realistic: OZ passes the identical conformance suite, and its gas lands in the same neighborhood, so the fixtures are not toy code.
2. **The cost of production generality.** OZ deliberately sits above the good tier because it does more: metadata interface, zero-address validation, transfer hooks, and configurable per-role admins. The good tier is cheaper precisely because it omits features the suite does not exercise. So the good-tier ceiling measures gas for the tested behavior, while OZ measures gas for production-grade behavior. Do not read "good beats OZ" as "OZ is inefficient."
3. **A future restraint test.** Running the optimizer directly on the OZ reference is a strong precision and safety probe: it should find little, and it must never strip the zero-address checks or admin configurability to chase the good-tier number. That transform would pass this suite yet break real integrators, exactly the "passing tests is not sufficient" failure the strategy warns about. Not scored in v0, but the reason the reference is committed.

## Isolated discrimination case (`src/isolated/`)

Kept from the isolated set because the tier ladder tests finding savings, not refraining when a transform is unsafe.

### CASE-TWIN (abstention)

- **Fixture:** `src/isolated/PriceGuard.sol`, function `pushAndAudit`. Suite: `test/isolated/PriceGuard.t.sol`.
- **Looks like:** ST-02. `price` is read twice, which pattern-matches "cache the storage read."
- **Why the transform is wrong:** an external call `IPriceSink(sink).onPrice(...)` sits between the two reads. The callee can reenter `setPrice` and change `price`, so the second read must reload. Caching the first read across the call changes behavior.
- **Expected behavior:** abstain. No caching transform on `price`. If routed anywhere, it belongs in rejected or advisory with the reentrancy reason, never applied.
- **Proof the trap is real:** `test_readsReflectReentrantWrite` shows `before_ == 100` and `after_ == 250` through a reentrant sink. A cached version would return 100 twice and fail this test.
- **Difficulty:** 3 (inter-contract behavior: the hazard is only visible by reasoning about the external callee).
