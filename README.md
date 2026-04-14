# typescript-template

> LLM-agent-driven TypeScript / Next.js project scaffolding template.
> Hand `SETUP.md` to Claude Code / Cursor and get a green CI pipeline on GitHub.

[![CI](https://github.com/YOUR_ORG/typescript-template/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_ORG/typescript-template/actions/workflows/ci.yml)
[![CodeRabbit](https://img.shields.io/badge/CodeRabbit-Active-brightgreen)](https://coderabbit.ai)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

## Purpose

This template enables an autonomous coding agent (Claude Code / Cursor) to
scaffold a production-grade TypeScript / Next.js 15 (App Router) project from
an empty directory to a green CI pipeline on GitHub — without human
intervention beyond providing the repo name, visibility, and final approval.

The generated project enforces:
- **Feature-Sliced Design (FSD)** via `eslint-plugin-fsd-lint`
- **Barrel File convention** (`index.ts` public API per slice)
- **Husky** pre-commit hooks for local lint-staged + commitlint enforcement
- **Strict TypeScript** (`strict: true` + `noUncheckedIndexedAccess`)
- **CodeRabbit** automated PR reviews focused on architecture, not formatting

## Who is this for

- Developers using Claude Code / Cursor who want a reproducible TypeScript scaffold
- Students / teams learning modern Next.js + FSD tooling in one shot
- Teams migrating from outdated setups to 2026 best practices

## Quick Start

1. Fork or clone this template
2. Open the project root in Claude Code / Cursor
3. Ask: "Please set up a new project using SETUP.md"
4. The agent executes Phase 0 → Phase 8 and pushes to GitHub

## What's Inside

- `SETUP.md` — the main agent prompt (14 sections, Phase 0 → Phase 8)
- `CLAUDE.md` — base CLAUDE.md for the generated project (replace `{{PROJECT_NAME}}`)
- `.claude/rules/` — modular AI behavior rules (code-style, git, architecture, verification-loop)
- `.claude/skills/claude-md-reviewer/` — English skill for reviewing CLAUDE.md quality
- `examples/` — ready-to-copy config file snippets (Prettier, ESLint, Jest, Husky, CI, etc.)
- `CODERABBIT-PROMPT-GUIDE.md` — how to author `.coderabbit.yaml` path_instructions

## Phase Overview (SETUP.md — 14 sections)

1. Preface + LLM meta-instructions
2. Prerequisites (Node 20, npm, gh CLI)
3. Phase 0 — Repo Init + `.nvmrc`
4. Phase 1 — Scaffolding (`create-next-app`)
5. Phase 1.5 — FSD directory scaffold (`fsd-scaffold.sh`)
6. Phase 2 — DevDeps + Husky init
7. Phase 3 — Config files (Prettier / ESLint / Jest / commitlint / lint-staged / Husky hooks)
8. Phase 4 — package.json scripts
9. Phase 5 — CI Workflow (`.github/workflows/ci.yml`)
10. Phase 6 — CodeRabbit setup (`.coderabbit.yaml`)
11. Phase 7 — Local Verify (`npm run verify`)
12. Phase 8 — First Push + CI Green (Git Safety Gate + `gh run watch`)
13. Troubleshooting
14. Config Reference Appendix

## Why this template exists

Most TypeScript/Next.js starter templates require manual configuration steps
and assume a human developer is reading documentation. This template is
authored for LLM agents: every decision is made upfront, every command is
fully spelled out, and the verification loop matches CI exactly. The result
is a reproducible "from zero to green CI" flow that works without human
mid-task intervention.

## Extension & Customization

- **Storybook**: not included by default. See `.claude/rules/architecture.md` extension notes.
- **Python archetypes**: see `llm-setup-prompts/python-template/` (03 Phase).
- Override rules in `.claude/rules/` to match your team's conventions.

## License

MIT
