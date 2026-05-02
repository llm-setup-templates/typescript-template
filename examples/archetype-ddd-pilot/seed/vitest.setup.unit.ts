import '@testing-library/jest-dom/vitest';
import { afterAll, afterEach, beforeAll } from 'vitest';
import { setupServer } from 'msw/node';
// eslint-disable-next-line fsd-lint/no-relative-imports -- root-level setup file (no FSD slice context)
import { handlers } from './__tests__/_msw/handlers';

export const server = setupServer(...handlers);
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
