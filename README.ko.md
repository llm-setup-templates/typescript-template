# TypeScript / Next.js 템플릿 — LLM 에이전트 전용 스캐폴딩

[English README](./README.md)

> Next.js 15 (App Router) + Feature-Sliced Design을 조합한 독단적(opinionated) 템플릿.
> Claude Code / Cursor 같은 LLM 코딩 에이전트가 빈 디렉토리에서 GitHub Actions CI green까지
> **중간 인간 개입 없이** 자동 세팅하도록 설계됐습니다.

**실증 검증 완료**: SETUP.md 하나로 Claude Code → CI green 9분 달성
([증거 실행 로그](https://github.com/KWONSEOK02/llm-setup-e2e17-typescript/actions/runs/24565977208))

---

## 이 템플릿이 존재하는 이유

JS/TS 프로젝트 세팅은 선택지 홍수입니다: App Router vs Pages Router, strict tsconfig 여부, ESLint flat config vs 레거시 포맷, 포매터, 테스트 러너, 아키텍처 컨벤션…

이 템플릿은 **계층별로 하나의 방어 가능한 답**을 미리 선택하고, LLM 에이전트가 위에서 아래로 그대로 실행하는 SETUP.md를 제공합니다.

**고정된 선택과 근거**:

| 계층 | 선택 | 이유 (기각된 대안) |
|---|---|---|
| 프레임워크 | Next.js 15 App Router | Pages Router는 레거시 경로; App Router + Server Components가 현재 표준 |
| 아키텍처 | Feature-Sliced Design (5계층) | Clean Architecture는 SPA에 너무 추상적; Atomic Design은 UI와 상태를 혼용 |
| TypeScript | strict 모드 + `@/*` alias | loose 모드는 실제 버그를 숨김; 상대 경로 임포트는 리팩토링 시 부서짐 |
| 포매터 | Prettier (모든 공백 소유) | "어떤 ESLint 규칙이 포맷을?" 논쟁 종식 |
| 린터 | ESLint 9 flat config + `eslint-plugin-fsd-lint` | 레거시 `.eslintrc.*`는 deprecated; fsd-lint가 계층 경계를 자동 강제 |
| 경계 검사 | Dependency Cruiser | "feature가 Prisma를 임포트 금지" 같은 규칙은 ESLint만으로 표현 불가 |
| 테스트 | Jest 29 + ts-jest + jsdom | Vitest는 별도 ref variant 존재; 더 넓은 생태계를 위해 Jest 선택 |
| Git 훅 | Husky 9 (pre-commit + commit-msg) | push 전에 포맷/커밋 메시지 문제 차단 |

---

## 누가 써야 하는가

**페르소나 1 — Next.js 웹 앱을 만드는 개인/소규모 팀**
- 해결: "tsconfig 플래그는? ESLint 규칙은? 폴더 구조는?"
- 해결 안 함: 디자인 결정 (Tailwind vs CSS-in-JS, 어떤 상태 라이브러리 등)

**페르소나 2 — LLM 보조 개발 (Claude Code, Cursor)**
- 해결: SETUP.md는 fail-fast, Husky는 나쁜 커밋 차단, Dependency Cruiser는 계층 위반 차단 — 에이전트가 수정할 구체적인 오류를 얻음
- 해결 안 함: 비즈니스 도메인 결정; 이 템플릿은 구조를 스캐폴딩하지 제품을 만들지 않음

**페르소나 3 — FSD를 처음 도입하는 팀**
- 해결: 디렉토리 구조 + barrel 파일 + eslint-plugin-fsd-lint 규칙이 사전 설정됨
- 해결 안 함: 기존 코드의 FSD 마이그레이션 — 그린필드 전용

**페르소나 4 — 재현 가능한 React/Next.js 수업 환경이 필요한 강사**
- 해결: 모든 학생이 동일한 스택; CI가 채점 시 실수를 잡아줌
- 해결 안 함: 커리큘럼

---

## 누가 쓰면 안 되는가

- Pages Router를 원하는 경우 → fork 후 Phase 1 스캐폴딩 재작성
- FSD를 원하지 않는 경우 → fork 후 `.claude/rules/architecture.md` 삭제, fsd-lint 플러그인 제거
- SSG 위주 정적 사이트가 필요한 경우 → Astro 또는 11ty가 더 적합
- TypeScript를 사용하지 않는 경우 → 이 템플릿은 TS 전용

---

## 빠른 적합성 체크

클론 전 세 가지 모두 답하세요:

1. **그린필드 Next.js 15 App Router 프로젝트인가?** 아니라면 — 이 템플릿은 새 프로젝트 스캐폴딩 전용; 기존 코드베이스 마이그레이션은 수동 적용이 필요합니다.
2. **FSD를 모른다면 배울 의향이 있는가?** (계층 / barrel / 임포트 방향 — 약 하루 학습 분량) 아니라면 — 비-FSD 템플릿을 선택하세요.
3. **처음부터 strict tsconfig + ESLint 9 flat config + Husky를 쓸 의향이 있는가?** 아니라면 — 더 가벼운 스타터를 사용하세요.

세 가지 모두 예 → `SETUP.md`로 진행하세요.

---

## FSD 빠른 안내 — 처음 접하는 경우

FSD(Feature-Sliced Design)는 `src/`를 5개 계층으로 구성하며, 단방향 의존성 방향을 강제합니다:

```
src/
├── shared/      — 원자 단위 기본 요소 (UI 키트, 유틸, 타입) — 다른 것을 임포트하지 않음
├── entities/    — 비즈니스 객체 (User, Product) — shared만 임포트
├── features/    — 사용자 기능 (인증, 결제) — shared + entities 임포트
├── widgets/     — 복합 UI 블록 — shared + entities + features 임포트
└── app/         — Next.js App Router 루트 — 모든 계층 임포트 가능
```

`eslint-plugin-fsd-lint`가 자동으로 강제하는 규칙:

- 상위 계층이 하위 계층을 임포트: 허용 (`features/`는 `entities/`를 쓸 수 있음)
- 하위 계층이 상위 계층을 임포트: **차단** (`entities/`는 `features/`를 쓸 수 없음)
- 같은 계층 내 다른 슬라이스 임포트: 슬라이스의 공개 `index.ts` barrel을 통해서만 허용
- barrel을 우회하는 직접 깊은 임포트: **차단** (`no-public-api-sidestep`)

처음에는 모든 것을 `shared/`에 넣고, 명확한 이유가 생겼을 때 분리하세요.
명확한 비즈니스 객체가 생기면 `entities/`로, 사용자 가시적 액션이 생기면 `features/`로 승격시킵니다.
계층 분리를 너무 일찍 과설계하는 것이 가장 흔한 실수입니다.

---

## 검증 루프 (6단계)

모든 코드 변경은 작업 완료 선언 전에 이 단계를 순서대로 통과해야 합니다:

```bash
npm run format:check   # Prettier
npm run typecheck      # tsc --noEmit
npm run depcruise      # Dependency Cruiser (인프라 격리 + 크로스-feature)
npm run lint           # ESLint 9
npm run test           # Jest 29
npm run build          # next build
```

또는 한 번에: `npm run verify`

이 루프는 CI 워크플로우와 정확히 일치합니다 — 설계상 괴리 없음.

---

## 포함된 내용

- 셋업 흐름: [SETUP.md](./SETUP.md) — 14개 섹션, Phase 0 → Phase 8
- AI 에이전트 규칙: [CLAUDE.md](./CLAUDE.md)
- 아키텍처 (FSD 심화): [.claude/rules/architecture.md](./.claude/rules/architecture.md)
- 검증 루프: [.claude/rules/verification-loop.md](./.claude/rules/verification-loop.md)
- 테스트 수정: [.claude/rules/test-modification.md](./.claude/rules/test-modification.md)
- Git 워크플로우: [.claude/rules/git-workflow.md](./.claude/rules/git-workflow.md)

---

## 관련 템플릿

- [python-template](https://github.com/llm-setup-templates/python-template) — Python 3.13 + 3개 아키타입 (script / web / library)
- [spring-template](https://github.com/llm-setup-templates/spring-template) — Spring Boot 3 + 계층형 아키텍처

---

## 라이선스

MIT
