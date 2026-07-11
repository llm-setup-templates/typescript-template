# {{PROJECT_NAME}}

> Generated from llm-setup-prompts/typescript-template.
> Canonical rules body for all agents (Claude Code loads this via CLAUDE.md imports; Codex CLI loads it directly).
> Replace `{{PROJECT_NAME}}` with the actual project name before use.

## 1. Project Overview

TypeScript / Next.js 15 (App Router) project scaffolded via
llm-setup-prompts/typescript-template. Architecture follows Feature-Sliced Design (FSD).

## 2. Tech Stack

- Language: TypeScript 5.x (strict mode)
- Runtime: Node.js 20 LTS
- Framework: Next.js 15 (App Router)
- Package Manager: npm
- Formatter: Prettier (`.prettierrc`)
- Linter: ESLint 9 flat config (`eslint.config.mjs`) + eslint-plugin-fsd-lint
- Type Checker: tsc (`npm run typecheck`)
- Test Runner: Jest 29 + ts-jest + jest-environment-jsdom
- CI: GitHub Actions (`Node 20`, `.github/workflows/ci.yml`)
- PR Review: CodeRabbit (`.coderabbit.yaml`)

## 3. Primary Commands

- Install deps: `npm install`
- Format (write): `npm run format`
- Format check: `npm run format:check`
- Lint: `npm run lint`
- Type check: `npm run typecheck`
- Architecture check: `npm run depcruise`
- Test: `npm run test`
- Build: `npm run build`
- Full verify: `npm run verify`

## 4. Architecture Summary

This project uses Feature-Sliced Design (FSD) with 5 layers: `shared → entities → features → widgets → app`. **Route Handlers return data directly via `NextResponse.json()`** (no wrapper). Error handling: `AppError` class + `errorResponse()` helper, or optional `apiHandler` HOF for boilerplate reduction. Request validation uses **Zod schemas** (`.parse()`/`.safeParse()` — Next.js official recommendation). Infrastructure isolation (DB drivers, ORMs) enforced by Dependency Cruiser (see `examples/.dependency-cruiser.cjs`). See `.agents/rules/architecture.md` for full rules.

## 5. Requirements traceability (RTM)

Every functional requirement gets an ID and a row in `docs/requirements/RTM.md`.

- ID formats: `FR-{DOMAIN}-{NNN}` for functional, `NFR-{CATEGORY}-{NNN}` for
  non-functional, `TC-{DOMAIN}-{NNN}` for test cases (all three digits,
  zero-padded). `ORDER` in examples is a placeholder — define your domain
  prefixes in the table at the top of RTM.md. Never reuse a retired number;
  set Status to `Deprecated` instead of deleting the row.
- When a PR implements or changes an FR, update its RTM row **in the same PR**.
  The row links the FR to its issue, ADRs, operationId, component paths,
  and tests (`TC-...` plus the test file path).
- Row completeness follows Status: `Draft`/`Design` rows need only ID, Summary,
  and Status; `Done` rows must list at least one existing component path and
  one existing test path. Any path you do write must exist (except on
  `Deprecated` rows, which keep their historical paths after code removal).
- The `V_rtm` section of `validate.sh` checks ID format, duplicates, the
  status gate above, and that referenced paths exist. If you don't use the
  RTM, the check stays silent; to drop it entirely, delete the `V_rtm`
  section in validate.sh (one block, marked by its header comment).
- Full rules: `.agents/rules/documentation.md`.

## 6. Verification Rules

After any code change, run `npm run verify` (or the individual steps in order).
Never declare a task complete until the full loop passes.
See `.agents/rules/verification-loop.md`.

## 7. Test Modification

When modifying code, always update tests in the same commit. Determine affected test layers:

- **Route/component added** → create unit + snapshot tests
- **Signature/schema changed** → update existing assertions and fixtures
- **Logic modified** → update assertions, add edge cases
- **Dependency bumped** → review snapshot diff before `npm test -- -u`
- **Refactoring only** → do NOT touch tests; if they break, the refactoring is wrong

Snapshot rule: **never `npm test -- -u` without reading the diff first**.

Full rules and checklist: `.agents/rules/test-modification.md`

## 8. Git Workflow

- Never commit directly to `main`
- Conventional Commits required: `<type>(<scope>): <description>`
- Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`
- Local enforcement: Husky `pre-commit` (lint-staged) + `commit-msg` (commitlint)
- CI enforcement: `wagoid/commitlint-github-action@v6`
- See `.agents/rules/git-workflow.md`

## 9. Business / Domain Terms

<!--
  DEFAULT: "N/A — add project-specific terms here as the codebase evolves."
  REPLACE the line below with project-specific terminology, or leave the
  default string if no domain terms exist yet.
-->
N/A — add project-specific terms here as the codebase evolves.
