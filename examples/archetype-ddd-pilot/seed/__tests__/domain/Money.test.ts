import { describe, it, expect } from 'vitest';
import { Money } from '@/entities/order';

describe('Money', () => {
  it('builds via Money.from', () => {
    const m = Money.from({ amount: 100, currency: 'KRW' });
    expect(m.amount).toBe(100);
    expect(m.currency).toBe('KRW');
  });

  it('Money.zero builds zero of given currency', () => {
    const z = Money.zero('USD');
    expect(z.amount).toBe(0);
    expect(z.currency).toBe('USD');
  });

  it('add sums same-currency amounts', () => {
    const a = Money.from({ amount: 100, currency: 'KRW' });
    const b = Money.from({ amount: 50, currency: 'KRW' });
    expect(a.add(b).amount).toBe(150);
  });

  it('add throws on currency mismatch', () => {
    const a = Money.from({ amount: 100, currency: 'KRW' });
    const b = Money.from({ amount: 50, currency: 'USD' });
    expect(() => a.add(b)).toThrow(/Currency mismatch/);
  });

  it('multiply scales amount', () => {
    const m = Money.from({ amount: 100, currency: 'KRW' });
    expect(m.multiply(3).amount).toBe(300);
  });

  it('rejects negative amount', () => {
    expect(() => Money.from({ amount: -1, currency: 'KRW' })).toThrow();
  });
});
