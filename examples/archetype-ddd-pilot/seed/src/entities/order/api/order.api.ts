import { cache } from 'react';
import type { AxiosResponse } from 'axios';
import { api } from '@/shared/api/base';
import type {
  OrderResponse,
  OrderListResponse,
  PlaceOrderRequest,
} from '../model/order.schema';

/**
 * orderApi -- Axios + React.cache wrapped GETs.
 *
 * NOTE: React.cache memoizes per-request inside an RSC tree only. In CSC ('use client')
 *       contexts cache() is effectively a no-op -- the wrapped function still calls Axios on
 *       every invocation. For CSC re-fetch deduplication, use Context state (OrderProvider).
 *       Reference: https://react.dev/reference/react/cache
 */
export const orderApi = {
  getOrder: cache(
    (id: string): Promise<AxiosResponse<OrderResponse>> =>
      api.get<OrderResponse>(`/orders/${id}`),
  ),
  getOrders: cache(
    (): Promise<AxiosResponse<OrderListResponse>> =>
      api.get<OrderListResponse>('/orders'),
  ),
  placeOrder: (
    request: PlaceOrderRequest,
  ): Promise<AxiosResponse<OrderResponse>> =>
    api.post<OrderResponse>('/orders', request),
  cancelOrder: (id: string): Promise<AxiosResponse<OrderResponse>> =>
    api.post<OrderResponse>(`/orders/${id}/cancel`),
  payOrder: (
    id: string,
    paymentRef: string,
  ): Promise<AxiosResponse<OrderResponse>> =>
    api.post<OrderResponse>(`/orders/${id}/pay`, { paymentRef }),
};
