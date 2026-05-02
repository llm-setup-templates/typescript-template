import type { OrderDto } from '../order.schema';
export interface OrderCreated {
  type: 'OrderCreated';
  occurredAt: string;
  payload: OrderDto;
}
