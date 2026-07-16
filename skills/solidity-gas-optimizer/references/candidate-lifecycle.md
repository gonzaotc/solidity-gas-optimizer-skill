# Candidate lifecycle: states, dispositions, dedup, funnel

The audit's conservation contract. Every candidate is **conserved**: it ends in exactly one disposition and none is silently dropped. This file is the single source of truth for the state machine; the phases in `SKILL.md` only name its terms.

## States

A candidate moves through up to four states:

1. **observation** — a raw resource fact in the Phase 1 inventory.
2. **candidate** — an observation the Phase 2 scan promotes once it hypothesizes avoidable waste and a transform.
3. **measured result** — the Phase 3 delta: a real saving, flat, a regression, or a positive below the noise floor. Only a candidate that gets a real number reaches this state, and only in Phase 3 (non-negotiable 8).
4. **report entry** — the umbrella term for a candidate that reaches the report carrying a disposition.

A **finding** is the narrow report entry of a measured survivor (`kept` or `team-decision`). Advisory, coverage-gap, rejected, and duplicate entries are report entries, not findings. A measured transform traverses all four states; an advisory or coverage-gap candidate terminates at `candidate` and reaches the report as a labeled estimate, never a measured result. A candidate that enters Phase 3 and turns out to have no test driving its code gets no number: it reverts to `candidate` and terminates as coverage-gap.

## Discovery ledger

Not a new artifact. It is the Phase 2 candidate record carried forward, one row per candidate, keyed by the `candidate id` threaded into the inventory's `candidate IDs` column: the same list gaining a `state` column Phase 3 advances and a `disposition` column drafted in Phase 4 and finalized at the Phase 5 close. It is candidate-grained, distinct from the site-grained resource inventory that feeds it.

## Dispositions

Every candidate ends in exactly one, and the set maps one-to-one onto the report's populations plus one dedup outcome:

- **kept** — measured a real saving and survived the Phase 5 challenge (`recommend`).
- **team-decision** — measured and survived, but the tradeoff is the team's call.
- **advisory** — design-level, or reclassified to report-only by policy; estimated, never applied. A candidate a hard policy constraint forbids (a layout freeze, an ABI freeze, an assembly-averse style) maps here, not to a dedicated `blocked` state: it is still worth reporting as "you would save X if the constraint were lifted." Record the blocking constraint on the entry.
- **coverage-gap** — a real candidate no test exercises, so never measurable; whether the gap is known from the Phase 1 coverage map or discovered when Phase 3 finds no test drives the touched code. Its own report population, never merged into rejected: rejected candidates were measured and failed; coverage-gap candidates were never measurable.
- **rejected** — measured and did not earn a keep, or was rejected downstream. Record the reason: `flat`, `regression`, `below noise floor` (a positive delta under the policy threshold; record the number), `broke targeted tests`, `compile failure`, `integration` (passed alone but failed the full suite and was dropped), `challenge` (the Phase 5 tradeoff pass rejected it), or `superseded by <id>` (a competing transform for the same waste chosen over it at the Phase 5 tradeoff). A saving sibling is never rejected on gas alone in Phase 3: supersession weighs gas against simplicity, compatibility, and risk, so a smaller but simpler transform can win, and that choice belongs to Phase 5.
- **duplicate** — merged into another candidate that proposes the same transform (see dedup below).

This candidate-to-disposition accounting is the run's completeness obligation, drafted in Phase 4 and reconciled at the Phase 5 close through the funnel below. It is the candidate-grained sibling of the site-grained scan-omission check in Phase 2 (`completed passes` must reach `required passes`): one insists every site was examined, the other that every candidate was disposed.

## Dedup by mechanism, not card ID

The tuple `(location, expensive resource, redundant operation, semantic constraint)` identifies a *waste*, not a *fix*. The catalog and the mindset passes can surface one site's waste under different card IDs, and the multi-pass scan revisits sites, so card ID is provenance, not identity.

Two candidates merge only when they share the tuple **and propose the same transform**: absorb the redundant ones into one, record the merged-away IDs on it, and dispose the absorbed ones as `duplicate`. Candidates that share the tuple but propose **different** transforms are competing fixes for the same waste, not duplicates: keep each as its own candidate in a shared `competes-with` group. Phase 3 measures each from an identical baseline, and the Phase 5 tradeoff (not a Phase 3 gas comparison) picks the winner on gas plus simplicity, compatibility, and risk; the losers become `rejected (superseded by <id>)`. Keeping competing transforms as separate candidates keeps the funnel arithmetic honest: three transforms for one waste are three candidates in, one kept plus two superseded out. Raise competing candidates only when a genuinely plausible alternative fix exists and the tradeoff is unclear; each extra candidate is a full measurement cycle.

## Discovery funnel

The conservation ledger's arithmetic view, built through the integration transition and put in the Phase 4 draft (template section: Discovery funnel). It is per-transition, not one final tally: at each stage `scan → dedup → policy/coverage routing → application → measurement → integration → challenge → report` the candidates coming in must equal those passed on plus those exiting to a disposition at that stage.

- Duplicates exit at **dedup**.
- Advisory (design-level and policy-blocked) and coverage-gap (known from the coverage map) exit at **routing**.
- Compile failures and broke-targeted-tests exit at **application**.
- Regression, flat, and below-noise-floor exit at **measurement**; coverage discovered missing also exits here to coverage-gap.
- Integration failures exit at **integration**.
- The final `challenge → report` transition (`rejected (challenge)`, `rejected (superseded)`, `kept`, `team-decision`) stays blank until Phase 5 runs.

**Reconciliation gate.** Only at the Phase 5 close can the funnel reconcile: fill the `challenge → report` exits, verify every transition balances (in equals passed-on plus exited-here), and verify total candidates raised equals the sum of the six dispositions. A row that does not balance means a candidate vanished: find it before finalizing. This is the completeness gate; the report is not final until it passes.
