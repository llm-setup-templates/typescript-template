# ADR-001: Adopt asymmetric Jest coverage threshold (branches 50%, functions/lines/statements 60%) for TypeScript template

---

- **Status**: Accepted
- **Date**: 2026-04-23
- **Deciders**: @gs07103
- **Related**: Phase 10 hardening PR (#11, merged 2026-04-23)

## Context

Phase 10 (typescript-template hardening, merged `15836fb`) wired a coverage gate into the Jest pipeline to close a Day-0 drift where `coverageThreshold` was absent and CI invoked `npm run test` instead of `npm run test:coverage`. The gate was implemented in `examples/jest.config.ts` and `examples/ci.yml` but **never formalized as an ADR at decision time** — Phase 10 bundled the coverage gate into a broader 7-item Approach A (DISCUSS § D2) without enumerating per-metric alternatives. This ADR records the decision retroactively so the numbers and their rationale survive future contributors and supersede reviews.

Cross-template drift notice: Spring ADR-001 (`ADR-001-jacoco-coverage-threshold.md`, Accepted 2026-04-23) contains five sentences — at approximate lines L14, L32, L54, L79, and L93 of that document — describing the TypeScript baseline as "70% starter baseline" or claiming "Phase 10 / 11 parity at 70%." The actual Phase 10 values shipped in `examples/jest.config.ts` are **`branches: 50, functions: 60, lines: 60, statements: 60`** — asymmetric, not a uniform 70%. Spring ADR-001 is Accepted and therefore immutable under the Append-only rule; retroactive correction of those sentences would violate that discipline, so this ADR carries the authoritative TypeScript values instead. A similar drift exists in prior session memory and in `.plans/llm-setup/10-typescript-template-hardening/DONE.md` where "70% line" appears as shorthand; both are corrected out-of-band of this ADR (memory and `.plans/` are not tracked in the repository).

## Decision

Adopt the following Jest `coverageThreshold.global` values for the TypeScript template's `examples/jest.config.ts`:

```ts
coverageThreshold: {
  global: { branches: 50, functions: 60, lines: 60, statements: 60 },
},
```

Coverage is collected from production source only — test files and ambient declarations are excluded via two `collectCoverageFrom` patterns:

```ts
collectCoverageFrom: [
  'src/**/*.{ts,tsx}',
  '!src/**/*.d.ts',
  '!src/**/*.test.{ts,tsx}',
],
```

The asymmetric floor (branches 10 points lower than the other three metrics) reflects Jest's four-metric default: branches is structurally harder to cover than line/statement/function counts at scaffold time, and enforcing parity blocks Day-0 green without meaningful signal. The 60% floor on the other three metrics matches the `pytest-cov` line-only baseline used in the Python template (see Python ADR-001) — interpreted-language stacks converge on 60% as the starter baseline.

## Alternatives considered

> Phase 10 decided these thresholds as part of a bundled 7-item Approach A (`.plans/llm-setup/10-typescript-template-hardening/DISCUSS.md` § D2) without formal Option A/B/C enumeration. This ADR reconstructs the alternatives retrospectively based on the Phase 11 Spring ADR-001 structure so future reviewers can see the tradeoff surface that was implicitly accepted.

### Option A: `branches 50% + functions/lines/statements 60%` (chosen)

Asymmetric floor that accepts the structural harder-to-cover reality of branch metrics at scaffold time. Trade-off: the `50 vs 60` asymmetry adds one line of cognitive load to anyone reading the config, but guarantees Day-0 green and lets autonomous LLM agents complete scaffold-to-green runs.

**Rejected alternatives**: see B and C below.

### Option B: uniform 70-80% across all four metrics

Would have matched a common industry "production-ready" ratio and required teams to write real tests before CI turns green. Rejected because the template's stated purpose is a Day-0 scaffold baseline; a uniform 70%+ floor blocks fresh repos on `npm run test:coverage` and blocks LLM autonomous runs until real code and real tests land. The raise path stays open — teams escalate via a future ADR supersede, not a decision gate at scaffold.

### Option C: line 70% + branch 50% (asymmetric but higher line floor)

Preserves the asymmetry insight of Option A but with a stricter line/statement/function floor. Rejected because 70% on lines at scaffold time is still above empty-project reality (the scaffold's seed `app/page.tsx` plus a single unit test cannot hit 70% lines); the gain over Option A (a perceived "aligned at 70%" narrative with Spring) is not worth the Day-0 breakage.

See Phase 10 DISCUSS § D2 (`.plans/llm-setup/10-typescript-template-hardening/DISCUSS.md`) for the full Phase 10 context. Note that D2 itself records only the problem statement (`coverageThreshold` absent + CI not measuring coverage) and the bundled fix, not an explicit three-option comparison — this ADR's Options A/B/C are a retroactive reconstruction for documentation completeness.

## Consequences

What becomes **easier**:

- Day-0 green CI on every fresh scaffold — the asymmetric floor reflects structural reality rather than aspirational targets
- LLM agents complete autonomous scaffold-to-green runs without hitting a coverage wall on trivial seed code
- Per-metric raise path is open (teams edit the four numbers independently in `examples/jest.config.ts`)

What becomes **harder**:

- Cross-template comparison narrative is less clean — readers encountering Spring ADR-001's "70% parity" claim must consult this ADR to see the actual numbers
- Four-metric Jest shape has more moving parts than Spring JaCoCo (2 metrics) or Python pytest-cov (1 metric) — raise decisions require thinking per-metric

**New technical debt**:

- Only one guard (in-place config) exists. Phase 13+ may add a SETUP.md § Coverage Threshold Adjustment section analogous to Spring Phase 11 T10 / Python Phase 12 T11-b for raise-trigger documentation. Intentionally deferred from Phase 11.5 scope to keep the retroactive ADR single-file.

## Business impact

### Cost

- Infrastructure: $0 / month (Jest + ts-jest are already installed; no additional tooling)
- Vendor / license: $0
- Engineer time to implement: 0 (already implemented in Phase 10; this ADR is zero-effort recording)
- Ongoing maintenance: ~0 hours / quarter unless raise decisions are made

### Risk

- Blast radius if the numbers turn out wrong: all derived TypeScript repositories inherit the four values; override is a single-PR edit in `jest.config.ts`
- Rollback time: < 5 minutes (edit four numbers, push, redeploy)
- Mitigations: per-metric numbers are independent, so tuning one metric does not disturb the others

### Velocity impact

- **Enables**: Day-0 CI green; autonomous scaffold runs; per-metric raise path as the codebase matures
- **Blocks**: nothing — the floor is additive and can be raised at any time via a future ADR
- **Does not affect**: existing derived repositories that have already customized their threshold

## Implementation notes

- Configuration source: `examples/jest.config.ts` around L20–L28 (`coverageThreshold.global` object)
- CI invocation: `examples/ci.yml` line 44 (`npm run test:coverage`) — running `npm run test` without `:coverage` silently bypasses the gate
- Raise procedure: edit each metric independently in the `global` object. Example:
  ```ts
  global: { branches: 70, functions: 80, lines: 80, statements: 80 },
  ```
- Lower-bound rule: do not lower any metric below the values in this ADR without recording an ADR that supersedes ADR-001 (Append-only rule per `.claude/rules/documentation.md`)

## References

- Phase 10 PR (hardening, TypeScript): https://github.com/llm-setup-templates/typescript-template/pull/11
- Phase 10 DISCUSS § D2 (bundled decision context): `.plans/llm-setup/10-typescript-template-hardening/DISCUSS.md`
- Spring ADR-001 (cross-template coverage comparison, contains five "70% aligned" sentences at approximate L14 / L32 / L54 / L79 / L93 that this ADR supersedes as the authoritative TypeScript values): `templates-review/spring-template/docs/architecture/decisions/ADR-001-jacoco-coverage-threshold.md`
- Python ADR-001 (pytest-cov 60% line-only baseline): `templates-review/python-template/docs/architecture/decisions/ADR-001-pytest-cov-threshold.md`
- Jest coverage threshold documentation: https://jestjs.io/docs/configuration#coveragethreshold-object
