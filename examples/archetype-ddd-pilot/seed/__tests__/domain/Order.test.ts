import { describe, it, expect } from 'vitest';
import {
  Order,
  OrderItem,
  Money,
  InvariantViolationError,
  InvalidStatusTransitionError,
} from '@/entities/order';

// Domain layer no-mocking pattern: tests verify behavior through the public
// API of the aggregate (entities/order/model/Order). Mocks are forbidden in
// this layer. See Spring template's docs/patterns/ddd-tdd-cross-stack.md
// "Domain layer no-mocking" section (cross-stack alignment).

describe('Order', () => {
  const item = OrderItem.create(
    'p1',
    2,
    Money.from({ amount: 100, currency: 'KRW' })
  );

  it('creates with CREATED status + computes total', () => {
    const o = Order.create([item]);
    expect(o.status).toBe('CREATED');
    expect(o.total.amount).toBe(200);
    expect(o.total.currency).toBe('KRW');
  });

  it('cancels from CREATED', () => {
    const o = Order.create([item]);
    o.cancel();
    expect(o.status).toBe('CANCELLED');
  });

  it('rejects empty items via InvariantViolationError', () => {
    expect(() => Order.create([])).toThrow(InvariantViolationError);
  });

  it('rejects cancel from DELIVERED via InvalidStatusTransitionError', () => {
    const o = Order.create([item]);
    o.pay('ref');
    o.markShipped();
    o.markDelivered();
    expect(() => o.cancel()).toThrow(InvalidStatusTransitionError);
  });

  it('preserves total through pay/ship/deliver transitions', () => {
    const o = Order.create([item]);
    const before = o.total.amount;
    o.pay('ref');
    o.markShipped();
    o.markDelivered();
    expect(o.total.amount).toBe(before);
  });

  it('rejects items with mixed currencies', () => {
    const krw = OrderItem.create(
      'a',
      1,
      Money.from({ amount: 100, currency: 'KRW' })
    );
    const usd = OrderItem.create(
      'b',
      1,
      Money.from({ amount: 100, currency: 'USD' })
    );
    expect(() => Order.create([krw, usd])).toThrow(InvariantViolationError);
  });
});
