# RFC-001: Vitest Migration (TypeScript)

Status: Proposed (2026-04-26)

## Context

Phase 13c locks Jest 29 + `next/jest` as the test runner (Wiki rubric
Q14, score 8). next/jest preserves Next 16's RSC + SWC transformation
pipeline and avoids the ts-jest Next 16 RSC compatibility break.

Vitest is increasingly the recommended test runner for new Next.js
projects in community guides, with native ESM, faster cold start, and
Vite-aligned mocking primitives. Migration is **out of scope** for
Phase 13c but worth tracking explicitly.

## Triggers for Promotion to ADR-003

This RFC is promoted to an Accepted ADR when **any one** of the
following surfaces:

1. **Next.js team recommendation**: official Next.js docs flip from
   `next/jest` to a Vitest preset as the primary recommendation (track:
   `nextjs.org/docs/app/guides/testing`).
2. **RSC coverage break**: a future Next minor (16.x or 17.x) breaks
   `next/jest`'s ability to test React Server Components — and Vitest
   has a working preset.
3. **Jest ESM friction**: Jest's `transformIgnorePatterns` workarounds
   for ESM-only deps reach a regression rate that exceeds the migration
   cost. Threshold: 3+ user-reported issues against the template tied
   to Jest ESM in a 90-day window.
4. **Team request**: a maintainer or downstream user opens an issue
   citing a concrete blocker that Vitest would resolve and Jest would
   not.

## Migration Sketch (when triggered)

Target: drop `jest`, `@types/jest`, `jest-environment-jsdom`, `next/jest`
deps. Add `vitest`, `@vitest/coverage-v8`, `jsdom` deps.

Touch points (estimated):

- `examples/archetype-next/seed/jest.config.mjs` → `vitest.config.ts`
- `examples/archetype-next/seed/package.json` scripts: `test`,
  `test:coverage`, `test:watch`
- Existing `__tests__/` snapshot format (`.snap` files) — Vitest uses
  the same Jest-compatible snapshot format, so this is mechanical.
- `.claude/rules/test-modification.md` — update commands and snapshot
  guidance (`vitest -u` instead of `jest --updateSnapshot`).
- `validate.sh` V26 grep target — change from `next/jest` to
  `defineConfig.*vitest`.
- ADR-001 `branches: 50%` threshold transfers as-is (Vitest's V8
  coverage uses the same metric vocabulary).

## Out-of-Scope for Phase 13c

This RFC is a **stub**: it carves out the namespace `RFC-001` and
documents the trigger conditions, so a future maintainer doesn't
accidentally renumber. No implementation work is included in Phase 13c.

## References

- Phase 13c PLAN.md `Wiki rubric Q14` (Q14-A=8 score: ts-jest break risk
  vs migration cost).
- Phase 13c Locked Decision LD-03 (next/jest + RFC-001 stub).
- next/jest official: `nextjs.org/docs/app/guides/testing/jest`
- Vitest official: `vitest.dev/guide/`
