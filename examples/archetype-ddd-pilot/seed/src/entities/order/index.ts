// Domain (model/)
export { Order } from './model/Order';
export { OrderItem } from './model/OrderItem';
export { Money } from './model/Money';
export { canTransitionTo } from './model/OrderStatus';
export {
  InvariantViolationError,
  InvalidStatusTransitionError,
} from './model/errors';
export type {
  OrderDomainEvent,
  OrderCreated,
  OrderCancelled,
  OrderPaid,
} from './model/events/order-domain-event';
export type {
  OrderDto,
  OrderItemDto,
  MoneyDto,
  OrderStatusDto,
  OrderResponse,
  OrderListResponse,
  PlaceOrderRequest,
} from './model/order.schema';
export { OrderSchema, PlaceOrderRequestSchema } from './model/order.schema';

// Context contract (type-only, RSC-safe)
export type { OrderContextValue } from './model/order-context.contract';

// API adapter (Axios + React.cache)
export { orderApi } from './api/order.api';

// UI (CSC -- 'use client' boundary kept inside the originating modules)
export { OrderStatusBadge } from './ui/order-status-badge.component';
export { OrderContext, useOrder } from './ui/order-context.client';
