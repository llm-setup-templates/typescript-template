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
echo "======================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
