'use client';
import { useState, useCallback } from 'react';
import { useOrder } from '@/shared/state/order-context.client';
import type { PlaceOrderRequest } from '@/entities/order';

export function usePlaceOrder() {
  const { placeOrder } = useOrder();
  const [error, setError] = useState<Error | null>(null);
  const [pending, setPending] = useState(false);

  const place = useCallback(
    async (request: PlaceOrderRequest) => {
      setError(null);
      setPending(true);
      try {
        await placeOrder(request);
      } catch (e) {
        setError(e instanceof Error ? e : new Error(String(e)));
      } finally {
        setPending(false);
      }
    },
    [placeOrder]
  );

  return { place, error, pending };
}
