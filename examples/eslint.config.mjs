import { dirname } from 'path';
import { fileURLToPath } from 'url';
import { FlatCompat } from '@eslint/eslintrc';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

/** @type {import('eslint').Linter.Config[]} */
const eslintConfig = [
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  // FSD boundary rules
  // eslint-plugin-fsd-lint: if flat config is not natively supported,
  // use compat.plugins('fsd-lint') wrapper below.
  // Verify support in https://github.com/conarti/eslint-plugin-fsd before executing.
  ...compat.plugins('fsd-lint'),
  {
    rules: {
      'fsd-lint/forbidden-imports': 'error',
      'fsd-lint/no-relative-imports': 'error',
      'fsd-lint/no-public-api-sidestep': 'error',
    },
  },
  {
    rules: {
      // Components and pages must use default export
      'import/prefer-default-export': 'off',
      // Enforce default export in component files
      // (apply selectively via overrides if needed)
    },
  },
];

export default eslintConfig;
