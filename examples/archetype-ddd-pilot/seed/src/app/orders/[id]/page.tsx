import { orderApi } from '@/entities/order/api/order.api';
import { OrderDetailWidget } from '@/widgets/order-detail';

export default async function OrderDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const res = await orderApi.getOrder(id);
  return <OrderDetailWidget orderDto={res.data} />;
}
