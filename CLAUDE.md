# {{PROJECT_NAME}}

> Generated from llm-setup-prompts/typescript-template.
> Replace `{{PROJECT_NAME}}` with the actual project name before use.

## Project Overview

TypeScript / Next.js 15 (App Router) project scaffolded via
llm-setup-prompts/typescript-template. Architecture follows Feature-Sliced Design (FSD).

## Tech Stack

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

## Primary Commands

- Install deps: `npm install`
- Format (write): `npm run format`
- Format check: `npm run format:check`
- Lint: `npm run lint`
- Type check: `npm run typecheck`
- Test: `npm run test`
- Build: `npm run build`
- Full verify: `npm run verify`

## Architecture Summary

This project uses Feature-Sliced Design (FSD) with 5 layers:
`shared → entities → features → widgets → app`.
Each layer may only import from lower layers.
Every FSD slice exposes its public API through `index.ts` (barrel file) only.
Direct imports into a slice's internal files are prohibited (`no-public-api-sidestep`).
See `.claude/rules/architecture.md` for full rules and examples.

## Verification Rules

After any code change, run `npm run verify` (or the individual steps in order).
Never declare a task complete until the full loop passes.
See `.claude/rules/verification-loop.md`.

## Test Modification

When modifying code, always update tests in the same commit. Determine affected test layers:

- **Route/component added** → create unit + snapshot tests
- **Signature/schema changed** → update existing assertions and fixtures
- **Logic modified** → update assertions, add edge cases
- **Dependency bumped** → review snapshot diff before `npm test -- -u`
- **Refactoring only** → do NOT touch tests; if they break, the refactoring is wrong

Snapshot rule: **never `npm test -- -u` without reading the diff first**.

Full rules and checklist: `.claude/rules/test-modification.md`

## Git Workflow

- Never commit directly to `main`
- Conventional Commits required: `<type>(<scope>): <description>`
- Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`
- Local enforcement: Husky `pre-commit` (lint-staged) + `commit-msg` (commitlint)
- CI enforcement: `wagoid/commitlint-github-action@v6`
- See `.claude/rules/git-workflow.md`

## Business / Domain Terms

<!--
  DEFAULT: "N/A — add project-specific terms here as the codebase evolves."
  REPLACE the line below with project-specific terminology, or leave the
  default string if no domain terms exist yet.
-->
N/A — add project-specific terms here as the codebase evolves.
