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
echo "20" > .nvmrc
gh repo create {{PROJECT_NAME}} --private --source=. --remote=origin
```

**Order note**: `.nvmrc` MUST be created after `cd {{PROJECT_NAME}}` AND after `git init`
to ensure the file is placed in the project root.

## 4. Phase 1 — Scaffolding

```bash
npx create-next-app@latest . --ts --app --tailwind --eslint=false \
  --src-dir --import-alias "@/*"
```

> `--src-dir` creates a `src/` directory. FSD layers live under `src/`.
> `--eslint=false` skips Next.js default ESLint config — we install ESLint 9 flat config manually in Phase 3.

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
  lint-staged

npx husky init
```

## 6. Phase 3 — Config Files

Write the following config files (exact content in Appendix § Config Reference):

- `.prettierrc` — Prettier formatting options
- `.prettierignore` — files Prettier should skip
- `eslint.config.mjs` — ESLint 9 flat config with FSD boundary rules
- `jest.config.ts` — Jest 29 + ts-jest config (`setupFilesAfterEnv`)
- `commitlint.config.js` — Conventional Commits enforcement
- `.lintstagedrc.json` — lint-staged per-extension commands
- `.husky/pre-commit` — runs `npx lint-staged`
- `.husky/commit-msg` — runs `npx --no -- commitlint --edit "$1"`
- `.gitattributes` — enforces LF line endings
- `.gitignore` — standard Next.js ignores
- `tsconfig.json` — merge `tsconfig.strict-additions.json` options into `compilerOptions`

Merge `examples/tsconfig.strict-additions.json` into your project's `tsconfig.json`:
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
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "verify": "npm run format:check && npm run typecheck && npm run lint && npm run test && npm run build",
    "prepare": "husky"
  }
}
```

## 8. Phase 5 — CI Workflow

Write `.github/workflows/ci.yml` (exact content in Appendix § CI Reference).

## 9. Phase 6 — CodeRabbit Setup

1. Write `.coderabbit.yaml` (exact content in Appendix § CodeRabbit Reference).
2. Install CodeRabbit GitHub App: https://github.com/apps/coderabbitai
3. If CodeRabbit trial is unavailable, fall back to the Claude Code Review
   Action (Appendix § Fallback).

## 10. Phase 7 — Local Verify (fail-fast)

```bash
npm run verify
```

All checks must pass before Phase 8.

## 11. Phase 8 — First Push + CI Green

### 11.1 Git Safety Gate (MANDATORY — run before push)

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

### 11.2 Push + watch CI

```bash
git push -u origin $(git rev-parse --abbrev-ref HEAD)
gh run watch
```

### 11.3 Success Declaration

Only after `gh run watch` reports all jobs green, you may report the task
as complete to the human.

## 12. Troubleshooting

| 문제 | 원인 | 해결 |
|------|------|------|
| `jest.config.ts` 파싱 실패 (`ts-node` 관련 에러) | `ts-node`가 devDependencies에 없음 | `npm i -D ts-node` 후 재실행 |
| Jest ESM/CJS 충돌 (`SyntaxError: Cannot use import statement`) | Next.js 15 ESM 모듈을 Jest CJS로 변환 실패 | `jest.config.ts`에 `transform` 설정 추가: `extensionsToTreatAsEsm: ['.ts', '.tsx']` + `ts-jest` ESM preset |
| Windows CRLF 이슈 (CI에서 Prettier 실패) | Windows에서 CRLF로 저장된 파일 | `.gitattributes`에 `* text=auto eol=lf` 적용 후 `git add --renormalize .` |
| CI build 실패 (환경변수 미설정) | `NEXT_PUBLIC_*` 환경변수가 CI에 없음 | `ci.yml`의 `env:` 블록에 dummy 값 또는 GitHub Secrets로 주입 |
| `eslint-plugin-fsd-lint` flat config 미지원 | 플러그인이 legacy config만 지원 | `@eslint/eslintrc`의 `FlatCompat.plugins()` wrapper 사용 (`examples/eslint.config.mjs` 참조) |

## 13. Essential Checklist

- [ ] `gh auth status` passed
- [ ] Node.js version verified (≥ 20)
- [ ] Scaffolding command ran in an empty or newly-created directory
- [ ] All config files written
- [ ] `npm run verify` passes locally
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
```

#### `eslint.config.mjs`
```js
import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

/** @type {import('eslint').Linter.Config[]} */
const eslintConfig = [
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  ...compat.plugins('fsd-lint'),
  {
    rules: {
      'fsd-lint/forbidden-imports': 'error',
      'fsd-lint/no-relative-imports': 'error',
      'fsd-lint/no-public-api-sidestep': 'error',
    },
  },
  {
    rules: {
      'import/prefer-default-export': 'off',
    },
  },
];

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
  testPathPattern: ['<rootDir>/src/**/*.test.{ts,tsx}'],
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
};

export default config;
```

**Important**: The Jest config key is `setupFilesAfterEnv` (NOT `setupFilesAfterFramework`).

#### `commitlint.config.js`
```js
/** @type {import('@commitlint/types').UserConfig} */
module.exports = {
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

#### `.lintstagedrc.json`
```json
{
  "*.{ts,tsx,js,jsx,mjs,cjs}": ["prettier --write", "eslint --fix"],
  "*.{json,md,yaml,yml,css}": ["prettier --write"]
}
```

#### `.husky/pre-commit`
```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
```

#### `.husky/commit-msg`
```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

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
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "verify": "npm run format:check && npm run typecheck && npm run lint && npm run test && npm run build",
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
          configFile: commitlint.config.js

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
