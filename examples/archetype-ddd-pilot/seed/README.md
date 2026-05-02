# {{PROJECT_NAME}} (archetype-ddd-pilot scaffolded)

Production-realistic frontend DDD/TDD pilot. Next.js 16 App Router + FSD slices + class-based Order aggregate + dependency-cruiser FE-DDD 7 rule + Vitest browser mode + Axios + Tailwind v4 + cn() utility + dot-role suffix.

## 4 unique 가치축

본 archetype은 [lapidix/nextjs-fsd-ddd-example](https://github.com/lapidix/nextjs-fsd-ddd-example) (이민기, 30 stars) 등 standalone DDD example과 차별:

1. **LLM agent template intent** — CLAUDE.md/AGENTS.md companion + scaffold.sh 8-stage + V_drift CI guard
2. **Spring E0 학습 매핑** — jMolecules + Spring Modulith ↔ dep-cruiser FE-DDD 4 rule (R-FE-1~4) 정합
3. **dep-cruiser FE-DDD 7 rule** — FSD 3 + frontend-DDD 4 (5 enforceable + 2 convention-only)
4. **Phase E 3-template stack companion** — Spring done → typescript (이 archetype) → python 학습 sequence

## vs lapidix/nextjs-fsd-ddd-example

| 영역 | lapidix/nextjs-fsd-ddd-example | archetype-ddd-pilot |
|---|---|---|
| FSD layer | shared / entities / features / widgets / pages / app | shared / entities / features / widgets / app (Next.js App Router) |
| Sample aggregate | User / Post / Comment (3 entities) | Order / OrderItem (single-aggregate pilot, DISCUSS Q14 LOCK) |
| Test runner | Vitest + testing-library (jsdom) | Vitest 4 + browser-mode (Playwright Chromium) + msw |
| 학습 sequence | standalone | Spring E0 → typescript → python (Phase E 3-template stack) |
| Template intent | learning example | LLM agent template (scaffold.sh + V_drift + CLAUDE.md/AGENTS.md companion) |
| Vercel demo | Yes (https://nextjs-fsd-ddd-example.vercel.app/) | None (deferred, scope.md) |
| License | MIT | MIT |

archetype-ddd-pilot은 학습 archetype. 외부 채택은 14a Revision trigger 2026-11-01 평가 게이트 대기 (parent ADR-004 inheritance, ADR-005 박제).

## Quick start

```bash
npm install
npx playwright install --with-deps chromium  # CX2-6: Vitest browser-mode (widget tests) requires Playwright Chromium binary
npm run verify
# format:check → typecheck → depcruise → lint → test → build
npm run dev
```

> **CI 캐싱 권장 (CX2-6)**: GitHub Actions에서 `cache: { key: playwright-${{ hashFiles('package-lock.json') }} }` + env `PLAYWRIGHT_BROWSERS_PATH=$HOME/.cache/ms-playwright` 설정으로 매 run 다운로드 회피. CI yml 예시는 `.github/workflows/ci.yml` 답습 (archetype-next에서 overlay된 ci.yml + Playwright 캐싱 step 포함).

## Architecture

See:
- [docs/guides/scope.md](./docs/guides/scope.md) — frontend-only scope + 11 학습 가치 vs 7 핵심 + 4 부수
- [docs/guides/domain.md](./docs/guides/domain.md) — Order aggregate diagram + status transitions
- [docs/guides/frontend-ddd-tdd-guide.md](./docs/guides/frontend-ddd-tdd-guide.md) — 4-step pattern + RSC/CSC boundary + vs Proxy API trade-off + dep-cruiser FE-DDD rule

## Phase E gate G1-G5

| Gate | 검증 |
|---|---|
| G1 | `bash validate.sh` V_drift 5-keyword + 35 lines + 0 non-ASCII byte-identical |
| G2 | `npm run depcruise` 호출 — ruleset 내 FSD 3 rule subset PASS (CX3-9: 같은 명령으로 G3와 동시 검증, G2는 FSD 부분의 conceptual gate) |
| G3 | `npm run depcruise` 동일 명령 호출 — ruleset 내 5 enforceable rule (FSD 3 + R-FE-3 + R-FE-4) 전체 PASS + R-FE-1 / R-FE-2 convention-only manual code review |
| G4 | `npm run test` Order domain unit test ≥ 4 PASS |
| G5 | V_drift CI guard SHA256 emit (14a-bis canonical inheritance) |
