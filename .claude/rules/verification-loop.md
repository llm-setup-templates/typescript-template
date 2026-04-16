# Verification Loop Rules — TypeScript / Next.js

## The Loop

After any code change, run the full verification loop in this exact order (fail-fast):

```bash
npm run format:check    # format check  — Prettier
npm run typecheck       # type check    — tsc --noEmit
npm run depcruise       # architecture  — Dependency Cruiser (infra isolation + cross-feature)
npm run lint            # lint          — ESLint 9
npm run test            # tests         — Jest + ts-jest
npm run build           # build         — next build
```

Or run all at once:

```bash
npm run verify
```

(`npm run verify` = format:check && typecheck && depcruise && lint && test && build — defined in package.json)

If the **test** step fails, consult `.claude/rules/test-modification.md` to determine
which tests need updating based on the code change type, then re-run the loop.

## Agent Self-Verification Rules

1. Never declare a task complete until the full loop passes.
2. If a step fails, fix the root cause:
   - Do NOT use `--no-verify` to bypass Husky hooks.
   - Do NOT add `// eslint-disable-next-line` without a cited reason in a comment.
   - Do NOT skip failing tests by deleting or commenting them out.
3. After 3 consecutive failed attempts on the same step, escalate to the human
   instead of trying more aggressive fixes.
4. If the loop command itself is broken (e.g., missing dependency), report the
   infrastructure problem before attempting code fixes.

## CI Parity

The local verification loop MUST match the CI workflow (`.github/workflows/ci.yml`):

| Step | Local command | CI step name |
|------|--------------|--------------|
| Format | `npm run format:check` | Format check |
| Typecheck | `npm run typecheck` | Type check |
| Architecture | `npm run depcruise` | Architecture boundary check |
| Lint | `npm run lint` | Lint |
| Test | `npm run test` | Test |
| Build | `npm run build` | Build |

Any divergence between local loop and CI is a bug and must be resolved.

## Pre-commit Hook Parity

Husky `pre-commit` runs `npx lint-staged` which runs:
- `prettier --write` + `eslint --fix` on staged `.ts/.tsx/.js/.jsx` files
- `prettier --write` on staged `.json/.md/.yaml/.yml/.css` files

This is a subset of the full loop (no typecheck/test/build in pre-commit).
The full loop MUST still pass before declaring a task complete.
