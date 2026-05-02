import { describe, it, expect } from 'vitest';
import { Money, OrderItem } from '@/entities/order';

describe('OrderItem', () => {
  it('OrderItem.create builds with positive quantity', () => {
    const price = Money.from({ amount: 100, currency: 'KRW' });
    const item = OrderItem.create('p1', 2, price);
    expect(item.productId).toBe('p1');
    expect(item.quantity).toBe(2);
  });

  it('rejects non-positive quantity', () => {
    const price = Money.from({ amount: 100, currency: 'KRW' });
    expect(() => OrderItem.create('p1', 0, price)).toThrow();
  });

  it('total = quantity * price', () => {
    const price = Money.from({ amount: 100, currency: 'KRW' });
    const item = OrderItem.create('p1', 3, price);
    expect(item.total().amount).toBe(300);
  });

  it('fromDto reconstructs an OrderItem', () => {
    const item = OrderItem.fromDto({
      productId: 'p2',
      quantity: 4,
      price: { amount: 50, currency: 'USD' },
    });
    expect(item.total().amount).toBe(200);
    expect(item.total().currency).toBe('USD');
  });
});
