import { describe, it, expect } from 'vitest';
import { canTransitionTo } from '@/entities/order';

describe('OrderStatus transitions', () => {
  it('CREATED -> PAID + CANCELLED allowed', () => {
    expect(canTransitionTo('CREATED', 'PAID')).toBe(true);
    expect(canTransitionTo('CREATED', 'CANCELLED')).toBe(true);
  });

  it('PAID -> SHIPPED + CANCELLED allowed', () => {
    expect(canTransitionTo('PAID', 'SHIPPED')).toBe(true);
    expect(canTransitionTo('PAID', 'CANCELLED')).toBe(true);
  });

  it('SHIPPED -> DELIVERED only', () => {
    expect(canTransitionTo('SHIPPED', 'DELIVERED')).toBe(true);
    expect(canTransitionTo('SHIPPED', 'CANCELLED')).toBe(false);
  });

  it('DELIVERED is terminal', () => {
    expect(canTransitionTo('DELIVERED', 'CANCELLED')).toBe(false);
    expect(canTransitionTo('DELIVERED', 'PAID')).toBe(false);
  });

  it('CANCELLED is terminal', () => {
    expect(canTransitionTo('CANCELLED', 'PAID')).toBe(false);
    expect(canTransitionTo('CANCELLED', 'DELIVERED')).toBe(false);
  });

  it('CREATED cannot skip to SHIPPED', () => {
    expect(canTransitionTo('CREATED', 'SHIPPED')).toBe(false);
  });
});
