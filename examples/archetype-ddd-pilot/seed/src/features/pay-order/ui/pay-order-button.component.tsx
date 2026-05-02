'use client';
import { usePayOrder } from '../model/use-pay-order.hook';

export function PayOrderButton({ orderId }: { orderId: string }) {
  const { pay, error, pending } = usePayOrder();
  const handle = () => pay(orderId, `ref_${Date.now()}`);
  return (
    <div className="inline-flex flex-col">
      <button
        onClick={handle}
        disabled={pending}
        className="rounded bg-blue-600 px-3 py-1 text-sm text-white disabled:opacity-50"
      >
        {pending ? 'Paying...' : 'Pay'}
      </button>
      {error && <p className="text-xs text-red-600">{error.message}</p>}
    </div>
  );
}
