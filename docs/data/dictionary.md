# Data Dictionary

> Extended Data Dictionary — every named data element in the system
> linked to the **live Zod schema** that validates it. The schema is
> the source of truth; this file is the index into the schema.

## How this file is structured

Each row in the table points to a Zod schema file. The schema file
is authoritative for the type, constraints, and default values. This
file adds the **business-level** context (ownership, policy, rationale)
that doesn't belong in the code.

**Never duplicate field definitions here.** If a reader needs the
exact type or regex, they follow the link to the Zod schema. Duplication
is what makes data dictionaries rot.

## Data elements

| Element | Zod schema | DFD flow | Owner | Policy notes |
|---|---|---|---|---|
| `User` | `src/shared/model/user.ts` § `UserSchema` | EXT-01 → 1.0 | auth-team | PII — never logged |
| `Session` | `src/shared/model/session.ts` § `SessionSchema` | 1.0 → D1 | auth-team | 24h TTL, Redis + DB |
| `Article` | `src/entities/article/model/article.ts` § `ArticleSchema` | EXT-02 → 2.0 | content-team | cached 1h in `factcheck_cache` |

## Notation carry-over from structured analysis

The 1978 DeMarco notation (`= + [ | ] { } ( ) ** **`) isn't used
directly — Zod expresses all of it more clearly:

| DeMarco | Zod equivalent |
|---|---|
| `=` definition | `const X = z.object({ ... })` |
| `+` composition | nested `z.object({ ... })` |
| `[ a \| b ]` selection | `z.union([a, b])` or `z.enum([...])` |
| `{ a }` iteration | `z.array(a)` |
| `(a)` optional | `.optional()` or `.nullable()` |
| `** comment **` | TSDoc comment on the schema |

Business rules that Zod can't express (e.g. "balance must equal
sum of transactions") belong as named refinements:
`z.object({...}).refine((v) => ..., { message: "..." })`.

## Cross-cutting policies

Not every field needs a table row — but policies that apply across
many fields do:

- **Timestamps**: all `created_at` / `updated_at` fields are UTC
  ISO-8601 strings, generated server-side. Never trust client timestamps
- **UUIDs**: all primary IDs are UUID v4 unless an ADR documents an
  exception
- **Currency**: store as integer minor units (e.g. cents, won) — never
  floating point. Format at the edge, not in the domain model
- **Email**: normalized lowercase on write, case-sensitive on display

## When to add a row

- A new domain-level entity appears in the system
- A field's **policy** changes (even if the type doesn't)
- A field crosses a trust boundary (PII, payment, auth token) and
  needs handling rules documented

## When NOT to add a row

- Every internal-only helper type — those are local to a feature slice
- DTOs used only between adjacent layers — the Zod schema is enough
- Derived / computed fields that don't persist — document them in the
  FR file, not here
