import { describe, it, expect } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { http, HttpResponse } from 'msw';
import { OrderProvider } from '@/app/providers/order.context';
import { usePlaceOrder } from '@/features/place-order';
import { useOrder } from '@/shared/state/order-context.client';
import { server } from '../../vitest.setup.unit';

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <OrderProvider>{children}</OrderProvider>
);

const makeRequest = () => ({
  items: [
    {
      productId: 'p1',
      quantity: 2,
      price: { amount: 100, currency: 'KRW' as const },
    },
  ],
});

describe('usePlaceOrder', () => {
  it('happy path: appends new order to context state', async () => {
    const { result } = renderHook(
      () => ({ place: usePlaceOrder(), ctx: useOrder() }),
      { wrapper }
    );
    await act(async () => {
      await result.current.place.place(makeRequest());
    });
    await waitFor(() => expect(result.current.ctx.orders).toHaveLength(1));
  });

  it('4xx server error sets error', async () => {
    server.use(
      http.post('http://localhost:3001/orders', () =>
        HttpResponse.json({ message: 'bad' }, { status: 400 })
      )
    );
    const { result } = renderHook(() => usePlaceOrder(), { wrapper });
    await act(async () => {
      await result.current.place(makeRequest());
    });
    await waitFor(() => expect(result.current.error).toBeTruthy());
  });

  it('network error sets error', async () => {
    server.use(
      http.post('http://localhost:3001/orders', () => HttpResponse.error())
    );
    const { result } = renderHook(() => usePlaceOrder(), { wrapper });
    await act(async () => {
      await result.current.place(makeRequest());
    });
    await waitFor(() => expect(result.current.error).toBeTruthy());
  });
});
