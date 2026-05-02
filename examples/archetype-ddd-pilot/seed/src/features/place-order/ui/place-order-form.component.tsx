'use client';
import { useState, type FormEvent } from 'react';
import { useOrder } from '@/shared/state/order-context.client';
import {
  Order,
  OrderItem,
  InvariantViolationError,
  PlaceOrderRequestSchema,
} from '@/entities/order';

export function PlaceOrderForm() {
  const { placeOrder } = useOrder();
  const [items, setItems] = useState([
    {
      productId: '',
      quantity: 1,
      price: { amount: 0, currency: 'KRW' as const },
    },
  ]);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setPending(true);
    // Layer 1: input shape (zod)
    const parsed = PlaceOrderRequestSchema.safeParse({ items });
    if (!parsed.success) {
      setError(parsed.error.issues[0].message);
      setPending(false);
      return;
    }
    // Layer 2: client invariant -- Order.create() throws InvariantViolationError
    // on currency mismatch / empty items. The instance is discarded; only used
    // for validation. id/createdAt are server-assigned.
    try {
      Order.create(parsed.data.items.map(OrderItem.fromDto));
    } catch (err) {
      if (err instanceof InvariantViolationError) {
        setError(`주문 무결성 위반: ${err.message}`);
        setPending(false);
        return;
      }
      throw err;
    }
    // Layer 3: external boundary -- pass PlaceOrderRequest (items only).
    // R2-05/CX2-5: Provider throws mapped ApiError. Display its message.
    try {
      await placeOrder(parsed.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : '알 수 없는 오류');
    } finally {
      setPending(false);
    }
  };

  const updateItem = (idx: number, patch: Partial<(typeof items)[number]>) => {
    setItems((prev) =>
      prev.map((it, i) => (i === idx ? { ...it, ...patch } : it))
    );
  };

  return (
    <form onSubmit={handleSubmit} className="mt-4 space-y-3">
      {items.map((item, idx) => (
        <div key={idx} className="flex gap-2">
          <input
            type="text"
            placeholder="productId"
            value={item.productId}
            onChange={(e) => updateItem(idx, { productId: e.target.value })}
            className="rounded border px-2 py-1"
            required
          />
          <input
            type="number"
            min={1}
            value={item.quantity}
            onChange={(e) =>
              updateItem(idx, { quantity: Number(e.target.value) })
            }
            className="w-20 rounded border px-2 py-1"
          />
          <input
            type="number"
            min={0}
            value={item.price.amount}
            onChange={(e) =>
              updateItem(idx, {
                price: { ...item.price, amount: Number(e.target.value) },
              })
            }
            className="w-28 rounded border px-2 py-1"
          />
        </div>
      ))}
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button
        type="submit"
        disabled={pending}
        className="rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
      >
        {pending ? 'Submitting...' : 'Place order'}
      </button>
    </form>
  );
}
