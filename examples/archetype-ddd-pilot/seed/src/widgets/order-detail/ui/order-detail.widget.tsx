'use client';
import { useMemo } from 'react';
import { Order } from '@/entities/order';
import type { OrderDto } from '@/entities/order';
import { OrderStatusBadge } from '@/entities/order/ui/order-status-badge.component';
import { CancelOrderButton } from '@/features/cancel-order';
import { PayOrderButton } from '@/features/pay-order';

export function OrderDetailWidget({ orderDto }: { orderDto: OrderDto }) {
  const order = useMemo(() => Order.fromDto(orderDto), [orderDto]);
  return (
    <main className="p-6">
      <header className="flex items-center gap-3">
        <h1 className="font-mono text-lg">{order.id}</h1>
        <OrderStatusBadge status={order.status} />
        <span className="ml-auto text-sm text-gray-600">
          {order.total.amount} {order.total.currency}
        </span>
      </header>
      <ul className="mt-4 divide-y">
        {order.items.map((item, idx) => (
          <li key={`${item.productId}-${idx}`} className="flex gap-3 py-2">
            <span className="font-mono text-sm">{item.productId}</span>
            <span className="text-sm text-gray-600">x{item.quantity}</span>
            <span className="ml-auto text-sm">
              {item.price.amount} {item.price.currency}
            </span>
          </li>
        ))}
      </ul>
      <div className="mt-4 flex gap-2">
        <PayOrderButton orderId={order.id} />
        <CancelOrderButton orderId={order.id} />
      </div>
    </main>
  );
}
