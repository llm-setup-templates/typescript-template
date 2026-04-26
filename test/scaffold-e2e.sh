#!/usr/bin/env bash
# E2E test for scaffold.sh (TypeScript Phase 13c).
#
# Usage:
#   bash test/scaffold-e2e.sh [doc-modules]
#   bash test/scaffold-e2e.sh --cell <1..6>
#
# 6 cells covered by .github/workflows/validate.yml matrix:
#   1. core
#   2. core,reports
#   3. core,reports,briefings
#   4. core,reports,briefings,extended
#   5. core --dry-run                              (DRY_RUN invariant + git diff --exit-code + stdout grep)
#   6. core --archetype invalid-foo                (Stage B error path V28)

set -uo pipefail

CELL=""
DOC_MODULES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cell) CELL="$2"; shift 2 ;;
    *) DOC_MODULES="$1"; shift ;;
  esac
done

# Default to cell 1 (core) if no args.
if [[ -z "$CELL" && -z "$DOC_MODULES" ]]; then
  CELL="1"
fi

# Map --cell <N> to (doc_modules, extra_args, expectation).
CELL_DOC_MODULES=""
CELL_EXTRA_ARGS=""
CELL_EXPECT_FAIL=0
CELL_EXPECT_DRY_RUN=0
CELL_INVALID_ARCHETYPE=0

case "$CELL" in
  1) CELL_DOC_MODULES="core" ;;
  2) CELL_DOC_MODULES="core,reports" ;;
  3) CELL_DOC_MODULES="core,reports,briefings" ;;
  4) CELL_DOC_MODULES="core,reports,briefings,extended" ;;
  5) CELL_DOC_MODULES="core"; CELL_EXTRA_ARGS="--dry-run"; CELL_EXPECT_DRY_RUN=1 ;;
  6) CELL_DOC_MODULES="core"; CELL_EXTRA_ARGS="--archetype invalid-foo"; CELL_EXPECT_FAIL=1; CELL_INVALID_ARCHETYPE=1 ;;
  "")
    CELL_DOC_MODULES="$DOC_MODULES"
    case "$DOC_MODULES" in
      'core'|'core,reports'|'core,reports,briefings'|'core,reports,briefings,extended') ;;
      *) echo "[e2e] invalid doc-modules: $DOC_MODULES" >&2; exit 1 ;;
    esac
    ;;
  *) echo "[e2e] invalid cell: $CELL (valid 1..6)" >&2; exit 1 ;;
esac

TEMPLATE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR_E2E="$(mktemp -d -t scaffold-e2e-XXXXXX)"
trap 'rm -rf "$TMPDIR_E2E"' EXIT

# Per-cell npm cache isolation (C13C-R6 + RC-M2 fix: $TMPDIR Linux unset -> /tmp).
NPM_CACHE_DIR="${TMPDIR:-/tmp}/npm-cache/cell-${CELL:-noncell}"
mkdir -p "$NPM_CACHE_DIR"
export npm_config_cache="$NPM_CACHE_DIR"

PROJECT_NAME="e2e-cell${CELL:-x}"

echo "[e2e] template     : $TEMPLATE_ROOT"
echo "[e2e] tmpdir       : $TMPDIR_E2E"
echo "[e2e] cell         : ${CELL:-(positional)}"
echo "[e2e] doc-modules  : $CELL_DOC_MODULES"
echo "[e2e] extra args   : $CELL_EXTRA_ARGS"
echo "[e2e] npm_cache    : $NPM_CACHE_DIR"
echo "[e2e] expect fail  : $CELL_EXPECT_FAIL"
echo "[e2e] expect dry-run : $CELL_EXPECT_DRY_RUN"

# 1. Copy template WITHOUT .git and test/ (portable, no rsync dependency)
DERIVED="$TMPDIR_E2E/$PROJECT_NAME"
mkdir -p "$DERIVED"
cp -a "$TEMPLATE_ROOT/." "$DERIVED/"
rm -rf "$DERIVED/.git" "$DERIVED/test"

cd "$DERIVED"

# Stage A pre-condition: validate.sh present in derived
test -f validate.sh || { echo "FAIL: pre-scaffold validate.sh missing"; exit 1; }

# 2. Run scaffold.sh
SCAFFOLD_OUT="$TMPDIR_E2E/scaffold.out"
SCAFFOLD_ERR="$TMPDIR_E2E/scaffold.err"

if [[ "$CELL_INVALID_ARCHETYPE" -eq 1 ]]; then
  # Cell 6: Stage B error path. Override --archetype.
  set +e
  bash scaffold.sh --project-name "$PROJECT_NAME" --archetype invalid-foo --doc-modules "$CELL_DOC_MODULES" \
    > "$SCAFFOLD_OUT" 2> "$SCAFFOLD_ERR"
  RC=$?
  set -e
  if [[ $RC -eq 0 ]]; then
    echo "FAIL [V28+Cell6] invalid archetype scaffold succeeded (expected exit 1)"
    cat "$SCAFFOLD_ERR"
    exit 1
  fi
  if grep -q 'unknown archetype' "$SCAFFOLD_ERR"; then
    echo "PASS [Cell6] Stage B 'unknown archetype' error path"
    exit 0
  else
    echo "FAIL [Cell6] expected 'unknown archetype' in stderr; got:"
    cat "$SCAFFOLD_ERR"
    exit 1
  fi
fi

if [[ "$CELL_EXPECT_DRY_RUN" -eq 1 ]]; then
  # Cell 5: --dry-run invariant. C3-H1 fix: capture stdout for [dry-run] grep.
  # D-22 fix: git diff --exit-code on derived must show no changes.
  git -C "$DERIVED" init -q -b main
  git -C "$DERIVED" add -A >/dev/null 2>&1 || true
  git -C "$DERIVED" -c user.name=e2e -c user.email=e2e@e2e.local commit -qm "pre-scaffold snapshot" >/dev/null 2>&1 || true

  set +e
  bash scaffold.sh --project-name "$PROJECT_NAME" --archetype next --doc-modules "$CELL_DOC_MODULES" --dry-run \
    > "$SCAFFOLD_OUT" 2> "$SCAFFOLD_ERR"
  RC=$?
  set -e
  if [[ $RC -ne 0 ]]; then
    echo "FAIL [Cell5] dry-run exit $RC (expected 0)"
    cat "$SCAFFOLD_ERR"
    exit 1
  fi
  if ! grep -q '\[dry-run\]' "$SCAFFOLD_OUT"; then
    echo "FAIL [Cell5] dry-run produced no '[dry-run]' lines (no-op script suspected)"
    cat "$SCAFFOLD_OUT"
    exit 1
  fi
  echo "PASS [Cell5] dry-run emitted [dry-run] lines"

  # git diff --exit-code: nothing changed
  if ! git -C "$DERIVED" diff --exit-code >/dev/null 2>&1; then
    echo "FAIL [Cell5] dry-run mutated working tree (D-22 invariant)"
    git -C "$DERIVED" diff --stat
    exit 1
  fi
  echo "PASS [Cell5] dry-run left working tree unchanged (D-22 invariant)"
  exit 0
fi

# Cells 1-4: real scaffold execution.
bash scaffold.sh --project-name "$PROJECT_NAME" --archetype next --doc-modules "$CELL_DOC_MODULES"

# 3. Structural post-conditions
test -f package.json                        || { echo "FAIL: package.json missing"; exit 1; }
test -f .github/workflows/ci.yml            || { echo "FAIL: ci.yml missing"; exit 1; }
test -f tsconfig.json                       || { echo "FAIL: tsconfig.json missing"; exit 1; }
test -f src/app/layout.tsx                  || { echo "FAIL: src/app/layout.tsx missing (--src-dir D-19)"; exit 1; }

# package.json name substituted (D-14 default = PROJECT_NAME plain form)
grep -q "\"name\": \"$PROJECT_NAME\"" package.json \
  || { echo "FAIL: package.json name not substituted"; exit 1; }

# layout.tsx PROJECT_NAME substituted (RR2-02 fix)
grep -q "$PROJECT_NAME" src/app/layout.tsx \
  || { echo "FAIL: src/app/layout.tsx PROJECT_NAME not substituted"; exit 1; }
! grep -q '{{PROJECT_NAME}}' src/app/layout.tsx \
  || { echo "FAIL: layout.tsx still has {{PROJECT_NAME}} placeholder"; exit 1; }

# CLAUDE.md substituted
! grep -q '{{PROJECT_NAME}}' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md PROJECT_NAME placeholder leaked"; exit 1; }
! grep -q '{{PROJECT_ONE_LINER}}' CLAUDE.md \
  || { echo "FAIL: CLAUDE.md PROJECT_ONE_LINER placeholder leaked"; exit 1; }

# Template-only files removed by Stage A/F
test ! -f validate.sh                       || { echo "FAIL: validate.sh leaked"; exit 1; }
test ! -f .github/workflows/validate.yml    || { echo "FAIL: validate.yml leaked"; exit 1; }
test ! -f .github/workflows/scaffold-e2e.yml || { echo "FAIL: scaffold-e2e.yml leaked"; exit 1; }
test ! -d examples                          || { echo "FAIL: examples/ not removed (Stage F)"; exit 1; }
test ! -d test                              || { echo "FAIL: test/ leaked"; exit 1; }
test ! -d tools                             || { echo "FAIL: tools/ leaked"; exit 1; }
test ! -f RATIONALE.md                      || { echo "FAIL: RATIONALE.md leaked"; exit 1; }
test ! -f CODERABBIT-PROMPT-GUIDE.md        || { echo "FAIL: CODERABBIT-PROMPT-GUIDE leaked"; exit 1; }
test ! -f docs/architecture/decisions/ADR-002-clone-script-scaffolding.md \
  || { echo "FAIL: ADR-002 leaked"; exit 1; }
test ! -f docs/architecture/decisions/RFC-001-vitest-migration.md \
  || { echo "FAIL: RFC-001 leaked"; exit 1; }

# scaffold.sh self-delete (Linux/macOS only -- C13C-R10 OS-gated)
case "$(uname -s)" in
  Linux*|Darwin*)
    test ! -f scaffold.sh || { echo "FAIL: scaffold.sh not self-removed on Unix"; exit 1; }
    ;;
  *)
    echo "[e2e] skipping scaffold.sh self-delete check (Windows file lock -- see RATIONALE.md)"
    ;;
esac

# .claude/ preserved (derived repo agent rules)
test -d .claude/rules || { echo "FAIL: .claude/rules missing"; exit 1; }

# 4. Placeholder leak (CRITICAL -- code/config files)
LEAKS=$(grep -rE '\{\{[A-Z_]+\}\}' . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.mjs" \
  --include="*.json" --include="*.yml" --include="*.yaml" \
  --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null || true)
if [ -n "$LEAKS" ]; then
  echo "FAIL: placeholder leak in code/config files:"
  echo "$LEAKS"
  exit 1
fi

# 5. doc-modules verification
case "$CELL_DOC_MODULES" in
  'core')
    test ! -d docs/reports    || { echo "FAIL: reports leaked under 'core' only"; exit 1; }
    test ! -d docs/briefings  || { echo "FAIL: briefings leaked under 'core' only"; exit 1; }
    test ! -f docs/architecture/containers.md || { echo "FAIL: extended (containers.md) leaked"; exit 1; }
    test ! -f docs/architecture/DFD.md || { echo "FAIL: extended (DFD.md) leaked"; exit 1; }
    test ! -d docs/data       || { echo "FAIL: extended (docs/data/) leaked"; exit 1; }
    ;;
  'core,reports')
    test -d docs/reports      || { echo "FAIL: reports missing under core,reports"; exit 1; }
    test ! -d docs/briefings  || { echo "FAIL: briefings leaked"; exit 1; }
    ;;
  'core,reports,briefings')
    test -d docs/reports      || { echo "FAIL: reports missing"; exit 1; }
    test -d docs/briefings    || { echo "FAIL: briefings missing"; exit 1; }
    test ! -f docs/architecture/containers.md || { echo "FAIL: extended leaked"; exit 1; }
    ;;
  'core,reports,briefings,extended')
    test -d docs/reports      || { echo "FAIL: reports missing in full combo"; exit 1; }
    test -d docs/briefings    || { echo "FAIL: briefings missing"; exit 1; }
    test -f docs/architecture/containers.md || { echo "FAIL: extended missing"; exit 1; }
    ;;
esac

echo "[e2e] structural checks PASS"

# 6. Husky activation smoke test (C13C-R8) -- Cell 1 only.
# Verifies that `npm install` activates Husky's commit-msg hook.
if [[ "$CELL" = "1" ]] && command -v npm >/dev/null 2>&1; then
  echo "[e2e] running npm ci for Husky smoke test (cell 1)..."
  if npm ci --no-audit --no-fund 2>&1 | tail -5; then
    HOOKS_PATH=$(git config --get core.hooksPath 2>/dev/null || echo "")
    if [[ "$HOOKS_PATH" == *".husky"* ]] || [[ -d ".husky/_" ]]; then
      echo "PASS [Cell1 Husky] core.hooksPath set to .husky (or _/ created)"
    else
      echo "WARN [Cell1 Husky] core.hooksPath not detected after npm ci (got: '$HOOKS_PATH')"
    fi

    # Negative test: bad commit message should fail commit-msg hook (exit non-zero).
    git -c user.name=e2e -c user.email=e2e@e2e.local init -q -b main 2>/dev/null || true
    git add -A >/dev/null 2>&1 || true
    set +e
    git -c user.name=e2e -c user.email=e2e@e2e.local commit -qm "BAD MESSAGE NO TYPE" 2>/dev/null
    BAD_RC=$?
    set -e
    if [[ $BAD_RC -ne 0 ]]; then
      echo "PASS [Cell1 Husky] commit-msg hook rejected bad message (exit $BAD_RC)"
    else
      echo "WARN [Cell1 Husky] commit-msg hook did not reject bad message (Husky may not be activated)"
    fi
  else
    echo "WARN [Cell1] npm ci failed; skipping Husky smoke test"
  fi
fi

# 7. npm verify (most important -- only if npm available)
if command -v npm >/dev/null 2>&1 && [[ "$CELL" != "1" ]]; then
  # Cell 1 already ran npm ci above; cells 2-4 fresh install.
  echo "[e2e] running npm ci..."
  npm ci --no-audit --no-fund
fi

if command -v npm >/dev/null 2>&1; then
  echo "[e2e] running npm run verify..."
  npm run verify
  echo "[e2e] npm run verify PASS"
else
  echo "[e2e] npm not available -- skipping verify (CI must run it)"
fi

echo "[e2e] PASS: cell=$CELL doc-modules=$CELL_DOC_MODULES"
