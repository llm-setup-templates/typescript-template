import { describe, it, expect } from 'vitest';
import { cruise } from 'dependency-cruiser';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const depcruiseConfig = require('../../.dependency-cruiser.cjs');

describe('FSD-DDD architecture rules', () => {
  it('all 5 enforceable rules pass on src/', async () => {
    // dependency-cruiser programmatic API: 2nd argument = ICruiseOptions
    // Must wrap config under ruleSet + set validate: true to actually enforce.
    // https://github.com/sverweij/dependency-cruiser/blob/main/doc/api.md
    const result = await cruise(['src'], {
      validate: true,
      ruleSet: depcruiseConfig,
      tsConfig: { fileName: 'tsconfig.json' },
    });
    const out = result.output as { summary: { violations: unknown[] } };
    expect(out.summary.violations).toEqual([]);
  });
});
