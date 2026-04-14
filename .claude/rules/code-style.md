# Code Style Rules — TypeScript / Next.js

## Universal
- Indent size: 2 spaces (tabs never)
- Line length limit: 80 characters
- Trailing commas: es5 (trailing commas where valid in ES5 — objects, arrays, imports)
- End of line: LF (enforced via .gitattributes: `* text=auto eol=lf`)
- File encoding: UTF-8

## Formatter Ownership — Prettier
- Prettier owns all whitespace and layout decisions.
- ESLint handles semantic and logic rules only.
- Any ESLint rule that conflicts with Prettier output MUST be disabled in ESLint config.
- Run: `npm run format` (write) or `npm run format:check` (verify)
- Config: `.prettierrc` (tabWidth: 2, singleQuote: true, trailingComma: "es5", printWidth: 80)

## Linter — ESLint 9 flat config
- Run: `npm run lint`
- Config: `eslint.config.mjs`
- Extends: `next/core-web-vitals` + `next/typescript` + `eslint-plugin-fsd-lint`
- Rules:
  - `fsd-lint/forbidden-imports`: error
  - `fsd-lint/no-relative-imports`: error
  - `fsd-lint/no-public-api-sidestep`: error

## Naming Conventions
- **React Components / Types / Interfaces / Enums**: `PascalCase`
  - Example: `UserProfile`, `ApiResponse`, `UserRole`
- **Functions / variables / object properties**: `camelCase`
  - Example: `getUserById`, `isLoading`, `fetchData`
- **Constants (module-level, truly immutable)**: `SCREAMING_SNAKE_CASE`
  - Example: `MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT_MS`
- **File names for components**: `PascalCase.tsx`
  - Example: `UserCard.tsx`, `AuthForm.tsx`
- **File names for utilities / hooks / services**: `camelCase.ts`
  - Example: `useAuth.ts`, `apiClient.ts`, `dateUtils.ts`
- **Directory names**: `kebab-case` (except FSD layers which are lowercase singular)

## Import Rules
- Use `@/*` path alias for all project imports (configured in `tsconfig.json`)
  - Correct: `import { Button } from '@/shared/ui'`
  - Wrong: `import { Button } from '../../shared/ui'`
- Cross-slice imports (feature → feature, entity → feature, etc.) MUST go through
  the target slice's public API barrel (`index.ts`)
- Intra-slice imports (within the same slice) may use relative paths
- Third-party imports come before project imports (enforced by `import/order` if added)
- `import type` MUST be used for type-only imports

## Module Export Rules
See `.claude/rules/architecture.md` for the full Barrel File convention.
