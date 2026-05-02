'use client';
import { useCancelOrder } from '../model/use-cancel-order.hook';

export function CancelOrderButton({ orderId }: { orderId: string }) {
  const { cancel, error, pending } = useCancelOrder();
  return (
    <div className="inline-flex flex-col">
      <button
        onClick={() => cancel(orderId)}
        disabled={pending}
        className="rounded bg-red-600 px-3 py-1 text-sm text-white disabled:opacity-50"
      >
        {pending ? 'Cancelling...' : 'Cancel'}
      </button>
      {error && <p className="text-xs text-red-600">{error.message}</p>}
    </div>
  );
}
