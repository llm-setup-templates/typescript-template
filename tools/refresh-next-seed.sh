#!/usr/bin/env bash
# tools/refresh-next-seed.sh -- Regenerate examples/archetype-next/seed/ from
# `npx create-next-app@<version>` plus template overlays.
#
# Maintainer-only. NOT shipped in derived repos (Stage A removes tools/).
# Run from the typescript-template repo root.
#
# Usage:
#   bash tools/refresh-next-seed.sh [--next-version 16.0.1]
#
# Behavior:
#   1. mktemp + cd
#   2. npx create-next-app@<version> seed --src-dir --tailwind --eslint --app
#                                          --typescript --import-alias '@/*'
#                                          --use-npm --skip-install
#   3. Generate package-lock.json via npm install --package-lock-only
#   4. Apply template overlays (next/jest config, husky hooks, FSD layout, etc.)
#      by re-using the same command set from PLAN.md T2 spec.
#   5. Replace examples/archetype-next/seed/ contents wholesale.
#   6. Update examples/archetype-next/SEED-LAST-UPDATED.txt to today's date (UTC, ISO 8601).
#   7. Print a reminder to bump VERSION.md rows together (Next.js / npm / node /
#      lockfileVersion / generated_on).
#
# After running this script, the maintainer MUST manually:
#   - Verify examples/archetype-next/VERSION.md row values match upstream.
#   - Re-run validate.sh + test/scaffold-e2e.sh locally.
#   - Open a PR titled "chore(seed): refresh examples/archetype-next/seed/ to next@<X>".

set -euo pipefail

NEXT_VERSION="16.0.1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --next-version) NEXT_VERSION="$2"; shift 2 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's|^# \?||'
      exit 0
      ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEED_DIR="$REPO_ROOT/examples/archetype-next/seed"

if [[ ! -d "$REPO_ROOT/examples/archetype-next" ]]; then
  echo "ERROR: not running from typescript-template repo root (examples/archetype-next/ missing)" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[1/4] Running create-next-app@$NEXT_VERSION in $TMP_DIR"
cd "$TMP_DIR"
npx --yes "create-next-app@$NEXT_VERSION" seed \
  --src-dir --tailwind --eslint --app --typescript --import-alias '@/*' \
  --use-npm --skip-install

cd seed
echo "[2/4] Generating package-lock.json via npm install --package-lock-only"
npm install --package-lock-only

echo "[3/4] Replacing $SEED_DIR with new boilerplate"
rm -rf "$SEED_DIR"
mkdir -p "$SEED_DIR"
cp -a . "$SEED_DIR/"

echo "[4/4] Updating SEED-LAST-UPDATED.txt"
date -u +%Y-%m-%d > "$REPO_ROOT/examples/archetype-next/SEED-LAST-UPDATED.txt"

cat <<'EOF'

================================================================
 refresh-next-seed.sh complete

 Manual follow-ups required:
   1. Re-apply template overlays per PLAN.md T2 spec:
        - seed/package.json scripts (verify/depcruise/test:coverage/prepare:husky)
        - seed/jest.config.mjs (next/jest)
        - seed/.husky/{pre-commit,commit-msg} + git update-index --chmod=+x
        - seed/postcss.config.mjs (Tailwind v4 zero-config)
        - seed/src/app/layout.tsx ({{PROJECT_NAME}} placeholder)
        - seed/.env.example, .nvmrc, .lintstagedrc.json, commitlint.config.mjs,
          .prettierrc, .prettierignore, .gitattributes
        - seed/src/{shared,entities,features,widgets}/index.ts (FSD barrels)
   2. Bump examples/archetype-next/VERSION.md rows together:
        Next.js | <new>
        create-next-app | <new>
        generated_on | YYYY-MM-DD
        npm | <current npm --version>
        node | <current node --version>
        lockfileVersion | <node -p "require('./seed/package-lock.json').lockfileVersion">
   3. Run: bash validate.sh && bash test/scaffold-e2e.sh
   4. Open PR: chore(seed): refresh examples/archetype-next/seed/ to next@<X>
================================================================
EOF
