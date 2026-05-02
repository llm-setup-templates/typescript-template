'use client';
import { useState, useCallback, type ReactNode } from 'react';
import { OrderContext } from '@/shared/state/order-context.client';
import type { OrderContextValue } from '@/shared/state/order-context.contract';
import { Order, type PlaceOrderRequest } from '@/entities/order';
import { orderApi } from '@/entities/order/api/order.api';
import { fromAxiosError } from '@/shared/lib/errors';

export function OrderProvider({ children }: { children: ReactNode }) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<Error | null>(null);
  // R5-CX5-1: rollback snapshot is captured as outer-scope const inside each
  // mutation function (pure, Strict Mode safe). The previous useRef pattern
  // was unsafe inside React 19 functional updaters and was removed.

  const placeOrder: OrderContextValue['placeOrder'] = useCallback(
    async (request: PlaceOrderRequest) => {
      setError(null);
      try {
        const res = await orderApi.placeOrder(request);
        // R4-06/CX4-6: Order.fromDto may throw ZodError. Calling it INSIDE the
        // setOrders updater would surface that throw during React's render
        // phase, bypassing this try/catch. So parse + instantiate first, then
        // append.
        const newOrder = Order.fromDto(res.data);
        setOrders((prev) => [...prev, newOrder]);
      } catch (e) {
        // R2-05/CX2-5: throw the mapped error, not the raw AxiosError.
        const mapped = fromAxiosError(e);
        setError(mapped);
        throw mapped;
      }
    },
    [],
  );

  const cancelOrder: OrderContextValue['cancelOrder'] = useCallback(
    async (orderId: string) => {
      setError(null);
      const target = orders.find((o) => o.id === orderId);
      if (!target) {
        setError(new Error('Order not found'));
        return;
      }
      const snapshot = orders;
      const optimistic = Order.fromDto({
        ...target.toDto(),
        status: 'CANCELLED',
      });
      setOrders((prev) =>
        prev.map((o) => (o.id === orderId ? optimistic : o)),
      );
      try {
        const res = await orderApi.cancelOrder(orderId);
        const updated = Order.fromDto(res.data);
        setOrders((prev) =>
          prev.map((o) => (o.id === orderId ? updated : o)),
        );
      } catch (e) {
        const mapped = fromAxiosError(e);
        setOrders(snapshot);
        setError(mapped);
        throw mapped;
      }
    },
    [orders],
  );

  const payOrder: OrderContextValue['payOrder'] = useCallback(
    async (orderId: string, paymentRef: string) => {
      setError(null);
      const target = orders.find((o) => o.id === orderId);
      if (!target) {
        setError(new Error('Order not found'));
        return;
      }
      const snapshot = orders;
      const optimistic = Order.fromDto({ ...target.toDto(), status: 'PAID' });
      setOrders((prev) =>
        prev.map((o) => (o.id === orderId ? optimistic : o)),
      );
      try {
        const res = await orderApi.payOrder(orderId, paymentRef);
        const updated = Order.fromDto(res.data);
        setOrders((prev) =>
          prev.map((o) => (o.id === orderId ? updated : o)),
        );
      } catch (e) {
        const mapped = fromAxiosError(e);
        setOrders(snapshot);
        setError(mapped);
        throw mapped;
      }
    },
    [orders],
  );

  return (
    <OrderContext.Provider
      value={{ orders, placeOrder, cancelOrder, payOrder, error }}
    >
      {children}
    </OrderContext.Provider>
  );
}
