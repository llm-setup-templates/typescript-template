#!/usr/bin/env bash
# T10 Static Verification Script for typescript-template
# Run from: Team-project/llm-setup-prompts/typescript-template/
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

check() {
  local id="$1"
  local desc="$2"
  local result="$3"
  local expected="$4"

  if [ "$result" = "$expected" ]; then
    echo "PASS [$id] $desc (got: $result)"
    PASS=$((PASS + 1))
  else
    echo "FAIL [$id] $desc (expected: $expected, got: $result)"
    FAIL=$((FAIL + 1))
  fi
}

check_gte() {
  local id="$1"
  local desc="$2"
  local result="$3"
  local min="$4"

  if [ "$result" -ge "$min" ]; then
    echo "PASS [$id] $desc (got: $result >= $min)"
    PASS=$((PASS + 1))
  else
    echo "FAIL [$id] $desc (expected >= $min, got: $result)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== V1: SETUP.md 잔여 플레이스홀더 (PROJECT_NAME 제외) ==="
V1_COUNT=$(grep -oE '\{\{[A-Z_]+\}\}' "$ROOT/SETUP.md" | grep -v 'PROJECT_NAME' | wc -l | tr -d ' ')
check "V1" "SETUP.md residual placeholders (excl PROJECT_NAME)" "$V1_COUNT" "0"

echo ""
echo "=== V2: SETUP.md 섹션 헤딩 수 ==="
V2_COUNT=$(grep -cE '^## [0-9]' "$ROOT/SETUP.md" || true)
check_gte "V2" "SETUP.md section headings (## N.)" "$V2_COUNT" "13"

echo ""
echo "=== V3: examples/ 파일/디렉토리 수 ==="
V3_COUNT=$(ls -A "$ROOT/examples/" | wc -l | tr -d ' ')
check_gte "V3" "examples/ entries (files + dirs)" "$V3_COUNT" "14"

echo ""
echo "=== V4: Git Safety Gate bash 문법 ==="
GATE_BLOCK=$(sed -n '/# Gate 1/,/# Gate 3/p' "$ROOT/SETUP.md" | grep -v '^\`\`\`')
if bash -n <(echo "$GATE_BLOCK") 2>&1; then
  echo "PASS [V4] Git Safety Gate bash syntax"
  PASS=$((PASS + 1))
else
  echo "FAIL [V4] Git Safety Gate bash syntax error"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== V5: verify 명령 일관성 ==="
V5_VL=$(grep -c "npm run verify" "$ROOT/.claude/rules/verification-loop.md" || echo "0")
V5_SETUP=$(grep -c "npm run verify" "$ROOT/SETUP.md" || echo "0")
V5_CLAUDE=$(grep -c "npm run verify" "$ROOT/CLAUDE.md" || echo "0")
check_gte "V5a" "npm run verify in verification-loop.md" "$V5_VL" "1"
check_gte "V5b" "npm run verify in SETUP.md" "$V5_SETUP" "1"
check_gte "V5c" "npm run verify in CLAUDE.md" "$V5_CLAUDE" "1"

echo ""
echo "=== V6: code-style.md OVERRIDE 플레이스홀더 ==="
V6_COUNT=$(grep -oE '\{\{OVERRIDE_[A-Z_]+\}\}' "$ROOT/.claude/rules/code-style.md" | wc -l | tr -d ' ')
check "V6" "code-style.md OVERRIDE placeholders" "$V6_COUNT" "0"

echo ""
echo "=== V7: architecture.md FSD 5계층 + no-public-api-sidestep ==="
V7_FSD=$(grep -c "shared\|entities\|features\|widgets" "$ROOT/.claude/rules/architecture.md" || echo "0")
V7_NPS=$(grep -c "no-public-api-sidestep" "$ROOT/.claude/rules/architecture.md" || echo "0")
check_gte "V7a" "FSD layers mentioned in architecture.md" "$V7_FSD" "1"
check_gte "V7b" "no-public-api-sidestep in architecture.md" "$V7_NPS" "1"

echo ""
echo "=== V8: Node 버전 일관성 (ci.yml) ==="
V8_RESULT=$(grep "node-version" "$ROOT/examples/ci.yml" || echo "MISSING")
if echo "$V8_RESULT" | grep -q "node-version"; then
  echo "PASS [V8] Node version reference in ci.yml: $V8_RESULT"
  PASS=$((PASS + 1))
else
  echo "FAIL [V8] Node version reference missing in ci.yml"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== V9: examples/ci.yml regression guards ==="
# Regression checks: these exact tokens must NOT appear again — each
# one is a bug PR #6 fixed.
check_absent() {
  local id="$1"
  local desc="$2"
  local file="$3"
  local pattern="$4"
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "FAIL [$id] $desc — forbidden pattern found in $file: $pattern"
    FAIL=$((FAIL + 1))
  else
    echo "PASS [$id] $desc (forbidden pattern absent)"
    PASS=$((PASS + 1))
  fi
}
check_absent "V9a" "ci.yml uses commitlint.config.mjs (not .js)" \
  "$ROOT/examples/ci.yml" "commitlint\.config\.js[^m]"
check_absent "V9b" "jest.config.ts uses testMatch (not testPathPattern)" \
  "$ROOT/examples/jest.config.ts" "testPathPattern"
check_absent "V9c" "husky/pre-commit has no legacy husky.sh sourcing" \
  "$ROOT/examples/husky/pre-commit" "husky\.sh"
check_absent "V9d" "husky/commit-msg has no legacy husky.sh sourcing" \
  "$ROOT/examples/husky/commit-msg" "husky\.sh"
check_absent "V9e" "package.scripts.json does not use deprecated next lint" \
  "$ROOT/examples/package.scripts.json" '"next lint"'

echo ""
echo "=== V10: depcruise wired across Phase 2/3/4/CI ==="
V10_P2=$(grep -c "dependency-cruiser" "$ROOT/SETUP.md" || echo "0")
V10_SCRIPT=$(grep -c '"depcruise"' "$ROOT/SETUP.md" || echo "0")
V10_EXAMPLES=$(grep -c '"depcruise"' "$ROOT/examples/package.scripts.json" || echo "0")
check_gte "V10a" "dependency-cruiser mentioned in SETUP.md" "$V10_P2" "3"
check_gte "V10b" "depcruise script defined in SETUP.md (Phase 4 + Appendix)" "$V10_SCRIPT" "2"
check_gte "V10c" "depcruise script present in examples/package.scripts.json" "$V10_EXAMPLES" "1"

echo ""
echo "=== V11: Phase 5.5 Core files present ==="
for f in \
  .github/ISSUE_TEMPLATE/feature.yml \
  .github/ISSUE_TEMPLATE/bug.yml \
  .github/ISSUE_TEMPLATE/adr.yml \
  .github/ISSUE_TEMPLATE/config.yml \
  .github/PULL_REQUEST_TEMPLATE.md \
  .github/CODEOWNERS \
  docs/README.md \
  docs/requirements/RTM.md \
  docs/requirements/_FR-template.md \
  docs/architecture/overview.md \
  docs/architecture/decisions/README.md \
  docs/architecture/decisions/_ADR-template.md \
  docs/architecture/decisions/_RFC-template.md \
  .claude/rules/documentation.md; do
  if [ -f "$ROOT/$f" ]; then
    echo "PASS [V11] $f"
    PASS=$((PASS + 1))
  else
    echo "FAIL [V11] $f missing"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== V12: ADR template encodes 5-state lifecycle ==="
V12_STATES=0
for state in Proposed Accepted Rejected Deprecated Superseded; do
  if grep -q "$state" "$ROOT/docs/architecture/decisions/README.md"; then
    V12_STATES=$((V12_STATES + 1))
  fi
done
check "V12" "ADR lifecycle states (Proposed/Accepted/Rejected/Deprecated/Superseded)" "$V12_STATES" "5"

echo ""
echo "=== V13: PR template has required discipline sections ==="
V13_REFS=0
for pattern in "FR:" "ADR:" "RTM discipline" "Balancing Rule"; do
  if grep -q "$pattern" "$ROOT/.github/PULL_REQUEST_TEMPLATE.md"; then
    V13_REFS=$((V13_REFS + 1))
  fi
done
check "V13" "PR template references (FR / ADR / RTM / Balancing)" "$V13_REFS" "4"

echo ""
echo "=== V14: Reports opt-in module (present or absent consistently) ==="
if [ -d "$ROOT/docs/reports" ]; then
  V14_FILES=0
  for f in README.md _spike-test-template.md _benchmark-template.md _api-analysis-template.md _paar-template.md; do
    if [ -f "$ROOT/docs/reports/$f" ]; then
      V14_FILES=$((V14_FILES + 1))
    fi
  done
  check "V14" "Reports module completeness (all 5 files present)" "$V14_FILES" "5"
else
  echo "SKIP [V14] Reports module not installed"
fi

echo ""
echo "=== V15: Briefings opt-in module consistency ==="
if [ -d "$ROOT/docs/briefings" ]; then
  V15_FILES=0
  for f in README.md _template/CLAUDE.md _template/README.md _template/slide-outline.md _template/talking-points.md _template/decisions-checklist.md _template/open-questions.md; do
    if [ -f "$ROOT/docs/briefings/$f" ]; then
      V15_FILES=$((V15_FILES + 1))
    fi
  done
  check "V15" "Briefings module completeness (all 7 files present)" "$V15_FILES" "7"
else
  echo "SKIP [V15] Briefings module not installed"
fi

echo ""
echo "=== V16: Extended opt-in module consistency ==="
V16_PRESENT=0
for f in docs/architecture/containers.md docs/architecture/DFD.md docs/data/dictionary.md; do
  if [ -f "$ROOT/$f" ]; then
    V16_PRESENT=$((V16_PRESENT + 1))
  fi
done
# Extended is all-or-nothing: either 3 files or 0
if [ "$V16_PRESENT" = "3" ]; then
  echo "PASS [V16] Extended module installed (3/3)"
  PASS=$((PASS + 1))
elif [ "$V16_PRESENT" = "0" ]; then
  echo "SKIP [V16] Extended module not installed"
else
  echo "FAIL [V16] Extended module partial: $V16_PRESENT/3 files — must be all or none"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "======================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
