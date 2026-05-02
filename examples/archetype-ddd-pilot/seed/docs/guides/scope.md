# archetype-ddd-pilot Scope

본 archetype은 TypeScript **frontend** 학습용. UI 페이지 + 사용자 행동 (`features/`) + 클라이언트 도메인 (`entities/`) + 외부 인터페이스 호출 (`api/`)이 전부.

## Frontend-only LOCK 사유

- Mind Signal / CheckMate frontend production pattern 정합
- Codex CI-1 ~ CI-5 자동 해소 (frontend FSD ↔ backend DDD 충돌)
- FSD `api = HTTP` 의미 일관

backend는 typescript-template backend archetype S4 deferred (별도 phase).

## Single-aggregate pilot (Order/OrderItem)

DISCUSS Q14 LOCK. Order 하나로 11가지 학습 가치 다룸.

## 11 학습 가치 vs 7 핵심 + 4 부수 (CRITIQUE Reviewer 2 흡수)

| # | 학습 가치 | 분류 |
|---|---|---|
| 1 | Aggregate invariant | **핵심** |
| 2 | Status transition | **핵심** |
| 3 | Value Object (Money, OrderStatus) | **핵심** |
| 4 | Static factory + private constructor | **핵심** |
| 5 | RSC/CSC boundary | **핵심** |
| 6 | zod schema validation | **핵심** |
| 7 | Classicist test (no-mocking domain) | **핵심** |
| 8 | Domain Event type | 부수 |
| 9 | Repository (HTTP fetch wrapper) | 부수 |
| 10 | Use case (mutation hook) | 부수 |
| 11 | msw + RTL feature test | 부수 |

**핵심 7**: DDD aggregate / boundary / 검증 패턴 — DDD/TDD pilot의 메시지 코어.
**부수 4**: 부가 학습 — 핵심 이해 후 자연스럽게 흡수되는 영역.

학습 진입 시 핵심 7부터 학습 권장, 부수 4는 핵심 7 안정화 이후. 11 가치는 redundant 아님 (각각 별개 학습 outcome) but 시간 효율적 학습 sequence는 7→4.

## T3 Stack 2026 evolution 정합 (P6 박제 — plan-review-deep --with-codex Round 1 검증)

본 archetype의 stack 결정 vs [T3 Stack 2026 evolution report](https://www.webdev.today/web-development/t3-stack-relevant-2026-engineering-report) 추세:

| 추세 | archetype 입장 | 박제 |
|---|---|---|
| Drizzle ORM 채택 우세 | frontend-only LOCK으로 ORM 채택 무관 | backend (S4 phase) 재평가 trigger — 본 phase scope 외 |
| Hono 추세 (Next.js API routes 대체) | frontend archetype 범위 외 | "범위 외" 명시 |
| Server Actions 2026 핵심 primitive | DISCUSS Q11 native form + zod LOCK + Mind Signal `use server` 0건 정합 | **의도적 비채택 — 학습 메시지 집중**. 실전 확장 시 Server Actions 도입 가능 |
| TanStack Query 복잡 클라이언트 데이터 | DISCUSS Q10 Context+native hooks LOCK + Mind Signal "TanStack Query 설치되어도 unused/limited" 정합 | **학습 목표 우선 선택** (라이브러리 magic이 학습 분산 회피). 실전 확장 시 TanStack Query / tRPC / Server Actions / Hono 도입 가능 |

archetype은 **"production-realistic learning track"** — 2026 추세를 무시하지 않되, 학습 메시지 집중을 위해 의도적으로 단순화한 stack 선택. 학습자는 본 archetype 안정화 후 위 추세 도입을 자연스럽게 학습할 수 있음.

## 다중 aggregate / Saga 등 deferred

본 phase scope 외:
- 다중 aggregate / cross-aggregate consistency
- Saga 패턴
- domain event subscriber / message bus / outbox
- E2E demo (Playwright spec, Vercel preview URL)
- backend archetype (S4 deferred)
- `docs/patterns/ddd-tdd-cross-stack.md` (부모 Q6=A, python phase 종료 후)
- `Guide/DDD-TDD-Application-Rubric.md` (부모 Q8=A, frontend 항목 본 phase 종료 후 v0.1)

## 14a Revision trigger 2026-11-01 inheritance

parent ADR-004 "0-external-usage phase":
- 외부 LLM agent fork/clone OR human adoption signal **1건 이상** → 🟢 PROCEED, ADR-005 stays
- 신호 0건 + cookiecutter equivalence demonstrated → 🔴 KILL (parent 운명 공동체)
- 신호 0건 + cookiecutter equivalence NOT demonstrated → 🟡 hold for next gate
