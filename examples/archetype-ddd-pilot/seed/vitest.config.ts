import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { playwright } from '@vitest/browser-playwright';
import path from 'node:path';

// IMPORTANT (R2-06/CX2-7): Do NOT add root-level test.setupFiles or test.environment here.
// Each project below specifies its own setupFile -- root inheritance would re-pollute the
// browser project with msw/node imports. If you need a shared setup, use plugins or
// resolve config (which DO inherit safely via extends:true).
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  test: {
    projects: [
      {
        extends: true,
        test: {
          name: 'unit',
          environment: 'jsdom',
          setupFiles: ['./vitest.setup.unit.ts'],
          include: ['__tests__/domain/**/*.test.ts', '__tests__/feature/**/*.test.tsx', '__tests__/architecture/**/*.test.ts'],
        },
      },
      {
        extends: true,
        test: {
          name: 'browser',
          setupFiles: ['./vitest.setup.browser.ts'],
          include: ['__tests__/widget/**/*.test.tsx'],
          browser: {
            enabled: true,
            provider: playwright(),
            instances: [{ browser: 'chromium' }],
            headless: true,
          },
        },
      },
    ],
  },
});
