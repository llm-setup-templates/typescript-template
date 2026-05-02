import { cn } from '@/shared/lib/cn';
import type { OrderStatusDto } from '../model/order.schema';

const STATUS_VARIANT: Record<OrderStatusDto, string> = {
  CREATED: 'bg-gray-100 text-gray-700',
  PAID: 'bg-blue-100 text-blue-700',
  SHIPPED: 'bg-yellow-100 text-yellow-700',
  DELIVERED: 'bg-green-100 text-green-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export function OrderStatusBadge({
  status,
  className,
}: {
  status: OrderStatusDto;
  className?: string;
}) {
  return (
    <span
      className={cn(
        'inline-block rounded px-2 py-0.5 text-xs font-medium',
        STATUS_VARIANT[status],
        className
      )}
    >
      {status}
    </span>
  );
}
