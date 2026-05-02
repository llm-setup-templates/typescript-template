import type { OrderStatusDto } from './order.schema';

const TRANSITIONS: Record<OrderStatusDto, ReadonlySet<OrderStatusDto>> = {
  CREATED: new Set<OrderStatusDto>(['PAID', 'CANCELLED']),
  PAID: new Set<OrderStatusDto>(['SHIPPED', 'CANCELLED']),
  SHIPPED: new Set<OrderStatusDto>(['DELIVERED']),
  DELIVERED: new Set<OrderStatusDto>(),
  CANCELLED: new Set<OrderStatusDto>(),
};

export function canTransitionTo(
  from: OrderStatusDto,
  to: OrderStatusDto,
): boolean {
  return TRANSITIONS[from].has(to);
}
