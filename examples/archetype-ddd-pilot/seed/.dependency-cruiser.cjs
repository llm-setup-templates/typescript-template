/**
 * archetype-ddd-pilot dependency-cruiser config.
 *
 * 7 frontend FSD-DDD rule (DISCUSS Q4-Q5 LOCK):
 *   - FSD 3 enforceable: no-db-in-entities / no-db-in-features / no-cross-feature-import
 *   - FE-DDD 2 enforceable: R-FE-3-no-fetch-in-domain / R-FE-4-no-upward-from-domain
 *   - FE-DDD 2 convention-only: R-FE-1 (domain class location) / R-FE-2 (event type location)
 *
 * R-FE-1 / R-FE-2 are doc-only conventions (dep-cruiser path-only weak):
 *   - R-FE-1: client domain class is defined only in entities/{name}/model/ (code review + frontend-ddd-tdd-guide.md)
 *   - R-FE-2: domain event type export in entities/{name}/model/events/ (code review + guide.md)
 *
 * Total: 5 enforceable error rules below + 2 convention-only doc-enforced.
 * See ADR-005 + frontend-ddd-tdd-guide.md for the "FE-DDD 4 rule" framing.
 */
module.exports = {
  forbidden: [
    {
      name: 'no-db-in-entities',
      comment: 'Entity/domain code must not import DB drivers directly',
      severity: 'error',
      from: { path: '^src/entities/' },
      to: { path: ['prisma', '@prisma/client', 'drizzle-orm', 'pg', 'mysql2'] },
    },
    {
      name: 'no-db-in-features',
      comment: 'Feature code must not import DB drivers directly',
      severity: 'error',
      from: { path: '^src/features/' },
      to: { path: ['prisma', '@prisma/client', 'drizzle-orm', 'pg', 'mysql2'] },
    },
    {
      name: 'no-cross-feature-import',
      // NOTE: $1 back-reference in pathNot may not work in all dependency-cruiser
      // versions. Primary enforcement is via eslint-plugin-fsd-lint's forbidden-imports.
      // (R-09 fix: archetype-next disclaimer mirrored)
      comment:
        'Features must not import from other features (barrel-only via shared if needed)',
      severity: 'error',
      from: { path: '^src/features/([^/]+)/' },
      to: { path: '^src/features/([^/]+)/', pathNot: '^src/features/$1/' },
    },
    {
      name: 'R-FE-3-no-api-dep-in-domain',
      // R2-03/CX2-3 fix: clarified intent. dep-cruiser `forbidden.to.path` means
      // "from depends on (imports) to-path is forbidden".
      // Preserves DISCUSS Q5 LOCK body (entities/model/ -> shared/api/ + entities/{name}/api/) +
      // extends to forbid direct axios import. This way the domain model cannot reach HTTP via
      // (a) internal api wrapper, nor (b) axios directly -- guarantees domain purity.
      comment:
        'R-FE-3: Domain model (entities/{name}/model/) must not depend on api wrapper layers (shared/api, entities/{name}/api) nor on HTTP libs (axios) directly. HTTP fetch belongs in api/ adapters.',
      severity: 'error',
      from: { path: '^src/entities/[^/]+/model/' },
      to: {
        path: [
          '^src/shared/api/',
          '^src/entities/[^/]+/api/',
          '^node_modules/axios',
          '^node_modules/node-fetch',
        ],
      },
    },
    {
      name: 'R-FE-4-no-upward-from-domain',
      comment:
        'R-FE-4: Domain model must not depend on application/UI layers (features, widgets, app).',
      severity: 'error',
      from: { path: '^src/entities/[^/]+/model/' },
      to: { path: ['^src/features/', '^src/widgets/', '^src/app/'] },
    },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: 'tsconfig.json' },
  },
};
