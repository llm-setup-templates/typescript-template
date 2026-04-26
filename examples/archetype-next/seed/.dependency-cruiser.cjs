/** @type {import('dependency-cruiser').IConfiguration} */
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
      comment: 'Features must not import from other features',
      severity: 'error',
      from: { path: '^src/features/([^/]+)/' },
      to: { path: '^src/features/([^/]+)/', pathNot: '^src/features/$1/' },
    },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsPreCompilationDeps: true,
  },
};
