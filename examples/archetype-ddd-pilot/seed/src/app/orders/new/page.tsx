import { PlaceOrderForm } from '@/features/place-order';

export default function NewOrderPage() {
  return (
    <main className="p-6">
      <h1 className="text-2xl font-bold">New Order</h1>
      <PlaceOrderForm />
    </main>
  );
}
