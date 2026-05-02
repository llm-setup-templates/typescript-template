import { describe, it, expect } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { OrderProvider } from '@/app/providers/order.context';
import { usePayOrder } from '@/features/pay-order';
import { useOrder } from '@/shared/state/order-context.client';
import { InvalidStatusTransitionError } from '@/entities/order';
import { server } from '../../vitest.setup.unit';

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <OrderProvider>{children}</OrderProvider>
);

const seedRequest = () => ({
  items: [
    {
      productId: 'p1',
      quantity: 1,
      price: { amount: 100, currency: 'KRW' as const },
    },
  ],
});

describe('usePayOrder', () => {
  it('happy path: PAID committed', async () => {
    const { result } = renderHook(
      () => ({ pay: usePayOrder(), ctx: useOrder() }),
      { wrapper }
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    await act(async () => {
      await result.current.pay.pay(id, 'ref_test');
    });
    await waitFor(() =>
      expect(result.current.ctx.orders[0].status).toBe('PAID')
    );
  });

  it('invariant: pay from CANCELLED throws InvalidStatusTransitionError', async () => {
    server.use(
      http.post('http://localhost:3001/orders', () =>
        HttpResponse.json(
          {
            id: 'order_cancelled',
            items: [
              {
                productId: 'p1',
                quantity: 1,
                price: { amount: 100, currency: 'KRW' },
              },
            ],
            status: 'CANCELLED',
            total: { amount: 100, currency: 'KRW' },
            createdAt: '2026-05-02T00:00:00.000Z',
          },
          { status: 201 }
        )
      )
    );
    const { result } = renderHook(
      () => ({ pay: usePayOrder(), ctx: useOrder() }),
      { wrapper }
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    await act(async () => {
      await result.current.pay.pay(id, 'ref_x');
    });
    expect(result.current.pay.error).toBeInstanceOf(
      InvalidStatusTransitionError
    );
  });

  it('4xx rollback: state restored', async () => {
    const { result } = renderHook(
      () => ({ pay: usePayOrder(), ctx: useOrder() }),
      { wrapper }
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    server.use(
      http.post('http://localhost:3001/orders/:id/pay', () =>
        HttpResponse.json({ message: 'nope' }, { status: 400 })
      )
    );
    await act(async () => {
      await result.current.pay.pay(id, 'ref_test');
    });
    await waitFor(() =>
      expect(result.current.ctx.orders[0].status).toBe('CREATED')
    );
  });

  it('network rollback: state restored', async () => {
    const { result } = renderHook(
      () => ({ pay: usePayOrder(), ctx: useOrder() }),
      { wrapper }
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    server.use(
      http.post('http://localhost:3001/orders/:id/pay', () =>
        HttpResponse.error()
      )
    );
    await act(async () => {
      await result.current.pay.pay(id, 'ref_test');
    });
    await waitFor(() =>
      expect(result.current.ctx.orders[0].status).toBe('CREATED')
    );
  });
});
