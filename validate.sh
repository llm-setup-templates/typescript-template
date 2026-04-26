#!/usr/bin/env bash
# validate.sh -- Tier 1 static verification for typescript-template.
# Run from: typescript-template/ repo root.
#
# Phase 13c additions: V20-V28 (scaffold.sh / archetype-next seed /
# placeholder allowlist / ASCII surface / freshness / next/jest /
# ci.yml parity / Stage B error path).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# ----------------------------------------------------------------
# PLACEHOLDER_ALLOWLIST -- files that intentionally contain {{...}}
# placeholders (filled by scaffold.sh Stage D or kept as authoring markers).
# V22 grep enumerates all matches and asserts every match's file is in this list.
# Add new entries when introducing new placeholders.
# ----------------------------------------------------------------
PLACEHOLDER_ALLOWLIST=(
  "CLAUDE.md"
  "examples/archetype-next/seed/package.json"
  "examples/archetype-next/seed/src/app/layout.tsx"
  "docs/architecture/decisions/_ADR-template.md"
  "docs/architecture/decisions/_RFC-template.md"
  "docs/requirements/_FR-template.md"
  ".plans/PRD.md"
  ".github/PULL_REQUEST_TEMPLATE.md"
)

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

check_absent() {
  local id="$1"
  local desc="$2"
  local file="$3"
  local pattern="$4"
  if [ ! -f "$file" ]; then
    echo "PASS [$id] $desc (file absent: $file)"
    PASS=$((PASS + 1))
    return
  fi
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "FAIL [$id] $desc -- forbidden pattern found in $file: $pattern"
    FAIL=$((FAIL + 1))
  else
    echo "PASS [$id] $desc (forbidden pattern absent)"
    PASS=$((PASS + 1))
  fi
}

echo "=== V1: SETUP.md residual placeholders (excluding documented PROJECT_NAME / PROJECT_ONE_LINER) ==="
# Phase 13c SETUP.md Appendix B documents PROJECT_NAME + PROJECT_ONE_LINER
# placeholders intentionally; both are filled by scaffold.sh Stage D.
V1_COUNT=$(grep -oE '\{\{[A-Z_]+\}\}' "$ROOT/SETUP.md" | grep -vE 'PROJECT_NAME|PROJECT_ONE_LINER' | wc -l | tr -d ' ')
check "V1" "SETUP.md residual placeholders (excl PROJECT_NAME, PROJECT_ONE_LINER)" "$V1_COUNT" "0"

echo ""
echo "=== V2: SETUP.md section headings (## N.) -- Phase 13c threshold ==="
# RC-M4 fix: SETUP.md shrunk to ~200 lines after T8; threshold lowered from 13 to 3.
V2_COUNT=$(grep -cE '^## [0-9]' "$ROOT/SETUP.md" || true)
check_gte "V2" "SETUP.md section headings (## N.)" "$V2_COUNT" "3"

echo ""
echo "=== V3: examples/ entries (recursive count) ==="
# C3-L2 fix: recursive find (was shallow ls -A).
# RC-M4 fix: threshold raised to 18 to account for archetype-next/seed/ 30+ files.
V3_COUNT=$(find "$ROOT/examples/" -type f 2>/dev/null | wc -l | tr -d ' ')
check_gte "V3" "examples/ recursive file count" "$V3_COUNT" "18"

echo ""
echo "=== V4: Git Safety Gate bash syntax (legacy) -- skipped post-Phase 13c ==="
# Pre-13c SETUP.md embedded a Git Safety Gate bash block; Phase 13c SETUP.md
# omits it (clone+scaffold flow). V4 is a no-op until/if reintroduced.
echo "SKIP [V4] Git Safety Gate not present in Phase 13c SETUP.md"

echo ""
echo "=== V5: 'npm run verify' command consistency ==="
V5_VL=$(grep -c "npm run verify" "$ROOT/.claude/rules/verification-loop.md" || echo "0")
V5_SETUP=$(grep -c "npm run verify" "$ROOT/SETUP.md" || echo "0")
V5_CLAUDE=$(grep -c "npm run verify" "$ROOT/CLAUDE.md" || echo "0")
check_gte "V5a" "npm run verify in verification-loop.md" "$V5_VL" "1"
check_gte "V5b" "npm run verify in SETUP.md" "$V5_SETUP" "1"
check_gte "V5c" "npm run verify in CLAUDE.md" "$V5_CLAUDE" "1"

echo ""
echo "=== V6: code-style.md OVERRIDE placeholders ==="
V6_COUNT=$(grep -oE '\{\{OVERRIDE_[A-Z_]+\}\}' "$ROOT/.claude/rules/code-style.md" | wc -l | tr -d ' ')
check "V6" "code-style.md OVERRIDE placeholders" "$V6_COUNT" "0"

echo ""
echo "=== V7: architecture.md FSD 5-layer + no-public-api-sidestep ==="
V7_FSD=$(grep -c "shared\|entities\|features\|widgets" "$ROOT/.claude/rules/architecture.md" || echo "0")
V7_NPS=$(grep -c "no-public-api-sidestep" "$ROOT/.claude/rules/architecture.md" || echo "0")
check_gte "V7a" "FSD layers mentioned in architecture.md" "$V7_FSD" "1"
check_gte "V7b" "no-public-api-sidestep in architecture.md" "$V7_NPS" "1"

echo ""
echo "=== V8: Node version reference (ci.yml) ==="
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
check_absent "V9a" "ci.yml uses commitlint.config.mjs (not .js)" \
  "$ROOT/examples/ci.yml" "commitlint\.config\.js[^m]"
# V9b/V9e: the underlying files (jest.config.ts, package.scripts.json) were
# removed in T7 (LD-08 / LD-03). check_absent is a no-op for missing files,
# which is the desired behavior post-13c.
check_absent "V9b" "jest.config.ts uses testMatch (not testPathPattern) -- file removed in T7" \
  "$ROOT/examples/jest.config.ts" "testPathPattern"
check_absent "V9c" "husky/pre-commit has no legacy husky.sh sourcing" \
  "$ROOT/examples/husky/pre-commit" "husky\.sh"
check_absent "V9d" "husky/commit-msg has no legacy husky.sh sourcing" \
  "$ROOT/examples/husky/commit-msg" "husky\.sh"
check_absent "V9e" "package.scripts.json does not use deprecated next lint -- file removed in T7" \
  "$ROOT/examples/package.scripts.json" '"next lint"'

echo ""
echo "=== V10: depcruise wired across SETUP/seed ==="
V10_P2=$(grep -c "dependency-cruiser\|depcruise" "$ROOT/SETUP.md" 2>/dev/null | head -1)
V10_P2=${V10_P2:-0}
# Phase 13c SETUP.md was rewritten (T8: 980 -> ~200 lines). It references
# depcruise via the verify chain comment but no longer redefines the script
# inline -- seed/package.json is now the authoritative definition source.
# V10b is therefore intentionally relaxed to >= 0 (informational; V10c carries
# the real assertion).
V10_SCRIPT=$(grep -c '"depcruise"' "$ROOT/SETUP.md" 2>/dev/null | head -1)
V10_SCRIPT=${V10_SCRIPT:-0}
# C3-M3 fix: V10c redirected from examples/package.scripts.json (deleted in T7)
# to examples/archetype-next/seed/package.json (authoritative).
V10_EXAMPLES=$(grep -c '"depcruise"' "$ROOT/examples/archetype-next/seed/package.json" 2>/dev/null | head -1)
V10_EXAMPLES=${V10_EXAMPLES:-0}
check_gte "V10a" "dependency-cruiser/depcruise mentioned in SETUP.md" "$V10_P2" "1"
check_gte "V10b" "depcruise script reference present in SETUP.md (relaxed: seed authoritative)" "$V10_SCRIPT" "0"
check_gte "V10c" "depcruise script present in seed/package.json" "$V10_EXAMPLES" "1"

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
echo "=== V14: Reports opt-in module consistency ==="
if [ -d "$ROOT/docs/reports" ]; then
  V14_FILES=0
  for f in README.md _spike-test-template.md _benchmark-template.md _api-analysis-template.md _paar-template.md; do
    if [ -f "$ROOT/docs/reports/$f" ]; then
      V14_FILES=$((V14_FILES + 1))
    fi
  done
  check "V14" "Reports module completeness (5 files)" "$V14_FILES" "5"
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
  check "V15" "Briefings module completeness (7 files)" "$V15_FILES" "7"
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
if [ "$V16_PRESENT" = "3" ]; then
  echo "PASS [V16] Extended module installed (3/3)"
  PASS=$((PASS + 1))
elif [ "$V16_PRESENT" = "0" ]; then
  echo "SKIP [V16] Extended module not installed"
else
  echo "FAIL [V16] Extended module partial: $V16_PRESENT/3 files -- must be all or none"
  FAIL=$((FAIL + 1))
fi

# ================================================================
# Phase 13c additions (V20-V28)
# ================================================================

echo ""
echo "=== V20: scaffold.sh 8-stage labels + Bash guard ==="
# RC-H4 fix: closing quote bug removed; matches both `echo "[Stage X] ..."` and
# stage-header comment lines.
V20_STAGES=$(grep -cE '\[Stage [A-H]\]' "$ROOT/scaffold.sh" || echo "0")
check_gte "V20a" "scaffold.sh contains 8 [Stage A]..[Stage H] markers" "$V20_STAGES" "8"
if grep -q 'BASH_VERSION' "$ROOT/scaffold.sh"; then
  echo "PASS [V20b] scaffold.sh has BASH_VERSION guard"
  PASS=$((PASS + 1))
else
  echo "FAIL [V20b] scaffold.sh missing BASH_VERSION guard"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== V21: examples/archetype-next/seed/ completeness + Tailwind v4 + lockfileVersion + VERSION.md ==="
SEED="$ROOT/examples/archetype-next/seed"
for required in package.json package-lock.json jest.config.mjs postcss.config.mjs; do
  if [ -f "$SEED/$required" ]; then
    echo "PASS [V21] required seed file present: $required"
    PASS=$((PASS + 1))
  else
    echo "FAIL [V21] required seed file missing: $required"
    FAIL=$((FAIL + 1))
  fi
done
# Sibling seed marker files (D-15 + D-16)
for required in examples/archetype-next/VERSION.md examples/archetype-next/SEED-LAST-UPDATED.txt; do
  if [ -f "$ROOT/$required" ]; then
    echo "PASS [V21] required seed marker present: $required"
    PASS=$((PASS + 1))
  else
    echo "FAIL [V21] required seed marker missing: $required"
    FAIL=$((FAIL + 1))
  fi
done
# Tailwind v4 PostCSS shape
if [ -f "$SEED/postcss.config.mjs" ] && grep -q '@tailwindcss/postcss' "$SEED/postcss.config.mjs"; then
  echo "PASS [V21] postcss.config.mjs uses @tailwindcss/postcss"
  PASS=$((PASS + 1))
else
  echo "FAIL [V21] postcss.config.mjs missing @tailwindcss/postcss"
  FAIL=$((FAIL + 1))
fi
GLOBALS="$SEED/src/app/globals.css"
if [ -f "$GLOBALS" ] && grep -q '@import "tailwindcss"' "$GLOBALS"; then
  echo "PASS [V21] src/app/globals.css contains @import \"tailwindcss\""
  PASS=$((PASS + 1))
else
  echo "FAIL [V21] src/app/globals.css missing @import \"tailwindcss\""
  FAIL=$((FAIL + 1))
fi
# lockfileVersion >= 3 (npm 7+ baseline). cd into seed dir so node's require
# resolves the relative path correctly on Windows (absolute paths with
# Windows drive letters and forward slashes confuse Node's CommonJS resolver).
if [ -f "$SEED/package-lock.json" ] && command -v node >/dev/null 2>&1; then
  LOCK_VER=$(cd "$SEED" && node -p "require('./package-lock.json').lockfileVersion" 2>/dev/null || echo "0")
  check_gte "V21" "lockfileVersion >= 3" "$LOCK_VER" "3"
else
  echo "SKIP [V21] lockfileVersion check (node or package-lock.json missing)"
fi
# D-25: VERSION.md `Next.js` row count == 1 (deterministic awk parse)
if [ -f "$ROOT/examples/archetype-next/VERSION.md" ]; then
  NEXT_ROWS=$(grep -c '^| Next\.js' "$ROOT/examples/archetype-next/VERSION.md" || echo "0")
  check "V21" "VERSION.md 'Next.js' row count == 1 (D-25)" "$NEXT_ROWS" "1"
fi

echo ""
echo "=== V22: PLACEHOLDER_ALLOWLIST consistency ==="
# D-23 grammar: \{\{[A-Z_]+\}\} (uppercase + underscore only)
V22_LEAK=0
while IFS= read -r match; do
  [ -z "$match" ] && continue
  file=$(echo "$match" | cut -d: -f1)
  rel="${file#$ROOT/}"
  allowed=0
  for entry in "${PLACEHOLDER_ALLOWLIST[@]}"; do
    if [ "$rel" = "$entry" ]; then
      allowed=1
      break
    fi
  done
  if [ "$allowed" -eq 0 ]; then
    echo "FAIL [V22] placeholder leak in $rel: $match"
    V22_LEAK=$((V22_LEAK + 1))
  fi
done < <(grep -rnE '\{\{[A-Z_]+\}\}' \
  "$ROOT/examples/" "$ROOT/.github/" "$ROOT/docs/" "$ROOT/.claude/" \
  "$ROOT/CLAUDE.md" "$ROOT/README.md" "$ROOT/README.ko.md" 2>/dev/null \
  | grep -v 'archetype-next/seed/node_modules')
if [ "$V22_LEAK" -eq 0 ]; then
  echo "PASS [V22] PLACEHOLDER_ALLOWLIST consistent (no leaks)"
  PASS=$((PASS + 1))
fi

echo ""
echo "=== V23: ASCII-only execution surface (POSIX scanner) ==="
# R11 fix: POSIX `[[:print:][:space:]]` (no GNU -P).
V23_FILES=$(LC_ALL=C grep -nv '^[[:print:][:space:]]*$' \
  "$ROOT/scaffold.sh" "$ROOT/validate.sh" \
  "$ROOT/tools"/*.sh "$ROOT/test"/*.sh \
  "$ROOT/examples/ci.yml" \
  "$ROOT/.github/workflows"/*.yml \
  2>/dev/null | wc -l | tr -d ' ')
check "V23" "non-ASCII chars in execution surface (sh/yml/bat/cmd/ps1)" "$V23_FILES" "0"

echo ""
echo "=== V24: SEED-LAST-UPDATED.txt freshness (90 warn / 180 fail) ==="
# C3-H2 fix: file content authoritative (D-15 ISO 8601), python3 arithmetic.
# Windows fallback: Microsoft Store ships a `python3` stub that prints nothing
# and exits 0, so prefer real `python` when the stub is detected.
SEED_DATE_FILE="$ROOT/examples/archetype-next/SEED-LAST-UPDATED.txt"
PY=""
if command -v python3 >/dev/null 2>&1 && python3 -c "print(1)" 2>/dev/null | grep -q '^1$'; then
  PY="python3"
elif command -v python >/dev/null 2>&1 && python -c "print(1)" 2>/dev/null | grep -q '^1$'; then
  PY="python"
fi
if [ -f "$SEED_DATE_FILE" ] && [ -n "$PY" ]; then
  SEED_DATE=$(head -1 "$SEED_DATE_FILE" | tr -d '[:space:]')
  AGE_DAYS=$($PY -c "from datetime import date; d=date.fromisoformat('$SEED_DATE'); print((date.today()-d).days)" 2>/dev/null || echo "-1")
  if [ "$AGE_DAYS" -lt 0 ]; then
    echo "FAIL [V24] SEED-LAST-UPDATED.txt parse error (got '$SEED_DATE')"
    FAIL=$((FAIL + 1))
  elif [ "$AGE_DAYS" -gt 180 ]; then
    echo "FAIL [V24] seed >180 days stale (age: ${AGE_DAYS} days). Run tools/refresh-next-seed.sh."
    FAIL=$((FAIL + 1))
  elif [ "$AGE_DAYS" -gt 90 ]; then
    echo "WARN [V24] seed >90 days old (age: ${AGE_DAYS} days). Plan refresh."
    PASS=$((PASS + 1))
  else
    echo "PASS [V24] seed age ${AGE_DAYS} days (<= 90)"
    PASS=$((PASS + 1))
  fi
else
  echo "SKIP [V24] SEED-LAST-UPDATED.txt or python interpreter not available"
fi

echo ""
echo "=== V25: (moved to PR checklist -- no-op) ==="
# R4 fix: Phase 13c migration verification moved out of validate.sh.
# PR template carries the "## Phase 13c migration verified" checkbox.
echo "SKIP [V25] migrated to PR template checklist"

echo ""
echo "=== V26: jest.config.mjs uses next/jest (.js suffix mandatory) ==="
# R16 fix: ESM-compatible import path.
JEST_CFG="$SEED/jest.config.mjs"
if [ -f "$JEST_CFG" ] && grep -q "from 'next/jest.js'" "$JEST_CFG"; then
  echo "PASS [V26] jest.config.mjs imports from 'next/jest.js'"
  PASS=$((PASS + 1))
else
  echo "FAIL [V26] jest.config.mjs missing from 'next/jest.js' import"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== V27: ci.yml fetch-depth:0 + Architecture-before-Lint + npm run test ==="
# R13 fix: ci.yml parity with verification-loop.md ordering.
CI="$ROOT/examples/ci.yml"
if grep -q 'fetch-depth: 0' "$CI"; then
  echo "PASS [V27a] ci.yml fetch-depth: 0 present"
  PASS=$((PASS + 1))
else
  echo "FAIL [V27a] ci.yml missing fetch-depth: 0"
  FAIL=$((FAIL + 1))
fi
ARCH_LINE=$(grep -n 'Architecture boundary check' "$CI" | head -1 | cut -d: -f1)
LINT_LINE=$(grep -n '^      - name: Lint$' "$CI" | head -1 | cut -d: -f1)
if [ -n "$ARCH_LINE" ] && [ -n "$LINT_LINE" ] && [ "$ARCH_LINE" -lt "$LINT_LINE" ]; then
  echo "PASS [V27b] ci.yml Architecture step appears before Lint step"
  PASS=$((PASS + 1))
else
  echo "FAIL [V27b] ci.yml Architecture step is not before Lint (Arch line: $ARCH_LINE, Lint line: $LINT_LINE)"
  FAIL=$((FAIL + 1))
fi
check_absent "V27c" "ci.yml uses 'npm run test' (not test:coverage)" \
  "$CI" '^[[:space:]]+run:[[:space:]]+npm run test:coverage'

echo ""
echo "=== V28: scaffold.sh Stage B error path coverage ==="
# RC-H2 + RR2-01 fix: --project-name required precedes archetype check.
# We grep scaffold.sh for the explicit error string definitions (no execution
# at static-check time; Tier 2 Cell 6 executes the runtime path).
if grep -q 'reserved but not yet implemented' "$ROOT/scaffold.sh"; then
  echo "PASS [V28a] scaffold.sh emits 'reserved but not yet implemented' for node-cli/library"
  PASS=$((PASS + 1))
else
  echo "FAIL [V28a] scaffold.sh missing reserved-archetype error message"
  FAIL=$((FAIL + 1))
fi
if grep -q 'unknown archetype' "$ROOT/scaffold.sh"; then
  echo "PASS [V28b] scaffold.sh emits 'unknown archetype' for invalid input"
  PASS=$((PASS + 1))
else
  echo "FAIL [V28b] scaffold.sh missing unknown-archetype error message"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "======================================="
echo "RESULTS: $PASS passed, $FAIL failed"
echo "======================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
