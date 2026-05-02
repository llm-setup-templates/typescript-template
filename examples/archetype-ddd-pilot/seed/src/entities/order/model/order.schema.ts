import { z } from 'zod';

export const MoneySchema = z.object({
  amount: z.number().nonnegative(),
  currency: z.enum(['KRW', 'USD']),
});
export const OrderItemSchema = z.object({
  productId: z.string().min(1),
  quantity: z.number().int().positive(),
  price: MoneySchema,
});
export const OrderStatusSchema = z.enum([
  'CREATED',
  'PAID',
  'SHIPPED',
  'DELIVERED',
  'CANCELLED',
]);
export const OrderSchema = z.object({
  id: z.string().min(1),
  items: z.array(OrderItemSchema).min(1),
  status: OrderStatusSchema,
  total: MoneySchema,
  createdAt: z.string().datetime(),
});
export const PlaceOrderRequestSchema = z.object({
  items: z.array(OrderItemSchema).min(1),
});

export type MoneyDto = z.infer<typeof MoneySchema>;
export type OrderItemDto = z.infer<typeof OrderItemSchema>;
export type OrderStatusDto = z.infer<typeof OrderStatusSchema>;
export type OrderDto = z.infer<typeof OrderSchema>;
export type OrderListResponse = { orders: OrderDto[] };
export type OrderResponse = OrderDto;
export type PlaceOrderRequest = z.infer<typeof PlaceOrderRequestSchema>;
