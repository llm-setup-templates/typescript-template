---
name: claude-md-reviewer
description: >
  Reviews, creates, and optimizes CLAUDE.md and .claude/ folder structures
  against Anthropic's official best practices. Produces a scored report
  with concrete improvement suggestions.
user_invocable: true
---

# CLAUDE.md Reviewer

Invoked when the user runs `/claude-md-reviewer` or
`/claude-md-reviewer [mode]`.

**Usage:**
- `/claude-md-reviewer` — auto-detect the current project's CLAUDE.md and review
- `/claude-md-reviewer review` — Mode A (review)
- `/claude-md-reviewer create` — Mode B (create)
- `/claude-md-reviewer structure` — Mode C (structure optimization)

---

## Execution Procedure

### Step 1: Mode Detection

If no argument is provided, check whether `.claude/` folder and CLAUDE.md exist:
- CLAUDE.md exists → Mode A (review)
- CLAUDE.md missing → Mode B (create)
- `.claude/rules/` has 5+ files → also run Mode C in parallel

### Step 2: Target File Collection

Scan all of the following paths and collect the list of existing files:

```
./CLAUDE.md
./.claude/CLAUDE.md
./CLAUDE.local.md
./.claude/rules/**/*.md
./.claude/skills/**/SKILL.md
./.claude/settings.json
./.claude/settings.local.json
*/CLAUDE.md              (subdirectories)
```

### Step 3: Execute Mode → Step 4: Output Results

---

## Mode A: Review

Score the collected CLAUDE.md against the following **7 criteria**.

### Scoring Criteria

**1. Length (Length)**
- ✅ 200 lines or fewer
- ⚠️ 200–300 lines (separation recommended)
- ❌ Over 300 lines (separation mandatory)
- Rationale: "Files over 200 lines consume more context and may reduce adherence"

**2. Specificity (Specificity)**
- Is each rule specific enough for the AI to self-verify?
- ❌ "Write clean code"
- ✅ "Functions must be ≤ 30 lines with ≤ 3 parameters"
- Test: "Can Claude automatically verify whether this rule was followed?"

**3. Verification Loop (Verification Loop)**
- Are build, test, and lint commands included?
- Is there a self-verification instruction like "after any code change, always run X"?

**4. Modularization (Modularization)**
- Is there a large single-file CLAUDE.md that should be split? → suggest `.claude/rules/`
- Is `@path` import syntax being used?
- Does the scale warrant per-subdirectory CLAUDE.md?

**5. Universality (Universality)**
- Does CLAUDE.md contain only content applicable to every task?
- Are there module-specific rules mixed in?
- Rationale: "Since CLAUDE.md goes into every single session, ensure contents are universally applicable"

**6. WHAT-WHY-HOW Completeness**
- **WHAT**: Is the tech stack and project structure described?
- **WHY**: Is the project purpose and each module's role explained?
- **HOW**: Are build / test / deploy instructions present?

**7. Domain Terms (Domain Terms)**
- Are project-specific terms defined?
- Are potentially confusing concepts clearly distinguished?

### Output Format

```markdown
# CLAUDE.md Review Results

## Summary
[One-line summary]

## Scorecard
| Criterion | Rating | Notes |
|-----------|--------|-------|
| Length | ✅/⚠️/❌ | ... |
| Specificity | ✅/⚠️/❌ | ... |
| Verification Loop | ✅/⚠️/❌ | ... |
| Modularization | ✅/⚠️/❌ | ... |
| Universality | ✅/⚠️/❌ | ... |
| WHAT-WHY-HOW | ✅/⚠️/❌ | ... |
| Domain Terms | ✅/⚠️/❌ | ... |

## Top 3 Improvements
1. [Most urgent issue + concrete fix]
2. ...
3. ...

## Revised CLAUDE.md Draft
[Full revised text or key changed sections]

## .claude/ Folder Structure Suggestion (if applicable)
[rules separation, skills organization, etc.]
```

---

## Mode B: Create

Run when no CLAUDE.md exists. Analyze the codebase and generate CLAUDE.md + rules/ files.

### Auto-Analysis Targets
1. `package.json` / `pyproject.toml` / `requirements.txt` → tech stack
2. Directory structure → architectural pattern
3. `.eslintrc` / `.prettierrc` / `tsconfig.json` → existing conventions
4. `Makefile` / `scripts/` → build/test commands
5. Presence of `.plans/` → whether to integrate project-flow skill
6. Presence of `context/` → whether context-guide rules are needed

### Interview (only when auto-analysis is insufficient)
1. **One-liner project description**: What does this project do?
2. **Domain terms**: Any project-specific vocabulary? (if yes → split into glossary.md)
3. **Hard prohibitions**: What must never happen?
4. **Team size / sharing**: Solo? Team? Shared via Git?
5. **Project planning**: Will you manage plans via `.plans/` + `context/`? (Y → include context-guide.md + project-flow.md and follow up with `/pf init`)
6. **Expected rule volume**: Do you expect many code-style, git, or architecture rules? (Y → split into rules/)

### Generation Strategy: Scale Assessment → Branch

**Decision criteria:**
- Auto-analysis + interview result predicts > 200 lines total → **split mode**
- 200 lines or fewer predicted → **single mode**
- Interview Q5 answered Y → **also include planning rules**

#### Single Mode: Generate 1 CLAUDE.md (≤ 200 lines)

```markdown
# Project Overview
[1–2 sentence description]

# Tech Stack
- Backend: [tech]
- Frontend: [tech]
- DB: [tech]

# Primary Commands
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

# Architecture Overview
[Brief directory structure and responsibilities]

# Coding Conventions
- [Specific, verifiable rules]

# Verification Rules
- After any code change, always run `[build command] && [test command]`
- On error, attempt auto-fix

# Domain Terms
- [Definitions of confusable terms]
```

#### Split Mode: Generate CLAUDE.md (core only) + rules/ files

CLAUDE.md stays slim (~50 lines):
```markdown
# Project Overview
[1–2 sentence description]

# Tech Stack
- Backend: [tech]
- Frontend: [tech]
- DB: [tech]

# Primary Commands
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

# Verification Rules
- After any code change, always run `[build command] && [test command]`
```

Generate rules/ files by topic:

| File | Content | When to create |
|------|---------|----------------|
| `code-style.md` | Naming rules, formatting, import ordering | Always |
| `git-workflow.md` | Branch strategy, commit convention, PR rules | When it's a Git project |
| `architecture.md` | Directory structure, import direction rules | When 3+ directory levels |
| `glossary.md` | Project domain term definitions (30–50 lines) | When interview Q2 has terms |
| `context-guide.md` | "For this task, reference this file" auto-lookup directives | When interview Q5 = Y or context/ exists |
| `project-flow.md` | .plans/ structure + workflow summary | When interview Q5 = Y or .plans/ exists |

Each rules/ file must be under 500 tokens.

### Follow-Up Guidance (output after generation completes)

After summarizing the generated result, always output:

```
---
## Next Steps

### Review
To review the generated CLAUDE.md and rules/:
  `/claude-md-reviewer review`

### Project Planning (optional)
To manage plans and context systematically via .plans/ + context/:
  `/pf init`  (project-flow skill)
  → PRD.md (requirement hierarchy), IA.md (information architecture), STATE.md
  → context/decisions/, context/references/, context/entity-schema.md
  → rules/context-guide.md, rules/project-flow.md auto-generated
---
```

---

## Mode C: Structure Optimization

Analyze the full `.claude/` folder + `.plans/` + `context/` and suggest the optimal structure.

### Analysis Items

**Existing (.claude/ scope):**
- CLAUDE.md line count + rules/ file count → determine if splitting is needed
- Whether rules/ files use frontmatter → check globs conditional-loading utilization
- Presence of skills/ → assess workflow reuse potential
- Review settings.json → check appropriateness of permissions/environment config
- Subdirectory CLAUDE.md → monorepo / multi-module support

**Planning scope (.plans/ + context/):**
- Presence of `.plans/` → check project-flow skill integration status
  - PRD.md present? Verify R→F→S hierarchy
  - IA.md present? Verify page↔Spec mapping
  - STATE.md present? Check last-updated date
  - Verify `{N}-{feature}/` folder structure (DISCUSS/PLAN/CHECKLIST/DONE)
- Presence of `context/` → check reference material management
  - `decisions/` ADR file count + latest date
  - `references/` file count
  - `entity-schema.md` presence + last modified
- `rules/context-guide.md` present? → auto-lookup rules configured?
- `rules/project-flow.md` present? → workflow rules configured?

### Recommended Structure by Scale

**Small** (single app, 1–2 people):
```
project/
├── CLAUDE.md             # ≤ 200 lines, all rules included
└── .claude/
    └── settings.json
```

**Medium** (multiple modules, team):
```
project/
├── CLAUDE.md             # Core only (tech stack, build commands, architecture)
├── CLAUDE.local.md       # Personal settings (not in Git)
├── .claude/
│   ├── settings.json
│   ├── settings.local.json
│   └── rules/
│       ├── code-style.md
│       ├── git-workflow.md
│       ├── architecture.md
│       ├── glossary.md           # Project domain terms
│       ├── context-guide.md      # "For this task, reference this file" directives
│       └── project-flow.md       # .plans/ structure + workflow rules
├── .plans/               # Planning + plan artifacts (managed by project-flow skill)
│   ├── PRD.md            #   R→F→S requirement hierarchy
│   ├── IA.md             #   Information architecture (for web apps)
│   ├── STATE.md          #   Current progress status
│   ├── 01-feature/       #   Per-feature plan folder
│   │   ├── DISCUSS.md
│   │   ├── PLAN.md
│   │   ├── CHECKLIST.md
│   │   └── DONE.md
│   └── _quick/           #   Quick fixes (when full workflow is overkill)
├── context/              # Team decisions + references (@-referenced on demand)
│   ├── entity-schema.md  #   Data model
│   ├── decisions/        #   ADR (Architecture Decision Records)
│   └── references/       #   External reference summaries
└── .github/              # Team infrastructure (for team projects)
    ├── ISSUE_TEMPLATE/task.md
    └── PULL_REQUEST_TEMPLATE.md
```

**Large / Monorepo:**
```
project/
├── CLAUDE.md             # Minimal common rules
├── CLAUDE.local.md
├── .claude/
│   ├── settings.json
│   ├── rules/
│   │   ├── general.md
│   │   ├── security.md
│   │   ├── context-guide.md
│   │   ├── project-flow.md
│   │   └── frontend/
│   │       └── react.md     (globs frontmatter)
│   └── skills/
│       └── deploy/SKILL.md
├── .plans/
│   ├── PRD.md
│   └── ...
├── context/
│   └── ...
├── packages/
│   ├── api/CLAUDE.md         # API-specific directives
│   └── web/CLAUDE.md         # Web-specific directives
```

### Structure Diagnosis Output Format

```markdown
# .claude/ Structure Diagnosis

## Current Structure
[Detected file tree]

## Diagnosis Table
| Area | Status | Suggestion |
|------|--------|------------|
| CLAUDE.md length | ✅/⚠️/❌ | ... |
| rules/ separation | ✅/⚠️/❌ | ... |
| .plans/ structure | ✅/⚠️/❌/absent | ... |
| context/ structure | ✅/⚠️/❌/absent | ... |
| context-guide.md | ✅/absent | ... |
| project-flow.md | ✅/absent | ... |

## Recommended Structure
[Structure suggestion matching the current project scale]

## Next Steps
[How to create missing files/folders]
```

---

## Reference: File Loading Order

### Auto-loaded at session start
1. `~/.claude/CLAUDE.md` (global)
2. All CLAUDE.md files in the parent directory chain
3. `./CLAUDE.md` or `./.claude/CLAUDE.md`
4. `./CLAUDE.local.md` (local only)
5. All `.md` files in `.claude/rules/` without frontmatter
6. Auto Memory (first 200 lines of MEMORY.md)

### On-demand load
- Subdirectory CLAUDE.md → when working on files in that directory
- `.claude/rules/` files with `globs` frontmatter → when the glob pattern matches the current file
- Skills → when invoked or deemed relevant

### rules/ Frontmatter (globs recommended)

Always loaded — written without frontmatter:
```markdown
# Code Style Rules
- 2-space indentation
```

Conditionally loaded — matched via globs:
```markdown
---
globs: "src/components/**/*.tsx, src/app/**/*.tsx"
---
# React Rules
- Use functional components only
```

> Use `globs:` instead of `paths:` — `paths` has bugs in some versions.

### @ Import Syntax
```markdown
Project overview: @README.md
Git rules: @docs/git-instructions.md
Personal settings: @~/.claude/my-preferences.md
```
- Supports recursive imports up to 5 levels deep

### claudeMdExcludes (for monorepos)
```json
// .claude/settings.local.json
{
  "claudeMdExcludes": ["**/monorepo/CLAUDE.md"]
}
```

---

## Reference: CLAUDE.md vs Rules vs Skills vs Hooks

| | CLAUDE.md | rules/ | skills/ | hooks |
|---|-----------|--------|---------|-------|
| Loading | Every session | At start / on glob match | On invocation | On event trigger |
| Enforcement | Contextual (can be ignored) | Contextual (can be ignored) | Contextual | **Deterministic (guaranteed)** |
| Purpose | Base directives | Domain-specific detailed rules | Reusable workflows | Automatic execution |
| Recommended size | ≤ 200 lines | ≤ 500 tokens/file | ≤ 500 lines | — |

**Decision guide:**
- "Must run every single time" → **Hooks** (lint, format, etc.)
- "Always-needed base context" → **CLAUDE.md**
- "Rules needed when working on specific files" → **rules/** (with globs)
- "Occasionally needed procedures / knowledge" → **skills/**

---

## Reference: Anti-patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| 300+ line monolith | Important rules buried in noise | Keep ≤ 200 lines; move the rest to rules/ |
| Vague instructions | "Write clean code" → unverifiable | Use specific, AI-self-verifiable criteria |
| Single-file dependency | Rules ignored as size grows | Split by topic into `.claude/rules/` |
| Hooks substitution via CLAUDE.md | Execution not guaranteed | Must-run logic = Hooks; context = CLAUDE.md |
| Auto Memory confusion | Role conflict between directives and memory | Manually written = CLAUDE.md; AI-learned = Memory |

---

## 7 Core Principles

1. **Start from an empty file** — add one line at a time as lessons are learned
2. **200-line limit** — when exceeded, split into `.claude/rules/`
3. **Specific and verifiable** — every rule must be checkable ("was this followed?")
4. **Universal content only** — module-specific rules belong in rules/ or subdirectory CLAUDE.md
5. **Verification loop required** — always include build/test commands
6. **Team shared = Git** — commit CLAUDE.md; add local.md to .gitignore
7. **Distinguish Hooks** — must-run every time = Hooks; provide context = CLAUDE.md
