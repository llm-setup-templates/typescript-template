# TypeScript / Next.js Template — LLM-Agent-Ready Scaffolding

[한국어 README](./README.ko.md)

> An opinionated Next.js 15 (App Router) + Feature-Sliced Design template
> designed for LLM coding agents (Claude Code / Cursor) to scaffold from an
> empty directory to a green GitHub Actions CI — without human intervention
> mid-setup.

**Empirically verified**: SETUP.md alone drives Claude Code → green CI in 9 min
([proof run](https://github.com/KWONSEOK02/llm-setup-e2e17-typescript/actions/runs/24565977208)).

---

## Why this template exists

JS/TS project scaffolding drowns in choices: app router vs pages, strict tsconfig
or not, ESLint flat config or legacy, which formatter, which test runner, which
architectural convention. This template picks **one defensible answer per layer**
and ships a SETUP.md the LLM agent executes top-to-bottom.

**Pinned choices** (with reasoning):

| Layer | Choice | Why (rejected alternatives) |
|---|---|---|
| Framework | Next.js 15 App Router | Pages Router is legacy path; App Router + Server Components is the modern default |
| Architecture | Feature-Sliced Design (5 layers) | Clean Architecture too abstract for SPA; Atomic Design conflates UI + state |
| TypeScript | strict mode + `@/*` alias | loose mode masks real bugs; relative imports rot on refactor |
| Formatter | Prettier (owns all whitespace) | no more "which ESLint rule formats what" debates |
| Linter | ESLint 9 flat config + `eslint-plugin-fsd-lint` | legacy `.eslintrc.*` is deprecated; fsd-lint enforces layer boundaries automatically |
| Boundary check | Dependency Cruiser | ESLint rules cannot express "no feature imports Prisma" cleanly |
| Test | Jest 29 + ts-jest + jsdom | Vitest has a separate ref variant; picked Jest for broader ecosystem |
| Git hooks | Husky 9 (pre-commit + commit-msg) | catch format/commit-message issues before push |

---

## Who should use this

**Persona 1 — Solo developer or small team building a Next.js web app**
- Solves: "which tsconfig flags? which ESLint rules? which folder layout?"
- Does NOT solve: design decisions (Tailwind vs CSS-in-JS, which state lib)

**Persona 2 — LLM-assisted development (Claude Code, Cursor)**
- Solves: SETUP.md is fail-fast, Husky blocks bad commits, Dependency Cruiser blocks boundary violations — the agent gets concrete errors to fix
- Does NOT solve: business domain decisions; the template scaffolds structure, not product

**Persona 3 — Team adopting FSD for the first time**
- Solves: directory structure + barrel files + eslint-plugin-fsd-lint rules come pre-configured
- Does NOT solve: migrating existing code to FSD — this is greenfield-first

**Persona 4 — Instructor setting up a reproducible React/Next.js course**
- Solves: every student gets identical stack; CI catches mistakes at grading time
- Does NOT solve: curriculum

---

## Who should NOT use this

- You want Pages Router (not App Router) → fork, rewrite Phase 1 scaffolding
- You dislike FSD → fork, delete `.claude/rules/architecture.md`, remove fsd-lint plugin
- You need an SSG-heavy static site → Astro or 11ty is a better fit
- You are not using TypeScript → this template is TS-only

---

## Quick fit check

Answer all three before cloning:

1. **Greenfield Next.js 15 App Router project?** If no — this template targets fresh scaffolding; migrating an existing codebase requires manual adaptation.
2. **Willing to learn FSD if you do not know it?** (layers / barrels / import direction — roughly one day of reading) If no — pick a non-FSD template.
3. **OK with strict tsconfig + ESLint 9 flat config + Husky from day 0?** If no — use a lighter starter.

All three yes → proceed to `SETUP.md`.

---

## FSD quick orientation — if this is your first time

FSD organizes `src/` into 5 layers with a strict one-way dependency direction:

```
src/
├── shared/      — atomic primitives (UI kit, utils, types) — imports nothing else
├── entities/    — business objects (User, Product) — imports only shared
├── features/    — user-facing features (auth, checkout) — imports shared + entities
├── widgets/     — composite UI blocks — imports shared + entities + features
└── app/         — Next.js App Router root — may import any layer
```

Rules enforced automatically by `eslint-plugin-fsd-lint`:

- Upper layer imports lower: allowed (`features/` can use `entities/`)
- Lower layer imports upper: **blocked** (`entities/` cannot use `features/`)
- Same-layer cross-slice imports: only through the slice's public `index.ts` barrel
- Direct deep imports that bypass the barrel: **blocked** (`no-public-api-sidestep`)

Start by putting everything in `shared/` until you have a clear reason to split.
Promote code to `entities/` when there is a coherent business object; to `features/`
when there is a user-visible action. Over-engineering the layer split early is the
most common mistake.

---

## Verification loop (6 steps)

Every code change must pass these steps in order before the task is declared done:

```bash
npm run format:check   # Prettier
npm run typecheck      # tsc --noEmit
npm run depcruise      # Dependency Cruiser (infra isolation + cross-feature)
npm run lint           # ESLint 9
npm run test           # Jest 29
npm run build          # next build
```

Or run all at once: `npm run verify`

This loop matches the CI workflow exactly — no divergence by design.

---

## What's inside

- Setup flow: [SETUP.md](./SETUP.md) — 14 sections, Phase 0 → Phase 8
- AI agent rules: [CLAUDE.md](./CLAUDE.md)
- Architecture (FSD deep dive): [.claude/rules/architecture.md](./.claude/rules/architecture.md)
- Verification loop: [.claude/rules/verification-loop.md](./.claude/rules/verification-loop.md)
- Test modification: [.claude/rules/test-modification.md](./.claude/rules/test-modification.md)
- Git workflow: [.claude/rules/git-workflow.md](./.claude/rules/git-workflow.md)

---

## Related templates

- [python-template](https://github.com/llm-setup-templates/python-template) — Python 3.13 + 3 archetypes (script / web / library)
- [spring-template](https://github.com/llm-setup-templates/spring-template) — Spring Boot 3 + layered architecture

---

## License

MIT
