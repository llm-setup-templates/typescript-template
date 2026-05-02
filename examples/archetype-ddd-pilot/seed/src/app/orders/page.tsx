import { orderApi } from '@/entities/order/api/order.api';
import { OrderListWidget } from '@/widgets/order-list';

export default async function OrdersPage() {
  const res = await orderApi.getOrders();
  return <OrderListWidget orderDtos={res.data.orders} />;
}
