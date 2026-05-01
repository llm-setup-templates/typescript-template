<!-- Machine-parsed by scaffold.sh / validate.sh. Keep "key | value" 2-column structure; Next.js row must be exactly one. -->

# archetype-ddd-pilot Seed Version Manifest

This file records the upstream tool versions used to generate
`examples/archetype-ddd-pilot/seed/`. scaffold.sh's Stage C parses the
`Next.js` row to assert the seed package.json's `dependencies.next`
is at the same major version. If a re-seed is required (Next major
bump / Vitest major bump), bump this file and the seed package.json
together.

| Key              | Value     |
|------------------|-----------|
| Next.js          | 16.0.1    |
| React            | 19.2.0    |
| Vitest           | 4.0.18    |
| TypeScript       | 5.6.3     |
| generated_on     | 2026-05-02 |
| npm              | 10.8.2    |
| node             | 20.19.0   |
| lockfileVersion  | 3         |

## Parse contract

Stage C extracts `Next.js` major (16) via:

```bash
SEED_NEXT_MAJOR=$(awk -F'|' '/^[|] Next\.js/{gsub(/[^0-9.]/,"",$3); print $3}' \
  examples/archetype-ddd-pilot/VERSION.md | cut -d. -f1)
PKG_NEXT_MAJOR=$(node -p "require('./examples/archetype-ddd-pilot/seed/package.json').dependencies.next.replace(/[^0-9.]/g,'').split('.')[0]")
```

Mismatch aborts scaffold with a re-seed required error. Same grammar as
archetype-next/VERSION.md; archetype 인자에 따라 path 분기. The awk
anchor `^[|] ` guarantees the table row is matched but in-prose mentions
of "Next.js" in this file are not. validate.sh V21-bis additionally
guards table row count == 1 via `check_seed_completeness ddd-pilot`.

## Why Vitest 4 (vs jest in archetype-next)?

archetype-ddd-pilot은 Mind Signal frontend production pattern 정합 + Classicist + Testcontainers 정신 정합 위해 Vitest browser mode (Playwright Chromium provider) 채택. archetype-next는 create-next-app default jest 보존 (production starter baseline). 두 archetype seed/package.json은 각각 자체 test runner deps 보유.
