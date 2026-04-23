# Git Workflow Rules

## Branch Strategy
- `main` is protected — never commit directly.
- Feature branches: `feat/<N>-<short-name>`
- Fix branches: `fix/<short-name>`
- Refactor: `refactor/<short-name>`
- Docs: `docs/<short-name>`
- All branches base on `main` unless stated otherwise.

## Commit Convention — Conventional Commits 1.0
Pattern: `<type>(<scope>): <description>`

Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`

Scope MUST be lowercase kebab-case. Description MUST start lowercase.

## One Task = One Commit
Each atomic task is one commit. No "WIP" or "misc" commits.

## No Force Push on Main
Force pushing to `main` is prohibited under any circumstance.
Use `git reset --soft HEAD~N` locally before the first push if commits
need rewriting.

## Pre-Push Gate (MANDATORY)
Before `git push` on any branch, run the inline Git Safety Gate bash block
from **SETUP.md § Phase 8.1**. The gate checks:
- Current branch is not `main`
- Last 10 commit messages match the Conventional Commits regex
- No uncommitted changes in working tree

The gate is embedded directly in SETUP.md (not a separate script file) so
that the LLM agent can execute it inline without extra file lookups.

## TypeScript-specific: Local Git Hooks (Husky)

This template installs Husky 9 for local commit enforcement.
Spring/Python templates use `wagoid/commitlint-github-action@v6` in CI instead.

### Hook: pre-commit
Runs `npx lint-staged` — formats and lints only staged files.
Config: `.lintstagedrc.json`

### Hook: commit-msg
Runs `npx --no -- commitlint --edit $1` — validates commit message convention.
Config: `commitlint.config.mjs`

### Note
The CI workflow (`ci.yml`) also runs `wagoid/commitlint-github-action@v6` as a
belt-and-suspenders check for commit messages on pull requests.
The local Husky hook provides the primary first-line defense for all commits.
