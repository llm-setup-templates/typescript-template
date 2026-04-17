# FR-XX: <one-line imperative title>

> **Copy this file.** Rename to `FR-XX-<slug>.md`, remove the leading
> underscore, fill in every section. Add the row to `RTM.md` in the
> same PR.

---

## Metadata

- **FR ID**: FR-XX
- **Status**: Draft / Design / Implementing / Done / Deprecated
- **GitHub Issue**: #NNN
- **Related ADRs**: ADR-NNN (optional)
- **Owner**: @github-handle
- **Created**: YYYY-MM-DD

## User story

As a **<actor>**, I want **<capability>**, so that **<outcome>**.

## Trigger

Who or what starts this? HTTP request? Cron? User click? External webhook?

## Inputs

| Name | Type (TypeScript / Zod) | Source | Constraints |
|---|---|---|---|
| `exampleId` | `string` (z.string().uuid()) | URL path param | must exist in `users` table |

## Outputs

| Name | Type | Consumer | Notes |
|---|---|---|---|
| `ExampleDto` | `z.infer<typeof ExampleSchema>` | HTTP 200 body | defined in `src/shared/model/example.ts` |

## Preconditions

What must be true **before** this runs? These become guard clauses or
middleware checks in code. Name the function that enforces each.

- [ ] Caller is authenticated (`middleware/auth.ts` verifies JWT)
- [ ] `exampleId` exists in `users` (checked by `userRepository.findById`)

## Postconditions

What must be true **after** this completes? These become assertions in
tests.

- [ ] Response body matches `ExampleSchema`
- [ ] `analytics_events` row inserted with `event_type='example_accessed'`
- [ ] Operation is **idempotent** — repeat calls with same inputs do
  not create duplicate rows

## Structured logic

Describe the flow in **structured English** — constrained grammar
(`IF … THEN … ELSE`, `FOR EACH`, `WHILE`, `RETURN`). No natural-language
ambiguity. An LLM implementing from this spec should produce one
compilable function.

```
BEGIN FR-XX
  VALIDATE input via ExampleSchema.parse (throws on failure)
  FETCH user BY exampleId
  IF user IS NULL THEN
    RETURN 404 with { error: "USER_NOT_FOUND" }
  END IF
  IF user.isBlocked THEN
    RETURN 403 with { error: "BLOCKED" }
  END IF
  INSERT into analytics_events (event_type, user_id, ts)
  RETURN 200 with ExampleDto
END FR-XX
```

## Decision table

**Only include this section if the logic has 3+ interacting conditions.**
One row per condition, one column per Rule. Y / N / — (don't care).

| Conditions                        | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| User exists                       | N  | Y  | Y  | Y  |
| User is blocked                   | —  | Y  | N  | N  |
| Premium feature requested         | —  | —  | Y  | N  |
| **Actions**                       |    |    |    |    |
| Return 404 `USER_NOT_FOUND`       | X  |    |    |    |
| Return 403 `BLOCKED`              |    | X  |    |    |
| Return 403 `PREMIUM_REQUIRED`     |    |    | X  |    |
| Return 200 `ExampleDto`           |    |    |    | X  |

**Test coverage rule**: one test per Rule column. 4 Rules = 4 tests
minimum. No Rule column may be untested.

## Exception handling

- **Database connection failure**: retry with exponential backoff (3
  attempts, 100 ms / 400 ms / 1600 ms), then surface as 503
- **Validation failure**: return 400 with `{ error: "VALIDATION_ERROR",
  details: zodError.format() }` — do NOT swallow validation errors
- **Concurrent modification**: use optimistic locking on the `users`
  row; on conflict, return 409 `{ error: "CONCURRENT_MODIFICATION" }`

## Test plan

| Level | Scenario | File |
|---|---|---|
| unit | happy path | `__tests__/fr-xx/happy.test.ts` |
| unit | each decision-table Rule (R1 … RN) | `__tests__/fr-xx/rules.test.ts` |
| integration | DB retry behavior | `__tests__/fr-xx/db-retry.test.ts` |
| e2e | full HTTP round trip | `e2e/fr-xx.spec.ts` |

## Open questions

<!-- Resolved questions become part of the spec above. -->

- [ ] ...
