<!-- Machine-parsed by scaffold.sh / refresh-next-seed.sh / validate.sh. Keep "key | value" 2-column structure; Next.js row must be exactly one. -->

# Next.js Seed Version Manifest

This file records the upstream tool versions used to generate
`examples/archetype-next/seed/`. scaffold.sh's Stage C parses the
`Next.js` row to assert the seed package.json's `dependencies.next`
is at the same major version. If a re-seed is required (Q1 archetype
expansion / RFC-001 Vitest migration / Next major bump), update
`tools/refresh-next-seed.sh`'s output and bump the rows below
together.

| Key              | Value     |
|------------------|-----------|
| Next.js          | 16.0.1    |
| create-next-app  | 16.0.1    |
| generated_on     | 2026-04-26 |
| npm              | 10.8.2    |
| node             | 20.19.0   |
| lockfileVersion  | 3         |

## Parse contract

Stage C extracts `Next.js` major (16) via:

```bash
SEED_NEXT_MAJOR=$(awk -F'|' '/^[|] Next\.js/{gsub(/[^0-9.]/,"",$3); print $3}' \
  examples/archetype-next/VERSION.md | cut -d. -f1)
PKG_NEXT_MAJOR=$(node -p "require('./examples/archetype-next/seed/package.json').dependencies.next.replace(/[^0-9.]/g,'').split('.')[0]")
```

Mismatch aborts scaffold with a re-seed required error. The awk anchor `^[|] `
guarantees the table row is matched but in-prose mentions of "Next.js" in
this file are not. validate.sh V21 additionally guards table row count == 1
to keep the parse deterministic.
