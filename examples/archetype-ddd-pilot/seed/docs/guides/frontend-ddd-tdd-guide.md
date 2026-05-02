# Frontend DDD/TDD Guide

class-based aggregate + RSC/CSC boundary + Classicist test 패턴 가이드.

## 4-step pattern (Form → Domain → Boundary → Optimistic)

1. **Form input shape** — zod safeParse (`PlaceOrderRequestSchema`)
2. **Client domain invariant** — `Order.create()` throws `InvariantViolationError`
3. **External boundary** — `orderApi` POST/PATCH (Axios + interceptor)
4. **Optimistic update + rollback** — Context state mutation + previous-orders restore on fail

## RSC/CSC boundary

- pages: RSC (`await orderApi.getOrders` → DTO props)
- widgets: CSC (`'use client'` + DTO → `Order.fromDto` `useMemo`)
- features: CSC (form/button + hooks)
- entities/model: pure (no React)
- entities/api: pure (Axios + `React.cache`)

## DTO ↔ class boundary 시연 위치

archetype은 boundary 시연을 **2 widget만** (`OrderListWidget`, `OrderDetailWidget`).
`useMemo(() => orderDtos.map(Order.fromDto), [orderDtos])` 패턴.
features `use-*.hook.ts`는 Context의 `Order` 인스턴스 직접 사용 (Context 안에서 변환 처리).
학습 burden 분산 회피.

## vs Proxy API trade-off (osedea.com Reactive Rich Domain Models)

class-based aggregate를 React에서 사용할 때 [osedea.com](https://www.osedea.com/insight/reactive-rich-domain-models)이
지적한 호환성 문제: React Reconciliation은 shallow comparison으로 prop change를 감지.
class 인스턴스 내부 값이 변해도 reference가 동일하면 re-render 안 됨.

| Approach | 장점 | 단점 | 본 archetype 채택 여부 |
|---|---|---|---|
| **Proxy API + BaseModel + useModelUpdate hook** (osedea.com) | reactive 자동 동기화 | Proxy API 학습 burden + magic | ❌ 미채택 (학습 메시지 분산) |
| **DTO ↔ class boundary + Order.fromDto pattern** (본 archetype) | 단순성 + RSC/CSC boundary 명시 + Reconciliation 친화 (`fromDto`가 새 reference 생성) | optimistic update 시 새 인스턴스 생성 boilerplate | ✅ 채택 |

archetype의 `fromDto` pattern은 valid alternative. Proxy API는 reactive 우위, `fromDto`는 단순성 우위.

## dep-cruiser FE-DDD 7 rule

5 enforceable error rules (`.dependency-cruiser.cjs`) + 2 convention-only:
- 3 FSD: `no-db-in-entities` / `no-db-in-features` / `no-cross-feature-import`
- 2 FE-DDD enforceable: `R-FE-3-no-api-dep-in-domain` / `R-FE-4-no-upward-from-domain`
- 2 FE-DDD convention: R-FE-1 client domain class location / R-FE-2 event type location (code review + guide.md 박제로 enforce)

## Domain Event type-only convention

archetype은 type-only event export (TS-Q17 A3 LOCK). `pullDomainEvents()` 미보유.
Spring `AbstractAggregateRoot.registerEvent()` 등가물은 본 archetype scope 외 — subscriber/analytics adapter/message bus/outbox 중 하나라도 도입될 때 추가 가능.

## Classicist test (no-mocking domain)

- domain layer = 직접 인스턴스화 + 상태 기반 단언 (no mocking)
- feature layer = msw boundary mock + 실제 hook 실행 — **`onUnhandledRequest: 'error'` 정책 (CX2-10)**: 핸들러 없는 요청은 즉시 FAIL. 신규 테스트 작성 시 `__tests__/_msw/handlers.ts` 핸들러 추가가 우선. 'warn'/'bypass'는 silent integration drift 누적 위험으로 미채택.
- widget layer = RTL + browser-mode (Playwright Chromium) — **파일 단위 격리 (CX2-9)**: Vitest browser-playwright는 동일 파일의 모든 테스트를 단일 page에서 실행. 파일 내 `beforeEach`로 localStorage/cookies/Context state 초기화 필수. 누수 위험 시 test file 분리.

## RSC / CSC boundary import 규칙 (R2-08/CX2-8)

`shared/state/order-context.client.ts`는 `'use client'` 모듈 — RSC에서 **값 import** 시 그 파일과 transitive import 전부가 client bundle로 편입됨 (Next.js App Router boundary semantics).

| 위치 | 허용 import |
|---|---|
| RSC (`app/page.tsx`, `app/orders/page.tsx` 등) | `import type { OrderContextValue } from '@/shared/state/order-context.contract'` (type only) |
| CSC (`app/providers/order.context.tsx`, `features/*`, `widgets/*`) | `import { OrderContext, useOrder } from '@/shared/state/order-context.client'` (값 import 가능) |

위반 예: RSC가 `import { useOrder } from '@/shared/state/order-context.client'` — 컴파일은 되지만 RSC가 client bundle로 끌려가서 SSR streaming 손실.

## Tailwind v4 + tailwind-merge note

`tailwind-merge ^3.0.0` v4 호환. 커스텀 theme token 추가 시 namespace 충돌 주의 — config 확장 필요.
