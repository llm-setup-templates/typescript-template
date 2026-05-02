import { FlatCompat } from '@eslint/eslintrc';
import fsdLint from 'eslint-plugin-fsd-lint';

const compat = new FlatCompat({ baseDirectory: import.meta.dirname });

export default [
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  {
    plugins: { 'fsd-lint': fsdLint },
    rules: {
      'fsd-lint/forbidden-imports': [
        'error',
        {
          layers: ['app', 'widgets', 'features', 'entities', 'shared'],
        },
      ],
      'fsd-lint/no-relative-imports': 'error',
      'fsd-lint/no-public-api-sidestep': 'error',
    },
  },
];
