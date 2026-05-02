import axios from 'axios';

// process.env guard: Vitest browser mode evaluates this in Chromium (no `process`
// global). Next.js statically replaces `process.env.NEXT_PUBLIC_*` at build time,
// so the typeof guard short-circuits in the browser test runner only.
const baseURL =
  (typeof process !== 'undefined' && process.env.NEXT_PUBLIC_API_BASE_URL) ||
  'http://localhost:3001';

export const api = axios.create({
  baseURL,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((cfg) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('token');
    if (token) cfg.headers.Authorization = `Bearer ${token}`;
  }
  return cfg;
});

export default api;
