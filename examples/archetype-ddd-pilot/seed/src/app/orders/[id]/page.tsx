import { orderApi } from '@/entities/order';
import { OrderDetailWidget } from '@/widgets/order-detail';

// Avoid SSG prerender hitting an API server that does not exist at build time.
export const dynamic = 'force-dynamic';

export default async function OrderDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const res = await orderApi.getOrder(id);
  return <OrderDetailWidget orderDto={res.data} />;
}
