# TypeScript / Next.js Template — LLM Agent Setup Prompt

> This document instructs an autonomous coding agent (Claude Code / Cursor)
> to scaffold a new TypeScript / Next.js project from an empty directory to a green
> CI pipeline on GitHub.

## 1. Preface — LLM Agent Meta-Instructions

You are an autonomous coding agent. Execute this document Phase by Phase
from top to bottom.

### Execution Rules
- Use the Bash tool for shell commands. Use the Write tool for config files.
- Each Phase is **fail-fast**. On failure, consult the Troubleshooting
  section and retry up to **3 times** before escalating to the human.
- Never skip the **Local Verify** phase. Do not claim completion until CI
  shows green on the first push (use `gh run watch`).
- Use **pinned versions** from the Config Reference Appendix. Do not guess.
- Do not ask the human for input during execution except for:
  (a) GitHub repo name (`{{PROJECT_NAME}}`)
  (b) visibility (private/public)
  (c) final approval before pushing

### Success Criteria
- [ ] GitHub repository created and first commit pushed
- [ ] All CI jobs pass on the first push
- [ ] CodeRabbit app connected (or fallback configured)
- [ ] Local `npm run verify` passes from a fresh clone

## 2. Prerequisites
- `gh` CLI authenticated (`gh auth status`)
- `git` ≥ 2.40
- Node.js ≥ 20
- npm installed

## 3. Phase 0 — Repo Init

Ask the human for `{{PROJECT_NAME}}` (the GitHub repository name) before running.

```bash
gh auth status || exit 1
mkdir {{PROJECT_NAME}} && cd {{PROJECT_NAME}}
git init -b main
gh repo create {{PROJECT_NAME}} --private --source=. --remote=origin
# Note: .nvmrc is created in Phase 1 AFTER create-next-app, because
# create-next-app refuses to scaffold into a non-empty directory.
```

**Order note**: do NOT create `.nvmrc` before Phase 1 — `create-next-app`
aborts if the target directory contains any files.

## 3.1 Phase 0.5 — Clone Template Reference

Throughout Phases 2~6 the agent copies files from `examples/`, `docs/`,
`.github/`, and other template-owned directories. In the `--source=.`
path used in Phase 0, the new repo is empty — these files do NOT exist
yet. Clone the template as a **read-only reference**:

```bash
gh repo clone llm-setup-templates/typescript-template /tmp/ref-ts
```

Throughout this document, when instructed to copy from `examples/X`,
use `cp /tmp/ref-ts/examples/X .` (not `cp examples/X .`).

Note on dotfiles: `examples/.dependency-cruiser.cjs`, `examples/.prettierignore`,
`examples/.prettierrc`, `examples/.lintstagedrc.json`, and `examples/.coderabbit.yaml`
are dotfiles and **not visible with plain `ls`**. Use `ls -A examples/` or
copy them explicitly by name.

Clean up after Phase 8:

```bash
rm -rf /tmp/ref-ts
```

> **Alternative (`--template` path)**: If you started with
> `gh repo create --template ...` instead of Phase 0's `--source=.`, the
> template files are already in your repo and Phase 0.5 is not needed.
> However, the `--template` path has drawbacks:
> 1. GitHub auto-creates an "Initial commit" message that violates the
>    Conventional Commits gate in Phase 8
> 2. `npx create-next-app@latest .` in Phase 1 refuses non-empty directories
>
> For LLM autonomous flows, **`--source=.` (Phase 0) is the recommended path**.

## 4. Phase 1 — Scaffolding

```bash
npx create-next-app@latest . --ts --app --tailwind --eslint=false \
  --src-dir --import-alias "@/*" --no-turbopack --use-npm

# After scaffold: create .nvmrc (deferred from Phase 0)
echo "20" > .nvmrc
```

> `--src-dir` creates a `src/` directory. FSD layers live under `src/`.
> `--eslint=false` skips Next.js default ESLint config — we install ESLint 9 flat config manually in Phase 3.
> `--no-turbopack` keeps the bundler compatible with tooling examples in this template.
> `--use-npm` pins the lockfile format across contributors.

**Next 16 caveat**: create-next-app 16+ generates its own `CLAUDE.md` that
just re-exports `@AGENTS.md`. The template's `CLAUDE.md` (with project
overview, tech stack, and architecture pointers) is overwritten. After
Phase 1, restore the template `CLAUDE.md` from this repo and substitute
`{{PROJECT_NAME}}`.

### Phase 1 Post-scaffold Cleanup

After `create-next-app` completes:

1. **Restore template CLAUDE.md** — Next 16's generated `CLAUDE.md` is a
   stub (`@AGENTS.md` redirect) that overwrites the template's rich version.
   Restore from `/tmp/ref-ts/CLAUDE.md` and substitute `{{PROJECT_NAME}}`.

2. **Remove AGENTS.md** — Next 16 generates `AGENTS.md` alongside the
   redirect stub. This template does not use an AGENTS.md; remove it:
   ```bash
   rm -f AGENTS.md
   ```

3. **`--eslint=false` caveat** — Next 16 ignores this flag and installs
   ESLint packages anyway. Harmless because Phase 2 pins our versions
   explicitly, but be aware the initial package.json may have ESLint
   packages before Phase 2 runs.

## 4.5 Phase 1.5 — FSD Directory Scaffold

```bash
chmod +x examples/fsd-scaffold.sh
bash examples/fsd-scaffold.sh
```

Or inline (if examples/ not available):

```bash
for d in shared/ui shared/lib shared/config shared/api shared/model \
          entities features widgets; do
  mkdir -p "src/$d" && touch "src/$d/index.ts"
done
```

This creates the 5-layer FSD directory structure under `src/` with empty `index.ts` barrel files.

## 5. Phase 2 — DevDeps Installation

```bash
npm i -D \
  eslint@^9 \
  eslint-config-next \
  @eslint/eslintrc \
  eslint-plugin-fsd-lint \
  prettier \
  prettier-plugin-tailwindcss \
  jest@^29 \
  @types/jest \
  ts-jest \
  ts-node \
  jest-environment-jsdom \
  @testing-library/react \
  @testing-library/jest-dom \
  husky@^9 \
  @commitlint/cli \
  @commitlint/config-conventional \
  lint-staged \
  dependency-cruiser

npx husky init
```

## 6. Phase 3 — Config Files

Write the following config files (exact content in Appendix § Config Reference):

- `.prettierrc` — Prettier formatting options
- `.prettierignore` — files Prettier should skip
- `eslint.config.mjs` — ESLint 9 flat config with FSD boundary rules
- `jest.config.ts` — Jest 29 + ts-jest config (`setupFilesAfterEnv`)
- `jest.setup.ts` — Jest setup file (referenced by `setupFilesAfterEnv` in jest.config.ts)
- `commitlint.config.mjs` — Conventional Commits enforcement (must be `.mjs`; `wagoid/commitlint-github-action@v6` rejects `.js` since 6.2)
- `.lintstagedrc.json` — lint-staged per-extension commands
- `.husky/pre-commit` — runs `npx lint-staged`
- `.husky/commit-msg` — runs `npx --no -- commitlint --edit "$1"`
- `.gitattributes` — enforces LF line endings
- `.gitignore` — standard Next.js ignores
- `.dependency-cruiser.cjs` — Dependency Cruiser config for FSD infra isolation
- `tsconfig.json` — merge `tsconfig.strict-additions.json` options into `compilerOptions`, and add `"examples"` to the `"exclude"` array

> **Dotfile visibility**: `.dependency-cruiser.cjs`, `.prettierignore`,
> `.prettierrc`, `.lintstagedrc.json`, `.coderabbit.yaml` are dotfiles.
> They do NOT appear in `ls examples/` — use `ls -A examples/` or copy
> by name: `cp /tmp/ref-ts/examples/.dependency-cruiser.cjs .`

Merge `examples/tsconfig.strict-additions.json` into your project's `tsconfig.json` and exclude `examples/` from type checking:
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

Also replace `{{PROJECT_NAME}}` in `CLAUDE.md` with the actual project name.

## 7. Phase 4 — Build / Run Scripts

Merge the following into the `"scripts"` section of `package.json`
(content from `examples/package.scripts.json`):

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint",
    "typecheck": "tsc --noEmit",
    "depcruise": "depcruise src --config .dependency-cruiser.cjs",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "verify": "npm run format:check && npm run typecheck && npm run depcruise && npm run lint && npm run test && npm run build",
    "prepare": "husky"
  }
}
```

> **Next 16 note**: `next lint` was removed in Next.js 16. Use `eslint`
> directly (shown above). Do NOT use `"lint": "next lint"`.

> **depcruise note**: `npm run depcruise` enforces FSD infrastructure
> isolation (entities/features MUST NOT import DB drivers directly).
> This step runs before `lint` in `verify` so architectural violations
> fail fast, before any test/build cost. Matches CI step order.

## 8. Phase 5 — CI Workflow

Create the workflow directory first, then write the CI config:

```bash
mkdir -p .github/workflows
```

Then write `.github/workflows/ci.yml` (exact content in Appendix § CI
Reference). On a fresh `create-next-app` scaffold `.github/` does not
exist yet, so the `mkdir -p` is required before using plain `echo >`
or `cat > .github/workflows/ci.yml` in an agent that shells out for
file writes.

## 8.5 Phase 5.5 — Documentation Scaffold

This phase installs the documentation tree and GitHub governance files.

### How installation works

When a project is created with `gh repo create --template
llm-setup-templates/typescript-template` (or by forking this repo), the
following are **already present in the working directory**:

```
.github/
├── ISSUE_TEMPLATE/{feature,bug,adr,config}.yml
├── PULL_REQUEST_TEMPLATE.md
└── CODEOWNERS                          # placeholder — customize

docs/
├── README.md                           # decision tree + navigation
├── requirements/
│   ├── RTM.md
│   └── _FR-template.md
├── architecture/
│   ├── overview.md                     # C4 Lv1 (Core)
│   ├── containers.md                   # C4 Lv2 (Extended)
│   ├── DFD.md                          # Data Flow Diagram (Extended)
│   └── decisions/
│       ├── README.md
│       ├── _ADR-template.md
│       └── _RFC-template.md
├── reports/                            # opt-in module
│   ├── README.md
│   ├── _spike-test-template.md
│   ├── _benchmark-template.md
│   ├── _api-analysis-template.md
│   └── _paar-template.md
├── briefings/                          # opt-in module
│   ├── README.md
│   └── _template/
└── data/
    └── dictionary.md                   # Extended module
```

The agent's job is not to generate these files — they ship with the
template. The agent's job is to **trim modules the human doesn't want**,
customize **placeholders**, and then register the decision.

### 8.5.1 Module selection

The docs/ structure has 4 modules: core (always), reports, briefings, extended.

**In autonomous/LLM mode** (default for this template): use `core` only.
Skip trimming the other modules if they don't exist yet (valid under the
`--source=.` path).

**In interactive mode**: ask the human to confirm the selection:

```
Documentation modules to keep (default = core only):
- core       [always kept]  FR / RTM / ADR / RFC / overview
- reports    [y/n]          portfolio / spike / benchmark / API / PAAR
- briefings  [y/n]          dated, frozen interview & talk archives
- extended   [y/n]          C4 Lv2 containers / DFD / Extended DD
```

| Module | Default | Include condition |
|--------|---------|-------------------|
| core | YES | always |
| reports | NO | user confirms OR `--with-reports` flag |
| briefings | NO | user confirms OR `--with-briefings` flag |
| extended | NO | user confirms OR `--with-extended` flag |

**Source-mode note**: If your repo came from Phase 0 `--source=.`, the
docs/ folder is empty by default. Copy from `/tmp/ref-ts/docs/core/` in
core-only mode (see Phase 0.5). If you started from `--template`,
docs/ is pre-populated and 5.5 becomes trim-only.

### 8.5.2 Trim unwanted modules

```bash
# If reports is NOT wanted:
rm -rf docs/reports/

# If briefings is NOT wanted:
rm -rf docs/briefings/

# If extended is NOT wanted:
rm -f docs/architecture/containers.md docs/architecture/DFD.md
rm -rf docs/data/
```

### 8.5.3 Replace placeholders

Files with placeholders to edit after template instantiation:

- `.github/CODEOWNERS` — replace `@YOUR_ORG/*` placeholders with real
  team handles, or delete rows you don't need. If the project has no
  teams, a single `* @YOUR_USERNAME` line works
- `docs/README.md` — top-of-file project name and one-line description
- `docs/architecture/overview.md` — project name, actors, external
  systems in the Mermaid diagram
- `docs/requirements/RTM.md` — remove the example row; the table
  starts empty

### 8.5.4 Update the documentation map

Edit `.claude/rules/documentation.md` to remove module sections that
aren't installed. This keeps Claude's decision tree accurate when it
later asks "where does this new document go?"

### 8.5.5 Self-check

Run `bash validate.sh`. V9 through V16 verify:

- `examples/` ↔ `SETUP.md Appendix` code blocks stay in sync
- `.github/ISSUE_TEMPLATE/*.yml` are valid YAML
- `docs/` module structure matches the human's selection
- No dangling references (e.g. a trimmed `docs/reports/` still linked
  from `docs/README.md`)

## 9. Phase 6 — CodeRabbit Setup

1. Write `.coderabbit.yaml` **at the project root** (exact content in
   Appendix § CodeRabbit Reference). CodeRabbit only auto-detects the
   config at the repo root — `.github/.coderabbit.yaml` is NOT picked
   up. The `examples/.coderabbit.yaml` file in this template is the
   source to copy; the destination is `./.coderabbit.yaml`.
2. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
3. If CodeRabbit trial is unavailable, fall back to the Claude Code Review
   Action (Appendix § Fallback): write `.github/workflows/claude-review.yml`
   and configure `ANTHROPIC_API_KEY` in repo Secrets.

## 10. Phase 7 — Local Verify (fail-fast)

First, normalize formatting and add a placeholder test so a fresh scaffold
passes `format:check` and `jest`:

```bash
# 1) Format files generated by create-next-app to match .prettierrc
npm run format

# 2) Add a smoke test if no test files exist yet (jest exits 1 on empty test set)
mkdir -p src/shared/lib
cat > src/shared/lib/smoke.test.ts <<'EOF'
describe('smoke', () => {
  it('runs', () => {
    expect(1 + 1).toBe(2);
  });
});
EOF
```

Then run the full verify pipeline:

```bash
npm run verify
```

All checks must pass before Phase 8.

## 11. Phase 8 — First Push + CI Green

### 11.1 Initial commit (required before Gate 1)

Gate 1 calls `git rev-parse --abbrev-ref HEAD` which requires at least
one commit to exist. On a fresh `git init` repo there is no HEAD yet,
so stage and commit all scaffolded files first:

```bash
git add .
git commit -m "feat(scaffold): initial project setup"
```

### 11.2 Git Safety Gate (MANDATORY — run before push)

```bash
# Gate 1: branch check
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "BLOCKED: direct commit on main. Moving to feat/initial-setup."
  git branch feat/initial-setup && git checkout feat/initial-setup
fi

# Gate 2: commit message convention
INVALID=$(git log --format=%s -10 | \
  grep -vE '^(feat|fix|docs|chore|refactor|test|ci)(\([a-z0-9-]+\))?: .+' || true)
if [ -n "$INVALID" ]; then
  echo "BLOCKED: commit message convention violation:"
  echo "$INVALID"
  echo "Fix: git reset --soft HEAD~N and rewrite commits. DO NOT force push."
  exit 1
fi

# Gate 3: uncommitted changes
git diff --quiet && git diff --cached --quiet || {
  echo "BLOCKED: uncommitted changes exist."
  exit 1
}
```

### 11.3 Push + watch CI

CI triggers on `push: [main, feat/**, fix/**, refactor/**]` and on
`pull_request: [main]`. On a brand-new repo created via `gh repo create
--source=. --remote=origin`, the remote has no branches yet. Seed `main`
by pushing the feature-branch commit directly into `main` on first push:

```bash
# Seed main from the feature branch (required on a fresh repo
# with no remote branches yet — CI's `push: [main, ...]` trigger
# needs main to exist before the feature-branch push fires it).
git push origin $(git rev-parse --abbrev-ref HEAD):main

# Push the feature branch and track it. This fires CI a second time,
# but on the branch ref, so two separate runs are produced.
git push -u origin $(git rev-parse --abbrev-ref HEAD)

# Watch the most recent run for THIS feature branch (not main),
# and exit non-zero if the run fails — lets the agent detect
# CI failure programmatically instead of relying on terminal output.
gh run watch --exit-status "$(gh run list --branch "$(git rev-parse --abbrev-ref HEAD)" --limit 1 --json databaseId --jq '.[0].databaseId')"
```

> **Why target the branch run explicitly**: `gh run watch` without an
> ID picks the most recently *queued* run, which can be either the
> `main` push or the branch push depending on timing. Scoping to the
> branch run gives deterministic CI monitoring and makes `--exit-status`
> reflect the branch's actual verdict.

### 11.4 Success Declaration

Only after `gh run watch` reports all jobs green, you may report the task
as complete to the human.

## 12. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `jest.config.ts` fails to parse (`ts-node` error) | `ts-node` missing from devDependencies | `npm i -D ts-node`, then retry |
| Jest ESM/CJS conflict (`SyntaxError: Cannot use import statement`) | Next.js 15 ESM modules not transformed by Jest CJS | Add `transform` to `jest.config.ts`: `extensionsToTreatAsEsm: ['.ts', '.tsx']` + `ts-jest` ESM preset |
| Windows CRLF (Prettier fails in CI) | Files saved with CRLF on Windows | Apply `.gitattributes` with `* text=auto eol=lf`, then `git add --renormalize .` |
| CI build fails on missing env vars | `NEXT_PUBLIC_*` vars not present in CI | Inject dummy values in `ci.yml` `env:` block or route through GitHub Secrets |
| `eslint-plugin-fsd-lint` flat config unsupported | Plugin ships legacy config only | Wrap with `@eslint/eslintrc` `FlatCompat.plugins()` (see `examples/eslint.config.mjs`) |
| `depcruise` rule `no-cross-feature-import` also blocks same-feature calls | `pathNot: '^src/features/$1/'` back-reference not honored by older dependency-cruiser | Upgrade to `dependency-cruiser@^16`; if the glitch persists, note that `eslint-plugin-fsd-lint`'s `forbidden-imports` is the primary enforcer and the depcruise rule can be softened to `warn`. See inline comment in `examples/.dependency-cruiser.cjs` |
| `prettier --check` fails on `.github/ISSUE_TEMPLATE/*.yml` (YAML parse error) | Prettier's YAML parser chokes on multi-line strings with backticks | Add `.github/` to `.prettierignore` (already in Fix 2's updated template). If still failing, verify `.prettierignore` has the `.github/` line |

## 13. Essential Checklist

- [ ] `gh auth status` passed
- [ ] Node.js version verified (≥ 20)
- [ ] Scaffolding command ran in an empty or newly-created directory
- [ ] All config files written
- [ ] Phase 5.5 Core files written (`.github/` + `docs/{requirements,architecture}`)
- [ ] Phase 5.5 opt-in modules selected + written (if any)
- [ ] `npm run verify` passes locally
- [ ] `bash validate.sh` passes (all V1–V16 PASS)
- [ ] Git Safety Gate passed
- [ ] `gh run watch` shows green CI
- [ ] CodeRabbit app installed or fallback configured

## 14. Config Reference Appendix

### § Pinned Versions

| Package | Version |
|---------|---------|
| Node.js | 20 LTS (`.nvmrc`: `20`) |
| Next.js | 15.x (create-next-app@latest) |
| TypeScript | 5.x (bundled with Next.js) |
| ESLint | ^9 |
| Prettier | latest |
| Jest | ^29 |
| ts-jest | ^29 |
| ts-node | latest |
| Husky | ^9 |
| @commitlint/cli | latest |
| @commitlint/config-conventional | latest |
| lint-staged | latest |
| eslint-plugin-fsd-lint | latest |
| dependency-cruiser | latest |

### § Config File Contents

#### `.prettierrc`
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80,
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

#### `.prettierignore`
```
.next/
node_modules/
dist/
coverage/
*.min.js
public/
examples/
# GitHub workflow/template YAML files — Prettier's YAML parser fails
# on multi-line strings with backticks (e.g., .github/ISSUE_TEMPLATE/adr.yml)
.github/
```

> **examples/ parity**: ESLint (`globalIgnores`), tsconfig
> (`exclude: ["examples"]`), and Prettier (`.prettierignore`) must all
> exclude `examples/`. Dropping any one of them causes `npm run verify`
> to fail on the template files that were meant to be snippets for
> copy-paste, not live source.

#### `eslint.config.mjs`

**Next 16 compatibility**: `eslint-config-next` 16 exports flat configs
directly (`eslint-config-next/core-web-vitals`, `eslint-config-next/typescript`).
Using `FlatCompat.extends('next/...')` on these now throws
`TypeError: Converting circular structure to JSON`. Import them directly
and only use `FlatCompat.plugins()` for legacy plugins (`eslint-plugin-fsd-lint`).

```js
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { defineConfig, globalIgnores } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';
import nextTs from 'eslint-config-next/typescript';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  ...compat.plugins('fsd-lint'),
  {
    rules: {
      'fsd-lint/forbidden-imports': 'error',
      'fsd-lint/no-relative-imports': 'error',
      'fsd-lint/no-public-api-sidestep': 'error',
      'no-console': ['warn', { allow: ['warn', 'error', 'info'] }],
    },
  },
  globalIgnores([
    '.next/**',
    'out/**',
    'build/**',
    'coverage/**',
    'next-env.d.ts',
    'examples/**',
  ]),
]);

export default eslintConfig;
```

#### `jest.config.ts`
```ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        tsconfig: {
          jsx: 'react-jsx',
        },
      },
    ],
  },
  setupFilesAfterEnv: ['<rootDir>/jest.setup.ts'],
  testMatch: ['<rootDir>/src/**/*.test.{ts,tsx}'],
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
};

export default config;
```

**Important**: The Jest config key is `setupFilesAfterEnv` (NOT `setupFilesAfterFramework`).

#### `jest.setup.ts`

```ts
import '@testing-library/jest-dom';
```

This file is referenced by `setupFilesAfterEnv` in `jest.config.ts`.
It runs before every test file. Add global test utilities, custom matchers,
or polyfills here as the project grows.

#### `commitlint.config.mjs`

> **Must be `.mjs`**: `wagoid/commitlint-github-action@v6` rejects `.js`
> extensions with `.js extension is not allowed for the configFile, please
> use .mjs instead`. Use ESM `export default` syntax.

```js
/** @type {import('@commitlint/types').UserConfig} */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'chore', 'refactor', 'test', 'ci'],
    ],
    'scope-case': [2, 'always', 'kebab-case'],
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 72],
  },
};
```

Update `.github/workflows/ci.yml` step accordingly:
`configFile: commitlint.config.mjs`

#### `.lintstagedrc.json`
```json
{
  "*.{ts,tsx,js,jsx,mjs,cjs}": ["prettier --write", "eslint --fix"],
  "*.{json,md,yaml,yml,css}": ["prettier --write"]
}
```

#### `.husky/pre-commit`

> Husky 9 removed the legacy `husky.sh` sourcing. Hook files are now plain
> commands — do NOT add shebang or source lines; Husky will warn if present.

```sh
npx lint-staged
```

#### `.husky/commit-msg`
```sh
npx --no -- commitlint --edit "$1"
```

#### `.gitattributes`
```
* text=auto eol=lf
*.bat text eol=crlf
*.{png,jpg,jpeg,gif,webp,ico,woff,woff2,ttf,eot} binary
```

#### `.gitignore`
```
# dependencies
node_modules/
.pnp
.pnp.js

# testing
coverage/

# next.js
.next/
out/

# production
build/
dist/

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts
```

#### `tsconfig.strict-additions.json`
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

Merge these options into your project's `tsconfig.json` `compilerOptions`.

#### `package.scripts.json` (merge into `package.json`)
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint",
    "typecheck": "tsc --noEmit",
    "depcruise": "depcruise src --config .dependency-cruiser.cjs",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "verify": "npm run format:check && npm run typecheck && npm run depcruise && npm run lint && npm run test && npm run build",
    "prepare": "husky"
  }
}
```

#### `fsd-scaffold.sh`
```bash
#!/usr/bin/env bash
# FSD 5계층 + 빈 index.ts barrel 파일 자동 생성
set -euo pipefail

for d in \
  shared/ui \
  shared/lib \
  shared/config \
  shared/api \
  shared/model \
  entities \
  features \
  widgets; do
  mkdir -p "src/$d"
  if [ ! -f "src/$d/index.ts" ]; then
    touch "src/$d/index.ts"
    echo "Created src/$d/index.ts"
  fi
done

# NOTE: pages/ 계층은 Next.js Pages Router 사용 시에만 추가
echo "FSD scaffold complete."
```

### § CI Reference

```yaml
name: CI

on:
  push:
    branches: [main, 'feat/**', 'fix/**', 'refactor/**']
  pull_request:
    branches: [main]

jobs:
  quality:
    name: Format · Typecheck · Lint · Test · Build
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Validate commit messages
        uses: wagoid/commitlint-github-action@v6
        with:
          configFile: commitlint.config.mjs

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: '.nvmrc'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Format check
        run: npm run format:check

      - name: Type check
        run: npm run typecheck

      - name: Architecture boundary check
        run: npm run depcruise

      - name: Lint
        run: npm run lint

      - name: Test
        run: npm run test

      - name: Build
        run: npm run build
        env:
          NEXT_TELEMETRY_DISABLED: 1
```

### § CodeRabbit Reference

```yaml
language: en-US
reviews:
  auto_review:
    enabled: true
    drafts: false
  ignore_formatting: true
  path_instructions:
    - path: 'src/**/*.{ts,tsx}'
      instructions: |
        Review for:
        - FSD boundary violations: no direct import from another feature/entity/widget slice internal path.
          All cross-slice imports must go through the slice's public API (index.ts barrel file).
        - Missing 'use client' directive in components that use hooks, browser APIs, or event handlers.
        - React Server Component / Client Component boundary violations.
        - TypeScript: avoid `any` and `unknown` without explicit narrowing.
        - Unvalidated external input (API responses, form data) without Zod or equivalent schema validation.
        - Performance: large imports from barrel files that could cause bundle bloat.
        - Security: hardcoded secrets, unsafe innerHTML, unvalidated redirects.
        - Do NOT comment on code formatting (indentation, spacing, line length).
    - path: 'src/**/*.test.{ts,tsx}'
      instructions: |
        Review for:
        - Test coverage of happy path and at least one error path per public function.
        - Mocking strategy: prefer msw over manual fetch mocks.
        - Avoid testing implementation details; test observable behavior.
        - Do NOT comment on formatting.
chat:
  auto_reply: true
```

### § Fallback — Claude Code Review Action

```yaml
name: Claude Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Claude Code Review
        uses: anthropics/claude-code-action@beta
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          direct_prompt: |
            Review this PR for:
            - FSD boundary violations
            - TypeScript type safety issues
            - Missing 'use client' directives
            - Security issues (hardcoded secrets, unsafe innerHTML)
            Do NOT comment on formatting.
```
