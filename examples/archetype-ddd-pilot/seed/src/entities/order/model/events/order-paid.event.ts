export interface OrderPaid {
  type: 'OrderPaid';
  orderId: string;
  paymentRef: string;
  occurredAt: string;
}
