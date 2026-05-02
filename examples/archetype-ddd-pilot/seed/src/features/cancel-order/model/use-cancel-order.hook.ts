'use client';
import { useState, useCallback } from 'react';
import { useOrder } from '@/shared/state/order-context.client';
import { InvalidStatusTransitionError, Order } from '@/entities/order';

export function useCancelOrder() {
  const { orders, cancelOrder } = useOrder();
  const [error, setError] = useState<Error | null>(null);
  const [pending, setPending] = useState(false);

  const cancel = useCallback(
    async (orderId: string) => {
      setError(null);
      const target = orders.find((o) => o.id === orderId);
      if (!target) {
        setError(new Error('Order not found'));
        return;
      }
      // Client invariant pre-check (DISCUSS TS-Q16 LOCK Layer 2):
      // simulate transition on a NEW Order built from DTO (do not mutate target).
      const probe = Order.fromDto(target.toDto());
      try {
        probe.cancel();
      } catch (e) {
        if (e instanceof InvalidStatusTransitionError) {
          setError(e);
          return;
        }
        throw e;
      }
      setPending(true);
      try {
        await cancelOrder(orderId);
      } catch (e) {
        setError(e instanceof Error ? e : new Error(String(e)));
      } finally {
        setPending(false);
      }
    },
    [orders, cancelOrder]
  );

  return { cancel, error, pending };
}
