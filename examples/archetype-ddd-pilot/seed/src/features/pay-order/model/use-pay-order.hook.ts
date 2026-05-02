'use client';
import { useState, useCallback } from 'react';
import { useOrder } from '@/shared/state/order-context.client';
import { InvalidStatusTransitionError, Order } from '@/entities/order';

export function usePayOrder() {
  const { orders, payOrder } = useOrder();
  const [error, setError] = useState<Error | null>(null);
  const [pending, setPending] = useState(false);

  const pay = useCallback(
    async (orderId: string, paymentRef: string) => {
      setError(null);
      const target = orders.find((o) => o.id === orderId);
      if (!target) {
        setError(new Error('Order not found'));
        return;
      }
      const probe = Order.fromDto(target.toDto());
      try {
        probe.pay(paymentRef);
      } catch (e) {
        if (e instanceof InvalidStatusTransitionError) {
          setError(e);
          return;
        }
        throw e;
      }
      setPending(true);
      try {
        await payOrder(orderId, paymentRef);
      } catch (e) {
        setError(e instanceof Error ? e : new Error(String(e)));
      } finally {
        setPending(false);
      }
    },
    [orders, payOrder],
  );

  return { pay, error, pending };
}
