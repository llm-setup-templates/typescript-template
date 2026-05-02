import { describe, it, expect, beforeEach } from 'vitest';
import { cleanup, render, screen } from '@testing-library/react';

// Browser mode runs all tests in a single page (CX2-9). Auto-cleanup is not wired
// in @testing-library/react browser context, so we cleanup manually between tests.
beforeEach(() => cleanup());
import { OrderListWidget } from '@/widgets/order-list';
import type { OrderDto } from '@/entities/order';

const sample: OrderDto[] = [
  {
    id: 'order_1',
    items: [
      { productId: 'p1', quantity: 2, price: { amount: 100, currency: 'KRW' } },
    ],
    status: 'CREATED',
    total: { amount: 200, currency: 'KRW' },
    createdAt: '2026-05-02T00:00:00.000Z',
  },
];

describe('OrderListWidget', () => {
  it('renders empty state when no orders', () => {
    render(<OrderListWidget orderDtos={[]} />);
    expect(screen.getByText(/no orders yet/i)).toBeInTheDocument();
  });

  it('renders an order row with status badge', () => {
    render(<OrderListWidget orderDtos={sample} />);
    expect(screen.getByText('order_1')).toBeInTheDocument();
    expect(screen.getByText('CREATED')).toBeInTheDocument();
  });

  it('reconstructs Order from DTO and shows total', () => {
    render(<OrderListWidget orderDtos={sample} />);
    expect(screen.getByText(/200 KRW/)).toBeInTheDocument();
  });
});
