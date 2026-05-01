---
status: Accepted
date: 2026-05-02
deciders: gs07103
related-adrs:
  - ADR-002-clone-script-scaffolding (parent)
  - ADR-004-template-governance-rationale (governance)
---

# ADR-005: archetype-ddd-pilot — Frontend DDD/TDD Pilot Archetype 분기 사유

## Context

ADR-002 §"single archetype" 결정 (`next` only, `node-cli` / `library` reserved)을 재해석. "single **production starter** archetype"으로 좁히고, **별도 학습 archetype** `ddd-pilot`을 추가한다.

부모 Phase E (3-template DDD/TDD stack) Q1-Q12 LOCK + 본 Phase E typescript-ddd 20 LOCK 결정이 archetype-ddd-pilot의 모든 세부 결정을 가이드한다. 사용자 철학 LOCK:

1. **학습 가치 우선** — pilot archetype은 DDD/TDD 핵심 학습 메시지에 집중. 라이브러리 magic이 학습을 분산시키면 reject.
2. **production-local custom 미채택** — Mind Signal 등 production-local pattern (예: 번호 prefix `07-shared`)은 채택 X. wider community standard (예: dot-role suffix `.component.tsx`)는 채택 OK.
3. **단순성** — 학습용 archetype scope 명확히. 의존성 최소, over-engineering 회피.
4. **Mind Signal 정합 (조건부)** — production realism이 학습 가치와 정합할 때 채택 (예: Axios + JWT interceptor). 정합 X일 때 분기 (예: 거의-모두-CSC vs minimal B RSC/CSC 경계).
5. **archetype-next ↔ archetype-ddd-pilot 분기 정당화** — 본 ADR + RATIONALE.md에 분기 사유 명시 의무.

## Decision

- **archetype-next**: minimal Next.js baseline (create-next-app default + jest + native fetch + Tailwind 단독 — production 시작점)
- **archetype-ddd-pilot**: production-realistic learning track (Vitest 4 browser mode + Axios + Tailwind + cn() + dot-role suffix + FSD-DDD hybrid + Order/OrderItem 단일 aggregate)

scaffold.sh `--archetype` 옵션 확장: `next` (default) | `ddd-pilot`. 두 archetype 동시 보유는 ADR-002 'single archetype' 결정의 재해석 ('single production starter archetype').

## Why two archetypes (not "next + DDD optional")?

1. **학습 메시지 분리** — production starter는 "minimal", 학습 archetype은 "fully wired DDD/TDD". 동거 시 학습자 혼선.
2. **Mind Signal 실측 정합** — dot-role suffix / Axios / Vitest는 Mind Signal frontend production pattern. 그러나 production-local convention (번호 prefix)은 미채택.
3. **lapidix/nextjs-fsd-ddd-example 직접 경쟁 차별화** — 4 unique 가치축:
   - **LLM agent template intent** — CLAUDE.md/AGENTS.md companion + scaffold.sh 8-stage + V_drift CI guard
   - **Spring E0 학습 매핑** — jMolecules + Spring Modulith ↔ dep-cruiser FE-DDD 4 rule (R-FE-1~R-FE-4)
   - **dep-cruiser FE-DDD 7 rule** — FSD 3 + frontend-DDD 4 (5 enforceable + 2 convention-only)
   - **Phase E 3-template stack companion** — Spring done → typescript → python 학습 sequence

## Consequences

- scaffold.sh `--archetype` 옵션 확장 (`next` | `ddd-pilot`)
- examples/archetype-next/seed/ + examples/archetype-ddd-pilot/seed/ 양립
- VERSION.md / SEED-LAST-UPDATED.txt 각 archetype별 보유
- examples/ci.archetype-next.yml + examples/ci.archetype-ddd-pilot.yml 분리 (Playwright install step ddd-pilot 전용)
- validate.sh `check_seed_completeness` 함수화 + V21 (next) / V21-bis (ddd-pilot) 두 번 호출
- validate.sh V8/V9 path 갱신 + V8-bis/V9f 신설 (ddd-pilot 전용)
- test/scaffold-e2e.sh Cell 7 추가 + scaffold-e2e.yml matrix [1..7] + paths archetype-ddd-pilot 추가

## Revision trigger inheritance (parent ADR-004)

본 archetype-ddd-pilot은 14a Revision trigger 2026-11-01 평가 게이트 inheritance:

| 평가 시점 | 외부 신호 | archetype-ddd-pilot 결정 |
|---|---|---|
| 2026-11-01 | 외부 LLM agent fork/clone OR human adoption signal **1건 이상** | 🟢 PROCEED — ADR-005 stays |
| 2026-11-01 | 신호 0건 + cookiecutter equivalence demonstrated (parent ADR-004) | 🔴 KILL — 14a-bis collapses with 14a parent → archetype-ddd-pilot도 archive |
| 2026-11-01 | 신호 0건 + cookiecutter equivalence NOT demonstrated | 🟡 hold for next gate |

archetype-ddd-pilot 자체 kill condition 없음 (parent 운명 공동체).

## Status (Accepted, 2026-05-02)

Append-only. Supersedes none. Cross-references ADR-002 (single archetype 재해석) + ADR-004 (governance / Revision trigger 상속).

## References

- [lapidix/nextjs-fsd-ddd-example](https://github.com/lapidix/nextjs-fsd-ddd-example) — direct competitor (30 stars, 2025-06 시작)
- [osedea.com Reactive Rich Domain Models](https://www.osedea.com/insight/reactive-rich-domain-models) — class-based domain + React Reconciliation 호환 문제 (vs Proxy API trade-off, frontend-ddd-tdd-guide.md 박제)
- Phase E0 spring-template DDD/TDD pilot DONE (2026-05-01, PR #22 `5f1acf54`) — Spring 학습 매핑 reference
- DISCUSS.md 20 LOCK 결정 (`.plans/E-phase-e-typescript-ddd/DISCUSS.md`)
- CRITIQUE.md 🟡 PROCEED-WITH-CONDITIONS (`.plans/E-phase-e-typescript-ddd/CRITIQUE.md`) — 6 prerequisites
- PLAN.md rev.5 final (`.plans/E-phase-e-typescript-ddd/PLAN.md`)
