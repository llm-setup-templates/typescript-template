export interface OrderCancelled {
  type: 'OrderCancelled';
  orderId: string;
  occurredAt: string;
  reason?: string;
}
