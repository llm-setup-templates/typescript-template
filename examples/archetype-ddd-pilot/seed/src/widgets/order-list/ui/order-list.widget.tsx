'use client';
import { useMemo } from 'react';
import { Order } from '@/entities/order';
import type { OrderDto } from '@/entities/order';
import { OrderStatusBadge } from '@/entities/order';

export function OrderListWidget({ orderDtos }: { orderDtos: OrderDto[] }) {
  const orders = useMemo(() => orderDtos.map(Order.fromDto), [orderDtos]);
  if (orders.length === 0) return <p className="p-6">No orders yet.</p>;
  return (
    <ul className="divide-y">
      {orders.map((o) => (
        <li key={o.id} className="flex items-center gap-3 px-6 py-3">
          <a
            href={`/orders/${o.id}`}
            className="font-mono text-sm text-blue-600 underline"
          >
            {o.id}
          </a>
          <OrderStatusBadge status={o.status} />
          <span className="ml-auto text-sm">
            {o.total.amount} {o.total.currency}
          </span>
        </li>
      ))}
    </ul>
  );
}
