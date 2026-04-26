# ADR-002: Clone + Script Scaffolding over `gh --template` (TypeScript)

Status: Accepted (2026-04-26)
Supersedes: Implicit Phase 0/0.5/1 flow in SETUP.md (pre-Phase-13c, removed)
Related: ADR-001 (Jest coverage threshold — unchanged)

## Status

Accepted. Phase 13c PR introduces `scaffold.sh`, `examples/archetype-next/seed/`,
`tools/refresh-next-seed.sh`, `test/scaffold-e2e.sh`, and rewires SETUP.md.
This ADR is append-only after merge per `docs/architecture/decisions/README.md`.

## Context

Through Phase 11/12, `SETUP.md` ran a 14-phase flow: clone reference repo,
fetch `npx create-next-app` output, apply template overlays, run validate.sh,
push to GitHub. Five distinct external calls, the earliest at the very first
step.

This was the same blocker the Python template (Phase 13) and Spring template
(Phase 13b) solved. The trigger was Codex's e2e23 dry run — the agent spent
2m 26s attempting `gh.exe` invocations from inside its Linux sandbox before
hitting quoting + IO encoding failures and **never reaching Phase 1**.

For TypeScript there is an additional twist: Phase 1 itself depended on
`npx create-next-app@<version>` — a network call to npm's registry. This
adds a second external dependency (npm registry availability) beyond `gh`,
breaking even environments that have `gh` but no outbound HTTPS to
`registry.npmjs.org` (corporate proxies, air-gapped CI).

The preceding Phase 11/12 hardenings tightened individual steps but kept
the coupling between "obtain template files" + "fetch create-next-app
output" + "connect to GitHub" intact.

## Decision

Separate "obtain template files" from "fetch create-next-app output"
from "connect to GitHub":

1. **Template acquisition**: `git clone https://github.com/llm-setup-templates/typescript-template`.
   Requires only `git` (already present in every environment that can
   edit files, including Codex's sandbox).
2. **Next.js seed**: pre-baked at `examples/archetype-next/seed/` inside
   the template repo. Snapshot of `npx create-next-app@16.0.1 --src-dir
   --tailwind --eslint --app --typescript --import-alias '@/*'` output.
   Refreshed via `tools/refresh-next-seed.sh` + the weekly
   `scaffold-e2e.yml` cron. Derived repos do not call npm registry.
3. **Customization**: `bash ./scaffold.sh --project-name <hyphen-case>
   [--package-name <name-or-@scope/name>] --archetype next [--doc-modules core]`.
   Requires only `bash` ≥ 4.0. No network calls, no `gh`, no `npx`.
   8-stage pipeline (Stage A-H, Spring 13b parity labels with TypeScript
   subtitles).
4. **GitHub connection (optional)**: `gh repo create` + `git push`.
   Documented in SETUP.md § "Publish to GitHub". Users who publish to
   GitLab, self-hosted Gitea, or keep the repo local skip this section.

scaffold.sh is single-use (detects `validate.sh` presence as freshness
marker) and self-deletes on success (Linux/macOS; Windows Git Bash prints
a warning and asks for manual deletion due to file locks on the running
script).

## Reserved Archetypes

`--archetype` accepts `next` (implemented) and reserves `node-cli` and
`library` (Stage B exits 1 with explicit "reserved but not yet
implemented" stderr). The directory layout reserves
`examples/archetype-next/{config,scripts}/` slots and the parallel
`examples/archetype-node-cli/` + `examples/archetype-library/` siblings
are added by a future Phase 14c when user demand surfaces.

Promotion contract: when a reserved archetype is implemented, the error
message is replaced with the implementation. This is a behavior change
visible to scripts that grep stderr; downstream consumers should treat
the reservation as **non-stable until implemented** and a CHANGELOG
entry is mandatory.

## 3-Tier Verification

scaffold.sh's behavior is testable across three tiers:

- **Tier 1 — `bash validate.sh`** (fast, every PR). V1-V19 (existing) +
  V20-V28 (Phase 13c additions). Static checks: file presence, ASCII-only
  scanner, placeholder allowlist, lockfileVersion, seed staleness, Bash
  guard, Stage B error path coverage.
- **Tier 2 — `bash test/scaffold-e2e.sh`** (every PR, wired into
  `validate.yml`). 6-cell matrix: 5 doc-module combinations + 1 invalid
  archetype error path. Each cell does temp dir → `cp -a` → `bash
  scaffold.sh` → `npm ci` → `npm run verify`. Per-cell npm cache
  isolation. Husky activation smoke test in Cell 1.
- **Tier 3 — Codex e2e27 no-intervention** (release-gate, opt-in). Codex
  sandbox runs `git clone ... && bash ./scaffold.sh ... && git push` to
  a pre-created `KWONSEOK02/llm-setup-e2e27-typescript` repo. Triggered
  manually before phase merge / release tag.

### Tier 3 Invocation

Tier 3 is **opt-in only**. No CI workflow invokes Codex automatically.
Trigger surfaces:

- `workflow_dispatch` event on `scaffold-e2e.yml` (manual).
- Phase merge gate: orchestrator runs the e2e27 invocation manually
  before approving a Phase 13c-style merge.
- Release tag: future `release.yml` may add Codex e2e to the release
  checklist.

### Tier 3 Network Fallback

When Codex sandbox port 443 is blocked (Phase 13b empirical), the
sandbox is escalated to `danger-full-access` per
`.plans/llm-setup/CLAUDE.md` policy. There is **no automatic
fallback** if `danger-full-access` itself is unavailable; the operator
must escalate manually or skip Tier 3 with a noted exception in the
PR description.

## Abandonment Cost

(Wiki rubric `Guide/Abandonment-Cost-Scoring-Rubric.md` first-application
case.) Ten Locked Decisions (LD-01 through LD-10) and fifteen secondary
decisions (D-11 through D-25) are jointly scored 1-10 across 17 design
questions. Threshold `5+` triggers a compromise; 13 compromises (C1-C13)
are documented in PLAN.md `## Compromise Design Table`. Each compromise
carries a Plan-impact mapping to one or more Tasks. Re-evaluation is
warranted when:

- A Locked Decision is contradicted by a downstream phase decision.
- A compromise's underlying constraint changes (e.g., Codex sandbox
  defaults relax → C13 simplifies).
- A new design question surfaces that overlaps with an existing one
  (e.g., archetype expansion in Phase 14c overlaps with Q1).

## Accepted Limitations

- **PowerShell silent-no-op**: scaffold.sh under PowerShell `.\scaffold.sh`
  invocation exits 0 without scaffolding side effects. Documented in
  RATIONALE.md and SETUP.md Troubleshooting. The two alternatives (ship
  parallel `.ps1`, require Bash invocation) have very different cost
  profiles; we chose the latter.
- **Single-use constraint**: re-running scaffold.sh errors out with
  "validate.sh not found — this doesn't look like a freshly-cloned
  template". Intentional (idempotent sed substitutions are fragile);
  users re-clone instead of retry.
- **Windows self-delete**: scaffold.sh can't delete itself on Windows
  Git Bash (file lock). The script warns and asks for manual cleanup.
- **Next.js version staleness**: the baked seed is a snapshot of one
  specific Next major (16.0.1 at template v1.x). Staleness ratchet via
  V24 (90 warn / 180 fail) + weekly scaffold-e2e cron + `tools/refresh-next-seed.sh`
  for maintainer regeneration.
- **Partial Stage A failure**: no rollback. Recovery is `cd .. && rm -rf
  my-app && git clone ...`. Documented in SETUP.md Troubleshooting.
- **lockfileVersion v3 vs v4**: the seed is `lockfileVersion: 3` (npm 10
  default). When a derived repo upgrades to npm 11+ and `npm install`
  rewrites the lockfile, v4 is accepted automatically. validate.sh V21
  asserts `>= 3` (forward-compatible).
- **Husky `_/` runtime helper**: scaffold.sh copies hook files but does
  NOT pre-create `.husky/_/`. The first `npm install` runs `husky` (via
  the `prepare` script) which creates `_/` automatically. Documented in
  SETUP.md Troubleshooting.
- **Phase 0.5 `/tmp/ref-typescript` concept deleted**: pre-Phase-13c
  SETUP.md used a reference clone to copy template files. In the
  clone+script architecture, the cloned directory IS the reference — no
  separate copy needed.

## Alternatives considered

### A. `gh repo create --template llm-setup-templates/typescript-template` (rejected)

Server-side templating via GitHub API. Clone-less, but:

- Still requires `gh` at step 1 → does not solve the Codex sandbox blocker.
- Still requires a separate `npx create-next-app` call → does not solve
  the npm-registry offline blocker.
- Auto-creates an "Initial commit" message that violates the Conventional
  Commits gate.
- No access to substitute placeholders before first commit (user must
  rewrite history, which breaks the "one clean initial commit" contract).

### B. scaffold.sh + `npx create-next-app@<latest>` at scaffold time (rejected)

Always fetch the latest Next.js seed at scaffold time. Pros: no version
staleness, smaller repo (no baked seed). Cons that overwhelm:

- Adds a network dependency on `registry.npmjs.org` to scaffold.sh — a
  violation of ADR-002's "single-dependency scaffolding" principle
  (`bash` + `git` only).
- Codex sandbox + air-gapped CI runners + GitLab mirrors with no
  registry egress: scaffold.sh fails. Same class of blocker as `gh`,
  just shifted one layer.
- Network failure mid-scaffold leaves a partial state — harder to
  recover than a baked seed which is deterministic.
- `create-next-app` API surface changes (new flags, deprecated
  templates) silently break future scaffold runs without any change to
  the template repo.

### C. degit (tarball download) (rejected)

`npx degit user/repo target-dir` downloads the template tarball without
`.git`. Clean, no git reinit step needed. But:

- Adds `npm` (Node.js) as a prerequisite at the very first step —
  inconsistent with Spring/Python parity (which require only `git` +
  `bash`).
- Still requires a separate `create-next-app` fetch.
- Loses the ability to `git pull` future template updates into the
  derived repo (users who want that have to re-clone anyway, so this
  is a shallow benefit — but the added dependency is not).

### D. Keep current 14-phase flow + add 7th Fix (rejected)

The "add yet another troubleshooting row" path. Rejected because the
underlying coupling (file acquisition ⊗ create-next-app ⊗ GitHub
connection) is the root cause; troubleshooting entries only paper over
symptoms. Phase 11/12 hardenings already accumulated environment-specific
workarounds (Husky activation timing, CRLF line endings, CI no-run
recovery, validate.yml template-only confusion). Adding a 7th doesn't
stop the 8th.

## Consequences

### Positive

- **Single-dependency scaffolding**: `git` + `bash` is enough. Any
  environment that can `git clone` over HTTPS can scaffold, including
  Codex sandboxes, air-gapped CI runners with git proxies, or
  GitLab/Gitea mirrors.
- **Executable documentation**: scaffold.sh IS the scaffolding logic.
  SETUP.md shrinks from 980 lines to ~200 lines and documents
  "why / when / how to call" rather than "paste these 40 bash commands
  in order".
- **CI regression coverage**: scaffold.sh's behavior is now testable in
  `.github/workflows/validate.yml` via `test/scaffold-e2e.sh` (6-cell
  matrix). Bugs in scaffolding are caught before they reach users.
- **Decoupled gh + create-next-app**: publishing to GitHub is optional,
  and registry availability is irrelevant at scaffold time.
- **Husky exec bit baked in**: the seed `.husky/` hook files are
  committed with `git update-index --chmod=+x` once, so derived repos
  inherit `100755` mode regardless of the user's filesystem semantics.

### Negative

- **scaffold.sh is a new, load-bearing file**: bugs here break all users.
  Mitigated by scaffold-e2e CI matrix + `--dry-run` flag + single-use
  freshness check + Bash interpreter guard + Tier 3 Codex e2e.
- **Single-use surprises users**: re-running errors with "validate.sh
  not found". Intentional but the error message must be clear.
- **Windows self-delete caveat**: scaffold.sh can't delete itself on
  Windows Git Bash. We warn and ask for manual cleanup.
- **Next.js seed staleness**: when Next major rolls forward (17/18),
  derived repos using the baked seed will lag. Mitigated by the
  freshness ratchet + weekly cron + tools/refresh-next-seed.sh.
- **Reserved archetype API stability**: `--archetype node-cli|library`
  exit messages may be replaced by real implementations later. Marked
  as non-stable until implemented; CHANGELOG entry is mandatory at
  promotion.

## Implementation trail

- Plan: `.plans/llm-setup/13c-typescript-clone-script-architecture/PLAN.md` (rev.4)
- Discussion: `.plans/llm-setup/13c-typescript-clone-script-architecture/DISCUSS.md`
- Plan-review-deep --with-codex (3 rounds, Critical 0 convergence):
  Round 1 Reality+Contract / Codex Runtime Contract+Completeness,
  Round 2 Runtime Contract / Codex Reality,
  Round 3 Completeness / Codex Contract.
- Wiki rubric (Guide/Abandonment-Cost-Scoring-Rubric.md) first-application
  case: 30+ rejected options scored, 13 compromises 1:1 mapped.
- Phase lineage: ADR-002 (Phase 13 Python) + ADR-002 (Phase 13b Spring,
  PR #16) → ADR-002 (Phase 13c TypeScript, this document).
- Direct driver: same as Phase 13/13b (Codex sandbox blocker), plus
  TypeScript-specific create-next-app offline requirement.
