import type { Order, PlaceOrderRequest } from '@/entities/order';
import type {
  ApiClientError,
  ApiServerError,
  ApiNetworkError,
} from '@/shared/lib/errors';

export interface OrderContextValue {
  orders: ReadonlyArray<Order>;
  placeOrder: (request: PlaceOrderRequest) => Promise<void>;
  cancelOrder: (orderId: string) => Promise<void>;
  payOrder: (orderId: string, paymentRef: string) => Promise<void>;
  error: ApiClientError | ApiServerError | ApiNetworkError | Error | null;
}
