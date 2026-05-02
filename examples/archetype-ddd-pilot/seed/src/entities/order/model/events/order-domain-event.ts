import type { OrderCreated } from './order-created.event';
import type { OrderCancelled } from './order-cancelled.event';
import type { OrderPaid } from './order-paid.event';

export type { OrderCreated, OrderCancelled, OrderPaid };
export type OrderDomainEvent = OrderCreated | OrderCancelled | OrderPaid;
