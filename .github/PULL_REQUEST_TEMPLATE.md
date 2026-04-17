## Summary

<!-- 1–3 sentences. What changes and why. -->

## Related documents

<!-- Link every applicable document. Delete rows that don't apply. -->

- [ ] FR: `docs/requirements/FR-XX.md` — <!-- closes #... -->
- [ ] ADR: `docs/architecture/decisions/ADR-NNN-<slug>.md` — <!-- Accepted via this PR -->
- [ ] RFC: `docs/architecture/decisions/RFC-NNN-<slug>.md` — <!-- still Proposed, not in scope for merge -->
- [ ] Report: `docs/reports/<type>-YYYY-MM-DD-<slug>.md` — <!-- spike / benchmark / api-analysis / paar -->
- [ ] Briefing: `docs/briefings/YYYY-MM-DD-<slug>/` — <!-- event archive -->

## RTM discipline

- [ ] If this PR implements or changes an FR, `docs/requirements/RTM.md`
      is updated in this PR (new row or cell edits) — **mandatory when
      the FR row exists**.

## Architecture / FSD checks

<!-- Check everything that applies. Unchecked items with a comment explaining why = acceptable. -->

- [ ] Import direction respected (`app → widgets → features → entities → shared`)
- [ ] New cross-slice imports go through the slice's barrel `index.ts`
- [ ] No direct DB driver imports in `entities/` or `features/`
      (`npm run depcruise` passes)
- [ ] No new `any` / `unknown` without explicit narrowing
- [ ] External input validated with Zod (or a documented equivalent)

## Data-flow Balancing Rule (only if DFD changed)

- [ ] No Black Hole (a process with input but no output)
- [ ] No Miracle (a process with output but no input)
- [ ] No Gray Hole (a process whose outputs cannot be derived from its
      inputs — e.g. returns PII that wasn't fetched)
- [ ] Terminology is consistent between parent and child levels

## Verification

- [ ] `npm run verify` passes locally (format / typecheck / depcruise /
      lint / test / build)
- [ ] Tests updated in the same commit as the code change
      (see `.claude/rules/test-modification.md`)
- [ ] Screenshots / recording attached (UI change)

## Business impact (only for large or risky changes)

<!-- Delete this section for routine changes. Required for ADR-level PRs. -->

**Cost**: <!-- infrastructure, API quota, human effort -->
**Risk**: <!-- what can go wrong, what's the blast radius -->
**Velocity impact**: <!-- what does this enable / block for the next sprint -->
