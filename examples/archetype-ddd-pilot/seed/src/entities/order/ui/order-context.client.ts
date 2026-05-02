'use client';
import { createContext, useContext } from 'react';
import type { OrderContextValue } from '../model/order-context.contract';

export const OrderContext = createContext<OrderContextValue | null>(null);

/**
 * useOrder -- not for RSC use (useContext is client-only).
 * For type references in RSC, import OrderContextValue from
 * '@/entities/order' instead. Value imports must come from this client module.
 */
export function useOrder(): OrderContextValue {
  const ctx = useContext(OrderContext);
  if (!ctx) throw new Error('useOrder must be used within OrderProvider');
  return ctx;
}
