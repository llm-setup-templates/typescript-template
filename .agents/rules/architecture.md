# Architecture Rules — TypeScript / Next.js + FSD

## Directory Layout (Feature-Sliced Design — 5 Layers)

```
src/
├── shared/          # Reusable primitives — no business logic
│   ├── ui/          # Generic UI components
│   ├── lib/         # Utility functions
│   │   ├── errors.ts         # AppError class (route handler try-catch)
│   │   ├── errorResponse.ts  # Error response helper (NextResponse.json shorthand)
│   │   ├── apiHandler.ts     # (Optional) HOF — reduce boilerplate if desired
│   │   └── logger.ts         # (Optional) Structured logger — for production deployments
│   ├── config/      # App-level configuration constants
│   ├── api/         # Low-level API client (fetch wrapper)
│   └── model/       # Shared TypeScript types / Zod schemas
├── entities/        # Business entities (User, Product, Order, …)
├── features/        # User-facing features (auth, checkout, search, …)
├── widgets/         # Composite UI blocks assembled from entities + features
└── app/             # Next.js App Router root (layout.tsx, page.tsx, …)
                     # NOT a FSD layer — Next.js routing convention
```

**Note on `pages/`**: Next.js App Router does not use `src/pages/`. Add `src/pages/`
only when migrating to or supporting the Pages Router.

## Module Boundaries (Import Direction)

```
app → widgets → features → entities → shared
```

- Upper layers may import from lower layers.
- Lower layers MUST NOT import from upper layers.
- Same-layer cross-slice imports are allowed ONLY through the public barrel API.
- Violations are detected by `eslint-plugin-fsd-lint` rules:
  `forbidden-imports`, `no-relative-imports`, `no-public-api-sidestep`

## Public API Surface — Barrel File Convention

Every FSD slice MUST expose its public interface through `index.ts` only.

### Barrel file structure (`src/<layer>/<slice>/index.ts`):
```ts
// Re-export default exports with a named alias
export { default as UserCard } from './ui/UserCard';
export { default as useUserStore } from './model/useUserStore';

// Re-export named exports directly
export type { User, UserRole } from './model/types';
export { fetchUser } from './api/userApi';
```

### Component file convention (`src/<layer>/<slice>/ui/ComponentName.tsx`):
```ts
// Component implementation ...

export default ComponentName;  // ← default export required
```

### Consuming a slice:
```ts
// Correct — goes through barrel
import { UserCard } from '@/entities/user';

// VIOLATION — sidesteps barrel (blocked by no-public-api-sidestep)
import UserCard from '@/entities/user/ui/UserCard';
```

## Circular Dependency Policy

Circular imports are **absolutely prohibited** at any level.
- Between layers: structurally impossible if import direction is respected.
- Within a slice: must be manually prevented; use flat module structure if unsure.

## Cross-Layer Access Rules

| From ↓ \ To → | shared | entities | features | widgets | app |
|----------------|--------|----------|----------|---------|-----|
| shared         | ✓ (intra) | ✗ | ✗ | ✗ | ✗ |
| entities       | ✓ | ✓ (intra) | ✗ | ✗ | ✗ |
| features       | ✓ | ✓ | ✓ (intra) | ✗ | ✗ |
| widgets        | ✓ | ✓ | ✓ | ✓ (intra) | ✗ |
| app            | ✓ | ✓ | ✓ | ✓ | ✓ |

**Intra** = within the same slice, relative imports allowed.

## [CRITICAL] AI Agent Architectural Constraints — TypeScript / Next.js

### 1. Response Pattern (Next.js standard — different from Spring/FastAPI!)
- Success: `NextResponse.json(data)` **direct return** — no `ApiResponse<T>` wrapper needed.
- Error: `NextResponse.json({ error, message }, { status })` — consistent error shape.
- Route Handler error handling — two patterns (both allowed):
  - **Pattern A (standard)**: try-catch inside route handler + NextResponse return
  - **Pattern B (optional)**: `apiHandler` HOF — reduces repetitive boilerplate
- Use `AppError` class for error categorization in try-catch blocks.

### 2. Layer Dependency Isolation
- FSD layers enforced by eslint-plugin-fsd-lint.
- Infrastructure isolation (Dependency Cruiser when configured):
  - `entities/` and `features/` MUST NOT import Prisma, Drizzle, `pg`, or DB drivers.
  - DB access: via Server Actions or `shared/api/` repository functions.
  - Features MUST NOT cross-import other features.

### 3. Observability
- `console.log/warn/error` allowed (Next.js server-side default, Vercel auto-collects).
- For production structured logging, use `shared/lib/logger.ts` (optional).
- ESLint `no-console: warn` — encourages cleanup before commit.

### 4. Required Execution Sequence
1. IDENTIFY: which FSD layer?
2. SEARCH: check existing patterns.
3. VERIFY: `npx depcruise src` + ESLint FSD rules.
4. PUBLIC API: import through barrel `index.ts` only.

### 5. Zod Schema Convention
- Server Actions and Route Handlers validate input with Zod (Next.js official).
- `schema.parse()` for hard validation, `.safeParse()` for Server Actions form validation.
- NEVER use `as` type assertions to bypass Zod validation.

## Universal Principles
- Dependency direction: outer layers import from inner layers, never reverse.
- Smallest public surface: expose only what callers need through `index.ts`.
- No "util dump" files: every file has a single, named responsibility.
- No `index.ts` re-exporting the entire slice internals — expose only the public API.
