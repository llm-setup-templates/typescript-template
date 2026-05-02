import { describe, it, expect } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { OrderProvider } from '@/app/providers/order.context';
import { useCancelOrder } from '@/features/cancel-order';
import { useOrder } from '@/shared/state/order-context.client';
import { InvalidStatusTransitionError } from '@/entities/order';
import { server } from '../../vitest.setup.unit';

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <OrderProvider>{children}</OrderProvider>
);

const seedRequest = () => ({
  items: [
    { productId: 'p1', quantity: 1, price: { amount: 100, currency: 'KRW' as const } },
  ],
});

async function seedOneOrder() {
  const hook = renderHook(
    () => ({ ctx: useOrder() }),
    { wrapper },
  );
  await act(async () => {
    await hook.result.current.ctx.placeOrder(seedRequest());
  });
  return hook;
}

describe('useCancelOrder', () => {
  it('happy path: optimistic CANCELLED and committed', async () => {
    const seeded = await seedOneOrder();
    const orderId = seeded.result.current.ctx.orders[0].id;
    const { result } = renderHook(
      () => ({ cancel: useCancelOrder(), ctx: useOrder() }),
      { wrapper: ({ children }) => wrapper({ children }) },
    );
    // Re-seed because new wrapper has fresh provider
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    await act(async () => {
      await result.current.cancel.cancel(id);
    });
    await waitFor(() =>
      expect(result.current.ctx.orders[0].status).toBe('CANCELLED'),
    );
    expect(orderId).toBeDefined();
  });

  it('invariant violation: cancel from DELIVERED state', async () => {
    // Seed with status=DELIVERED via a custom GET response and Order.fromDto reload
    server.use(
      http.post('http://localhost:3001/orders', () =>
        HttpResponse.json(
          {
            id: 'order_done',
            items: [
              { productId: 'p1', quantity: 1, price: { amount: 100, currency: 'KRW' } },
            ],
            status: 'DELIVERED',
            total: { amount: 100, currency: 'KRW' },
            createdAt: '2026-05-02T00:00:00.000Z',
          },
          { status: 201 },
        ),
      ),
    );
    const { result } = renderHook(
      () => ({ cancel: useCancelOrder(), ctx: useOrder() }),
      { wrapper },
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    await act(async () => {
      await result.current.cancel.cancel(id);
    });
    expect(result.current.cancel.error).toBeInstanceOf(
      InvalidStatusTransitionError,
    );
  });

  it('4xx rollback: state is restored on server reject', async () => {
    const { result } = renderHook(
      () => ({ cancel: useCancelOrder(), ctx: useOrder() }),
      { wrapper },
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    server.use(
      http.post('http://localhost:3001/orders/:id/cancel', () =>
        HttpResponse.json({ message: 'nope' }, { status: 400 }),
      ),
    );
    await act(async () => {
      await result.current.cancel.cancel(id);
    });
    await waitFor(() =>
      expect(result.current.ctx.orders[0].status).toBe('CREATED'),
    );
  });

  it('network rollback: state is restored on transport failure', async () => {
    const { result } = renderHook(
      () => ({ cancel: useCancelOrder(), ctx: useOrder() }),
      { wrapper },
    );
    await act(async () => {
      await result.current.ctx.placeOrder(seedRequest());
    });
    const id = result.current.ctx.orders[0].id;
    server.use(
      http.post('http://localhost:3001/orders/:id/cancel', () =>
        HttpResponse.error(),
      ),
    );
    await act(async () => {
      await result.current.cancel.cancel(id);
    });
    await waitFor(() =>
      expect(result.current.ctx.orders[0].status).toBe('CREATED'),
    );
  });
});
