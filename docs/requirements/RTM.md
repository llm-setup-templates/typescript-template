# Requirements Traceability Matrix

> Single source of truth linking every requirement — functional (FR) and
> non-functional (NFR) — to its artifacts: GitHub issue, architectural
> decisions it depends on, the screen it appears on, the API it consumes,
> the code it lives in, the tests that cover it, and its current status.

## Status values

| Value | Meaning |
|---|---|
| `Draft` | FR file exists, AC not finalized |
| `Design` | AC agreed; ADRs being written |
| `Implementing` | PR open, tests being added |
| `Done` | Merged, tests passing, RTM row complete |
| `Deprecated` | No longer in scope — keep row for history |

## Domain prefixes

Uppercase abbreviations; each domain numbers its IDs independently.

| Prefix | Meaning |
|---|---|
| `ORDER` | (example) order management — replace with your own domains |

## How to use

- Add a row when an FR issue is opened; update it in the same PR that
  implements or changes the FR. Never delete a row — set Status to
  `Deprecated` instead, and never reuse a retired number.
- Multiple values in Issue / Screen / API / Component(s) / Test(s) are
  allowed, comma-separated. Any path you write must exist in this repo
  (checked by `V_rtm` in validate.sh), except on `Deprecated` rows,
  which keep their historical paths even after the code is gone.

| Column       | Format                                             | Required when |
|--------------|----------------------------------------------------|---------------|
| FR ID        | `FR-{DOMAIN}-{NNN}` (NFR rows: `NFR-{CATEGORY}-{NNN}`) | always    |
| Summary      | one line                                           | always        |
| Issue        | `#NNN`, comma-separated                            | optional      |
| ADR          | `ADR-NNN`                                          | optional      |
| Screen       | `{DEVICE}-{AREA}-{SCREEN}-{NN}`, or `n/a`          | optional      |
| API          | operationId of the endpoint consumed, or `n/a`     | optional      |
| Component(s) | backticked repo-relative file path(s)              | Status = Done |
| Test(s)      | `TC-{DOMAIN}-{NNN}` (recommended) plus backticked test path(s) | Status = Done |
| Status       | Draft / Design / Implementing / Done / Deprecated  | always        |
| Owner        | `@handle`, or `—`                                  | optional      |
| Notes        | NFR target and measurement, exclusion reason, etc. | optional      |

Domain prefixes are defined in the table above — `ORDER` in examples is a
placeholder; define your own.

Screen IDs use three uppercase segments and a two-digit sequence, e.g.
`M-FE-HM-01` (mobile, front-end area, home screen, first of its kind).
The abbreviations are yours to define; only the shape is checked.

## Requirements

<!-- Example rows (kept in this comment so they never pollute the live table):
| FR-ORDER-001 | (example) cancel an order | #0 | — | M-FE-OR-01 | cancelOrder | `src/features/order/model/cancel-order.ts` | TC-ORDER-001 `__tests__/order/cancel-order.test.ts` | Done | — | — |
| NFR-PERF-001 | (example) p95 route transition | — | — | n/a | n/a | — | — | Draft | — | Target: < 300 ms; measurement: Lighthouse run on the order route |
-->

| FR ID | Summary | Issue | ADR | Screen | API | Component(s) | Test(s) | Status | Owner | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
