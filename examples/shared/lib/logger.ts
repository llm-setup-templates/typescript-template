/**
 * (Optional) Structured logger — for Docker/EC2 production deployments.
 * Vercel deployments: console.* is auto-collected, this module is not required.
 */
type LogLevel = 'debug' | 'info' | 'warn' | 'error';

function createLogger(name: string) {
  const isProduction = process.env.NODE_ENV === 'production';
  const log = (level: LogLevel, msg: string, meta?: Record<string, unknown>) => {
    const entry = isProduction
      ? JSON.stringify({ ts: new Date().toISOString(), level, name, msg, ...meta })
      : `[${level.toUpperCase()}] ${name}: ${msg}`;
    const fn = level === 'error' ? console.error : level === 'warn' ? console.warn : console.log;
    fn(entry);
  };
  return {
    debug: (msg: string, meta?: Record<string, unknown>) => log('debug', msg, meta),
    info: (msg: string, meta?: Record<string, unknown>) => log('info', msg, meta),
    warn: (msg: string, meta?: Record<string, unknown>) => log('warn', msg, meta),
    error: (msg: string, meta?: Record<string, unknown>) => log('error', msg, meta),
  };
}

export { createLogger };
