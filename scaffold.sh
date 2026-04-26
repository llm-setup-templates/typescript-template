#!/usr/bin/env bash
# scaffold.sh -- Convert a freshly-cloned typescript-template into a project-specific scaffold.
#
# Usage:
#   bash ./scaffold.sh --project-name <hyphen-case> [--package-name <npm-name>] \
#                      [--archetype next] [--doc-modules core[,reports,briefings,extended]] [--dry-run]
#
# This script is single-use. It must be run on a freshly cloned template
# (detected via presence of validate.sh). After execution, it self-deletes.
#
# See ADR-002 for architecture rationale (offline Next.js seed +
# Stage A-H 8-stage pipeline).

# ----------------------------------------------------------------
# Bash interpreter guard [Spring 13b parity / Phase 13b D-12]
# Windows PowerShell can invoke `./scaffold.sh` via .sh file association
# without actually running bash -- exit 0 with no side effects. That silent
# success is more dangerous than a visible failure. This guard refuses to
# run under any non-bash interpreter and instructs the user to prefix `bash `.
# Note: PowerShell's `.\scaffold.sh` form bypasses this guard entirely
# (ShellExecute path doesn't parse the script body). See RATIONALE.md
# (section) PowerShell Silent-No-Op for the empirical test matrix.
# ----------------------------------------------------------------
# BASH_VERSION: bash-only shell variable (dash/ash/zsh/PowerShell do not set it).
# BASH: bash-only shell variable holding the full path to the bash binary.
# Checking BOTH closes the M-03 edge case where a parent PowerShell process
# exports BASH_VERSION into the environment and a non-bash child inherits it.
_not_bash=0
[ -z "${BASH_VERSION:-}" ] && _not_bash=1
[ -z "${BASH:-}" ] && _not_bash=1
case "${BASH##*/}" in
  bash|bash.exe) ;;
  *) _not_bash=1 ;;
esac
if [ "$_not_bash" -eq 1 ]; then
  echo "ERROR: scaffold.sh must be executed by Bash." >&2
  echo "       Detected: non-bash interpreter (likely PowerShell/cmd/sh/dash)." >&2
  echo "       Fix: run with an explicit bash prefix:" >&2
  echo "         bash ./scaffold.sh --project-name <name> --archetype next" >&2
  echo "       On Windows, prefer Git Bash or WSL over PowerShell." >&2
  exit 1
fi
unset _not_bash

set -euo pipefail

# ----------------------------------------------------------------
# preflight -- required tools
# CL-03 fix: required vs optional tools split.
# Required: bash + git + sed + awk + node (Stage C VERSION.md cross-check).
# Optional: npx (Stage F next telemetry -- best-effort).
# ----------------------------------------------------------------
for tool in git sed awk node; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: required tool '$tool' not found in PATH." >&2
    echo "       Install '$tool' and re-run scaffold.sh." >&2
    exit 1
  fi
done

# ----------------------------------------------------------------
# parse_args
# ----------------------------------------------------------------
PROJECT_NAME=""
PACKAGE_NAME=""
ARCHETYPE="next"
DOC_MODULES="core"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $0 --project-name <hyphen-case> [options]

Required:
  --project-name <name>     Project name in hyphen-case (e.g. my-app).
                            Pattern: ^[a-z][a-z0-9-]*\$

Optional:
  --package-name <name>     npm package name. Defaults to --project-name.
                            npm scope supported: @org/name.
                            Pattern: ^(@[a-z0-9-]+/)?[a-z0-9][a-z0-9-]*\$
  --archetype <name>        next (default, only implemented).
                            Reserved: node-cli, library (exit 1 with explicit message).
  --doc-modules <list>      comma-separated from {core,reports,briefings,extended}
                            default: core. 'core' is mandatory.
  --dry-run                 Print planned actions without writing.
  -h, --help                This message.

Examples:
  bash ./scaffold.sh --project-name my-app --archetype next
  bash ./scaffold.sh --project-name acme-portal --package-name @acme/portal --doc-modules core,reports
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name)  PROJECT_NAME="$2"; shift 2 ;;
    --package-name)  PACKAGE_NAME="$2"; shift 2 ;;
    --archetype)     ARCHETYPE="$2"; shift 2 ;;
    --doc-modules)   DOC_MODULES="$2"; shift 2 ;;
    --dry-run)       DRY_RUN=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               echo "ERROR: unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# ----------------------------------------------------------------
# validate args
# D-13 (rev.3): --project-name required, no fallback.
#               D-13 fires before archetype check so V28 reaches the
#               Stage B error path with --project-name v28-foo passed.
# D-14 (rev.3): --package-name optional, npm scope grammar.
# ----------------------------------------------------------------
if [[ -z "$PROJECT_NAME" ]]; then
  echo "ERROR: --project-name is required" >&2
  usage >&2
  exit 1
fi

if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "ERROR: --project-name must be hyphen-case (lowercase, starts with letter, letters/digits/hyphens)" >&2
  echo "       got: '$PROJECT_NAME'" >&2
  exit 1
fi

# Default --package-name to --project-name (plain, no scope).
if [[ -z "$PACKAGE_NAME" ]]; then
  PACKAGE_NAME="$PROJECT_NAME"
fi

if ! [[ "$PACKAGE_NAME" =~ ^(@[a-z0-9-]+/)?[a-z0-9][a-z0-9-]*$ ]]; then
  echo "ERROR: --package-name must match ^(@scope/)?name$ (lowercase, hyphens allowed)" >&2
  echo "       got: '$PACKAGE_NAME'" >&2
  exit 1
fi

# doc-modules: must include 'core'; each item must be in {core,reports,briefings,extended}
if [[ ",$DOC_MODULES," != *",core,"* ]]; then
  echo "ERROR: --doc-modules must include 'core' (got '$DOC_MODULES')" >&2
  exit 1
fi
IFS=',' read -ra DOC_MODS_ARR <<<"$DOC_MODULES"
for m in "${DOC_MODS_ARR[@]}"; do
  case "$m" in
    core|reports|briefings|extended) ;;
    *) echo "ERROR: unknown doc module '$m' (valid: core,reports,briefings,extended)" >&2; exit 1 ;;
  esac
done

# ----------------------------------------------------------------
# freshness check -- validate.sh is template-only; its presence is the
# reliable marker that scaffold.sh has not yet run.
# R14 fix: position before plan summary, mirrors Spring 13b line 134.
# ----------------------------------------------------------------
if [[ ! -f validate.sh ]]; then
  echo "ERROR: validate.sh not found -- this doesn't look like a freshly-cloned template." >&2
  echo "       scaffold.sh is single-use. Re-clone the template to start over:" >&2
  echo "         git clone https://github.com/llm-setup-templates/typescript-template <new-dir>" >&2
  exit 1
fi

# ----------------------------------------------------------------
# plan summary
# ----------------------------------------------------------------
echo "==============================================="
echo " scaffold.sh -- typescript-template"
echo "==============================================="
echo " PROJECT_NAME : $PROJECT_NAME"
echo " PACKAGE_NAME : $PACKAGE_NAME"
echo " ARCHETYPE    : $ARCHETYPE"
echo " DOC_MODULES  : $DOC_MODULES"
echo " DRY_RUN      : $DRY_RUN"
echo "==============================================="
if [[ $DRY_RUN -eq 1 ]]; then
  echo " (dry-run: no files will be modified)"
fi
echo ""

# ----------------------------------------------------------------
# helpers (D-11): run / run_eval / substitute verbatim from
# python-template/scaffold.sh line 150-180.
# Spring `migrate_initializr_seed_package` (line 192-230) is intentionally
# NOT carried -- Spring-only Java package migration not applicable to TS.
# ----------------------------------------------------------------
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

run_eval() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] $*"
  else
    eval "$*"
  fi
}

substitute() {
  # Portable in-place substitution (GNU sed + BSD sed compatible).
  local pattern="$1" replacement="$2" file="$3"
  if [[ ! -f "$file" ]]; then
    echo "  WARN: substitute skip (file not found): $file"
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] substitute '$pattern' -> '$replacement' in $file"
  else
    sed "s|$pattern|$replacement|g" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
}

# ----------------------------------------------------------------
# Stage A -- remove template-only files
#   scaffold.sh is NOT in this list (self-deletes in Stage H).
#   R2 fix: tools/ removed in Stage A (refresh-next-seed.sh is template-only).
#   R5 fix: CODERABBIT-PROMPT-GUIDE.md removed (Spring 13b parity).
# ----------------------------------------------------------------
echo "[Stage A] Remove template-only files"
TEMPLATE_ONLY=(
  validate.sh
  .github/workflows/validate.yml
  .github/workflows/scaffold-e2e.yml
  test
  RATIONALE.md
  CODERABBIT-PROMPT-GUIDE.md
  tools
  docs/architecture/decisions/ADR-002-clone-script-scaffolding.md
  docs/architecture/decisions/RFC-001-vitest-migration.md
  # examples/ : KEEP until Stage F
  # .claude/ : KEEP -- derived repo reuses agent rules
  # scaffold.sh : self-delete in Stage H
)
for f in "${TEMPLATE_ONLY[@]}"; do
  if [[ -e "$f" ]]; then
    run rm -rf "$f"
  fi
done

# ----------------------------------------------------------------
# Stage B -- select archetype
#   R18 fix: explicit reserved-vs-unknown stderr distinction.
#   V28 + Tier 2 Cell 6 grep stderr for these substrings.
# ----------------------------------------------------------------
echo "[Stage B] Select archetype: $ARCHETYPE"
case "$ARCHETYPE" in
  next) ;;
  node-cli|library)
    echo "ERROR: --archetype $ARCHETYPE is reserved but not yet implemented." >&2
    echo "       For TypeScript Phase 13c, only --archetype next is supported." >&2
    echo "       Track future archetype expansion in docs/architecture/decisions/ADR-002." >&2
    exit 1
    ;;
  *)
    echo "ERROR: unknown archetype: $ARCHETYPE" >&2
    echo "       Valid: next (reserved future: node-cli, library)" >&2
    exit 1
    ;;
esac

# ----------------------------------------------------------------
# Stage C -- import Next seed + overlay template assets
#   D-20: seed FIRST, then template asset overlay.
#   D-16 + RC-M1 + C13C-R5: VERSION.md major cross-check (literal '|' FS).
#   D-19 + RC-H1: --src-dir adopted, src/app/layout.tsx must exist.
# ----------------------------------------------------------------
echo "[Stage C] Import Next seed + overlay template assets"

# Initializr-style seed import: copy contents of seed/ to repo root.
run_eval "cp -a examples/archetype-next/seed/. ."

# VERSION.md major cross-check (rev.4 -- D-16 + RC-M1).
if [[ $DRY_RUN -eq 0 ]]; then
  SEED_NEXT_MAJOR=$(awk -F'|' '/Next\.js/{gsub(/[^0-9.]/,"",$3); print $3}' \
    examples/archetype-next/VERSION.md | cut -d. -f1)
  PKG_NEXT_MAJOR=$(node -p "require('./package.json').dependencies.next.replace(/[^0-9.]/g,'').split('.')[0]")
  if [[ -z "$SEED_NEXT_MAJOR" || -z "$PKG_NEXT_MAJOR" ]]; then
    echo "ERROR: Stage C major-check empty (SEED='$SEED_NEXT_MAJOR' PKG='$PKG_NEXT_MAJOR'). Re-seed required." >&2
    echo "       Maintainer-only: bash tools/refresh-next-seed.sh" >&2
    exit 1
  fi
  if [[ "$SEED_NEXT_MAJOR" != "$PKG_NEXT_MAJOR" ]]; then
    echo "ERROR: VERSION.md Next major ($SEED_NEXT_MAJOR) != package.json ($PKG_NEXT_MAJOR). Re-seed required." >&2
    echo "       Maintainer-only: bash tools/refresh-next-seed.sh" >&2
    exit 1
  fi
else
  echo "  [dry-run] cross-check examples/archetype-next/VERSION.md Next major == package.json dependencies.next major"
fi

# Template asset overlay (D-20: explicit cp commands, R12 fix).
run mkdir -p .github/workflows
run cp examples/ci.yml .github/workflows/ci.yml
# .claude/, README, CLAUDE.md already at template root -- no overlay needed.

# ----------------------------------------------------------------
# Stage D -- substitute placeholders
#   D-22: every mutation goes through the run helper or DRY_RUN guard.
#   D-23: placeholder grammar locked to \{\{[A-Z_]+\}\}.
#   D-24: bulk find scope excludes examples/, node_modules/, .git/.
#   D-19 + RC-H1: src/app/layout.tsx existence asserted.
# ----------------------------------------------------------------
echo "[Stage D] Substitute placeholders"

# CLAUDE.md
substitute '{{PROJECT_NAME}}' "$PROJECT_NAME" CLAUDE.md
substitute '{{PROJECT_ONE_LINER}}' "_(fill in your project description)_" CLAUDE.md

# Stage C post-condition (RC-H1 fix): assert src/app/layout.tsx exists
# before substituting it. seed must be created with --src-dir.
if [[ $DRY_RUN -eq 0 ]]; then
  [[ -f src/app/layout.tsx ]] || {
    echo "ERROR: seed missing src/app/layout.tsx (was --src-dir used in seed generation?)" >&2
    exit 1
  }
fi

# src/app/layout.tsx -- Next.js metadata (--src-dir adopted, D-19 + RC-H1)
substitute '{{PROJECT_NAME}}' "$PROJECT_NAME" src/app/layout.tsx

# package.json -- name field (D-14: PACKAGE_NAME default $PROJECT_NAME)
substitute '"name": "{{PROJECT_NAME}}"' "\"name\": \"$PACKAGE_NAME\"" package.json

# Bulk find/sed across **/*.{md,yml,yaml} (excluding examples/, node_modules/, .git/).
# C13C-R1 + D-22 + D-24 + RC-H3 fix (rev.3): explicit DRY_RUN guard.
if [[ $DRY_RUN -eq 0 ]]; then
  find . -type f \( -name '*.md' -o -name '*.yml' -o -name '*.yaml' \) \
    -not -path './examples/*' -not -path './node_modules/*' -not -path './.git/*' -print0 | while IFS= read -r -d '' f; do
    sed "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  done
else
  echo "  [dry-run] substitute {{PROJECT_NAME}} -> $PROJECT_NAME in **/*.{md,yml,yaml} (excl. examples/, node_modules/, .git/)"
fi

# ----------------------------------------------------------------
# Stage E -- trim unselected doc modules
# ----------------------------------------------------------------
echo "[Stage E] Trim doc modules (kept: $DOC_MODULES)"

has_module() {
  [[ ",$DOC_MODULES," == *",$1,"* ]]
}

if ! has_module "reports"; then
  run rm -rf docs/reports
fi
if ! has_module "briefings"; then
  run rm -rf docs/briefings
fi
if ! has_module "extended"; then
  run rm -f docs/architecture/containers.md docs/architecture/DFD.md
  run rm -rf docs/data
fi

# ----------------------------------------------------------------
# Stage F -- cleanup
#   D-17 (rev.3): next telemetry disable here, best-effort.
#   RC-L2 fix: tools/ already removed in Stage A; defensive 2nd attempt.
# ----------------------------------------------------------------
echo "[Stage F] Remove examples/ + best-effort next telemetry disable"
run rm -rf examples
# tools/ already removed in Stage A -- belt-and-suspenders re-attempt for re-runs (RC-L2).
run rm -rf tools 2>/dev/null || true

# next telemetry disable (best-effort, D-17). Optional: requires npx.
if [[ $DRY_RUN -eq 0 ]] && command -v npx >/dev/null 2>&1; then
  npx --no-install next telemetry disable 2>/dev/null || true
fi
# If telemetry was not auto-disabled, the seed/.env.example carries
# NEXT_TELEMETRY_DISABLED=1 as a visible policy default for the user to enable.

# ----------------------------------------------------------------
# Stage G -- reinit git (fresh history)
# ----------------------------------------------------------------
echo "[Stage G] Reinit git (fresh history)"
run rm -rf .git
run git init -b main
# user.name / user.email are read from the user's global git config or set
# explicitly in CI (Tier 2 / Tier 3). scaffold.sh does not configure them.

# ----------------------------------------------------------------
# Stage H -- report + self-delete
#   R9 + C13C-R10: Windows file lock warning.
# ----------------------------------------------------------------
echo "[Stage H] Report + self-delete"
echo ""
echo "==============================================="
echo " scaffold complete"
echo "==============================================="
cat <<EOF

Next steps:
  1) Install dependencies (activates Husky hooks via the prepare script):
       npm install

  2) Verify locally:
       npm run verify

  3) Commit the scaffold:
       git add .
       git commit -m "feat(scaffold): initial project setup"

  4) (Optional) Publish to GitHub:
       gh auth status
       gh repo create $PROJECT_NAME --private --source=. --remote=origin
       git push -u origin main
       # If 'git push' does not trigger CI on a brand-new repo, fire manually:
       gh workflow run ci.yml --ref main

TODO before production:
  - .github/CODEOWNERS -- replace @YOUR_ORG/* placeholders with real team handles
  - .env.example -- fill in NEXT_PUBLIC_* and other project-specific env vars
  - README.md / CLAUDE.md -- replace {{PROJECT_ONE_LINER}} with your project description

EOF

# Self-delete scaffold.sh.
# On Linux/macOS the inode is preserved until the process closes, so
# rm -- "\$0" succeeds from within the running script. On Windows Git Bash
# the file is locked; we emit a warning and ask the user to delete manually.
# Tier 2 OS-gated assertion (C13C-R10): Linux/macOS asserts `! -f scaffold.sh`,
# Windows runner matches the warning text only.
if [[ $DRY_RUN -eq 0 ]]; then
  if rm -- "$0" 2>/dev/null; then
    :
  else
    echo "WARN: Could not auto-remove scaffold.sh (likely Windows file lock)."
    echo "      Delete manually: rm scaffold.sh"
  fi
fi

exit 0
