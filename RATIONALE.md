# RATIONALE — TypeScript Template Design Notes

> Out-of-band design rationale that doesn't fit in CLAUDE.md (LLM agent rules)
> or SETUP.md (user-facing how-to). Captures the "why" behind non-obvious
> decisions so future maintainers don't relitigate them.

## PowerShell Silent-No-Op — Accepted Limitation

scaffold.sh contains a Bash interpreter guard (`BASH_VERSION` + basename of
`$BASH`) that refuses to run under dash/sh/zsh and prints a clear error.
**This guard cannot fire under PowerShell** because PowerShell's `.\<filename>`
invocation path bypasses the script body entirely:

- For `.ps1` files, PowerShell runs the file as PowerShell script.
- For other extensions (`.sh`, `.bat`, etc.), PowerShell delegates via
  ShellExecute, which on Windows looks up the file association in the
  registry. Git for Windows registers `.sh` to open in a text editor by
  default — not to execute. In headless contexts (CI runners, agent
  sandboxes) where no editor is present, ShellExecute fails silently.
- The script body is never parsed by any shell that could reach the guard.
  Result: PowerShell `.\scaffold.sh ...` exits 0 with no output and no
  scaffolding side effects.

This pattern was empirically confirmed in Phase 13b Spring (`spring-template/RATIONALE.md`).
Phase 13c TypeScript inherits the same limitation. The two alternatives —
ship a parallel `scaffold.ps1` or require Bash invocation — have very
different cost profiles. Shipping `.ps1` doubles the maintenance burden
and PowerShell's substitution helpers have different semantics from sed
(regex flavor, line endings, encoding); drift between the two scripts
becomes a failure mode of its own. Documenting "Run under Bash, not
PowerShell" in SETUP.md Quick Start + one Troubleshooting row is the
cheaper path.

## Husky Activation — Configured at Scaffold, Activated on `npm install`

Husky 9 is the only template-bundled local git hook framework (Spring/Python
use CI-side commitlint instead). The activation flow surprises users who
expect "scaffold.sh finishes ⇒ hooks active":

1. **Scaffold time**: scaffold.sh's Stage C copies seed/.husky/ contents
   into the derived repo and assigns `100755` mode via `git update-index`.
   `package.json` carries `"prepare": "husky"`.
2. **npm install time**: npm executes the `prepare` lifecycle script. Husky
   creates `.husky/_/` (the runtime helper directory) and runs
   `git config core.hooksPath .husky` so git starts invoking the bundled
   hooks for `pre-commit` and `commit-msg`.
3. **Without `npm install`**: hooks are dormant. `git commit` succeeds
   without lint-staged or commitlint. This is a feature, not a bug —
   users in CI-only flows or those who skip `npm install` retain control.

Phase 13c rules wording (`.claude/rules/git-workflow.md`) was rewritten to
say "configured at scaffold, activated on `npm install`" so derived-repo
agents don't claim the hooks are live before the first install.

## Next.js Seed — Why Bake `examples/archetype-next/seed/`

Phase 13b Spring chose the same architectural pattern for Spring Initializr:
bake the seed in-tree, do not call `start.spring.io` at scaffold time.
Phase 13c applies the same logic to Next.js:

- `npx create-next-app@<version>` is a network call to npm's registry.
  Codex sandboxes (current default `workspace-write`) block port 443.
  Air-gapped CI runners block egress entirely.
- Without the seed, scaffold.sh would have to depend on npm registry
  reachability — violating ADR-002's "single-dependency scaffolding"
  principle (`bash` + `git` only).
- The seed is regenerated on the template side via `tools/refresh-next-seed.sh`
  + the weekly `scaffold-e2e.yml` cron. Derived repos never call
  `npx create-next-app`.

The cost is staleness: the baked seed is a snapshot of Next 16.0.1 at
template release. Mitigations:

1. **scaffold-e2e weekly cron** catches build breaks before users do.
2. **validate.sh V24** enforces SEED-LAST-UPDATED.txt freshness:
   - 90+ days old → warn
   - 180+ days old → fail
3. **VERSION.md major check** (Stage C) aborts if seed and
   package.json `dependencies.next` major drift.

## Why Single Archetype (Not 3 Like Python)

Python ships `fastapi`, `library`, `data-science` archetypes — each with
a different `pyproject.toml`, `.importlinter` contract, and `src/` skeleton.

TypeScript's situation is closer to Spring than to Python:

- The Next.js + Tailwind v4 + ESLint flat config + FSD + Jest +
  Husky stack is a single composable bundle. A "node-cli" or "library"
  archetype would share most of the same toolchain (TypeScript, ESLint,
  Jest, Prettier) but drop Next/Tailwind. Bundling them as toggles
  rather than full archetypes saves duplication.
- The architecture rules in `eslint.config.mjs` + `.dependency-cruiser.cjs`
  target Next.js + FSD layered web. Library projects without `widgets/`
  or `app/` would need a parallel rule set.
- User demand for archetype splits is unmeasured.

We chose to ship a single `next` archetype for v1 (Phase 13c). The
`--archetype node-cli` and `--archetype library` flags are **reserved**
in scaffold.sh's Stage B (exit 1 with explicit "reserved but not yet
implemented" message). The directory layout `examples/archetype-next/`
+ reserved `examples/{config,scripts}/` slots is future-proof for a
Phase 14c iteration if user demand surfaces.

## `--src-dir` Adoption — Next 16 + tsconfig Alias `@/*` → `./src/*`

`npx create-next-app@16` defaults to `src/app/` when `--src-dir` is passed
(without it: root `app/` directly). Phase 13c chose `--src-dir`:

- The FSD layer convention places business code under `src/{shared,entities,features,widgets}/`.
  Putting `app/` at root and FSD layers under `src/` would make the import
  alias confusing: `@/*` would resolve to a different prefix depending on
  whether the import targets routing (`app/`) or business code (`src/`).
- With `--src-dir`, both `app/` and FSD layers live under `src/`, and
  `tsconfig.json paths "@/*": ["./src/*"]` resolves uniformly.
- One tradeoff: Next 16's root `app/layout.tsx` (without --src-dir) ships
  with built-in metadata. With `--src-dir`, `src/app/layout.tsx` has
  metadata that we override with `{{PROJECT_NAME}}`. Stage D substitutes
  the placeholder and asserts the file exists; the cost is one
  precondition check, not a new code path.

## npm Scope (`@org/<name>`) — Optional Package Name

`--package-name` is optional (defaults to `--project-name` plain-form,
e.g., `acme-portal`). Users who publish to a private registry can pass
`--package-name @acme/portal` and scaffold.sh substitutes the
package.json `name` field accordingly.

The grammar `^(@[a-z0-9-]+/)?[a-z0-9][a-z0-9-]*$` allows both forms.
Phase 13c does not auto-detect the user's organization (out of scope —
would require a second prompt). Setting it after the fact is a one-line
edit to package.json + a re-publish step.

## lockfileVersion v3 vs v4 — Accepted Forward-Compatibility

The seed package-lock.json is generated with `npm 10.8.2`, which writes
`lockfileVersion: 3`. Going forward, npm 11+ may default to v4 with
new fields (e.g., per-platform native dependency resolution).

Today's choice:

- v3 is npm 7+ compatible (engines.node `>=20.9` ⇒ npm 10+ guaranteed).
- A derived repo running npm 11+ does not auto-rewrite the lockfile;
  the user-side `npm install` regenerates lockfileVersion when transitive
  deps change. v4 then enters the lockfile naturally.
- validate.sh V21 only asserts `lockfileVersion >= 3` (npm 7+ baseline);
  v4 will pass the guard automatically.

If npm 11+ introduces breaking lockfile semantics (e.g., per-platform
metadata), the freshness ratchet (V24 90/180 day) plus weekly
scaffold-e2e CI will surface the regression before users hit it. We do
not pre-emptively migrate the seed to v4.

## Partial Stage A Failure — Accepted "Re-Clone" Recovery

scaffold.sh runs `set -euo pipefail`. If Stage A fails mid-way (e.g.,
`rm` denied, network glitch on a network filesystem), the derived repo
has a partial state: some template-only files removed, others remaining.

We do **not** ship a Stage A rollback because:

1. Rollback would require taking a git snapshot before Stage A
   (`git stash` or temp branch), which doubles the I/O cost for the
   common case where Stage A succeeds.
2. The recovery path is well-defined: `cd .. && rm -rf my-app && git clone ...`
   — a 30-second user action.
3. Stage A failures are rare (file removal under a freshly-cloned tree
   is not a permission-prone operation).

SETUP.md Troubleshooting documents the re-clone recovery; Codex sandbox
empirically follows this path automatically.

## ALLOWLIST Coordination — Why `--src-dir` Specific Entries

The validate.sh `PLACEHOLDER_ALLOWLIST` array marks files that
intentionally contain `{{...}}` placeholders. With `--src-dir` adopted
(D-19), the layout.tsx placeholder lives at `src/app/layout.tsx`, not
root `app/layout.tsx`. ALLOWLIST entries reflect the actual paths.

The grammar `\{\{[A-Z_]+\}\}` (D-23) is the only legal placeholder shape;
soft variants like `{{project-name}}` or `<<NAME>>` are forbidden. This
keeps the V22 grep deterministic and authoring rules single-source.
