import { orderApi } from '@/entities/order';
import { OrderListWidget } from '@/widgets/order-list';

// Avoid SSG prerender hitting an API server that does not exist at build time.
export const dynamic = 'force-dynamic';

export default async function OrdersPage() {
  const res = await orderApi.getOrders();
  return <OrderListWidget orderDtos={res.data.orders} />;
}
