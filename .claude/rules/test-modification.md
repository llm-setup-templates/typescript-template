# Test Modification Rules — TypeScript / Next.js

## When to modify tests

Every code change MUST be accompanied by corresponding test changes.
Use this table to determine which test layers are affected:

| Code Change Type | Affected Test Layer | Required Action |
|-----------------|--------------------|-----------------| 
| API route/page added | unit + integration + snapshot | Create new test file(s), run `npm test -- -u` for snapshots |
| Function/component signature changed | unit (direct) + integration (indirect) | Update existing assertions and fixtures |
| DB schema / Prisma model changed | integration | Update fixtures/factories, add migration test |
| Business logic modified | unit | Update assertions, add edge case tests |
| Dependency version bumped | snapshot (may break) | Review diff → intentional = `npm test -- -u`; unexpected = fix code |
| Config / env var changed | integration + smoke | Update environment fixtures |
| **Refactoring (behavior unchanged)** | **none** | **Do NOT modify tests — if they break, the refactoring is wrong** |

## Test modification checklist (5 steps)

For every code change, follow this sequence:

1. **Identify affected layers** — Use the mapping table above. If unsure, err on the side of more layers.
2. **Run existing tests first** — `npm test` before any test changes. This establishes which tests break from your code change vs. which were already broken.
3. **Modify tests to match new behavior** — Update assertions, fixtures, mocks. Add new test files for new functionality. Follow the AAA pattern (Arrange-Act-Assert).
4. **Run verification loop** — Full `npm run verify` (format:check + typecheck + lint + test + build).
5. **Review test diff** — `git diff __tests__/ tests/` must make sense relative to the code change. If the test diff is larger than the code diff, reconsider your approach.

## Snapshot management (Jest)

**NEVER run `npm test -- -u` blindly.**

When a snapshot test fails:

```
1. Read the failure diff carefully
2. Ask: "Is this change intentional — did I deliberately change the output?"
   → YES: run `npm test -- -u`, then `git diff` the .snap files
   → NO:  the code change introduced a bug — fix the code, not the snapshot
3. After updating, review the git diff of snapshot files
   → If the diff looks wrong, revert and fix the code instead
```

> **First-time snapshots**: If this is a brand-new snapshot test (no `.snap` file exists yet),
> the "missing snapshot" error is expected. Run `npm test` once — Jest auto-creates the
> snapshot on first run. Then re-run to confirm it passes.

## Dynamic values in snapshots

**Never snapshot non-deterministic values** (timestamps, UUIDs, session IDs, random data).
If the component or response contains dynamic values:

- Use `expect.any(String)` / `expect.any(Number)` matchers, OR
- Mock the source of randomness (`Date.now`, `crypto.randomUUID`) in the test, OR
- Use `toMatchInlineSnapshot()` with manually curated expected output

Example: a component showing `lastUpdated: new Date()` — mock `Date.now` to a fixed value.

## Matching existing project patterns

Before creating new test files:

- **Check test directory structure**: `__tests__/` vs. colocated `*.test.ts` vs. `tests/` folder. Follow existing convention.
- **Check test patterns**: some projects use `@testing-library/react` render, others use `enzyme` or raw `jsdom`. Match what exists.
- **Check import style**: named imports vs. default imports, relative vs. alias (`@/`). Match existing tests.

## Prohibitions

- **No `npm test -- -u` without reading the diff first**
- **No deleting tests to make CI green** — fix the code or update the test correctly
- **No `// eslint-disable` or `@ts-ignore` to suppress test failures** — these mask real bugs
- **No skipping tests** (`test.skip()`, `xit()`) without a documented reason and issue link
- **Refactoring PRs must not change test assertions** — if a test breaks during refactoring, the refactoring changed behavior

## New feature test requirements

When adding a new feature (component, API route, utility):

- **Minimum**: 1 unit test covering the happy path + 1 edge case
- **Component**: render test + key interaction test (click, submit)
- **API route**: request/response test with mocked dependencies
- **Snapshot**: if the feature produces stable UI output, add a snapshot test
- Follow existing test file naming convention (check `__tests__/` vs. colocated)

## Worked examples

For three concrete walkthroughs (add GET route, change signature,
refactor with unchanged behavior) showing how this rules file maps to
actual code/test diffs, see `examples/guides/test-modification-scenarios.md`.
Copy the scenarios into your project's internal docs if you want them
as a living reference.
