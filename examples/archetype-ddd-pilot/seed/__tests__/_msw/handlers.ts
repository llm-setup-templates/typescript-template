import { http, HttpResponse } from 'msw';

const sampleOrder = {
  id: 'order_test_1',
  items: [
    { productId: 'p1', quantity: 2, price: { amount: 100, currency: 'KRW' } },
  ],
  status: 'CREATED',
  total: { amount: 200, currency: 'KRW' },
  createdAt: '2026-05-02T00:00:00.000Z',
};

export const handlers = [
  http.get('http://localhost:3001/orders', () =>
    HttpResponse.json({ orders: [sampleOrder] })
  ),
  http.get('http://localhost:3001/orders/:id', ({ params }) =>
    HttpResponse.json({ ...sampleOrder, id: String(params.id) })
  ),
  http.post('http://localhost:3001/orders', () =>
    HttpResponse.json(sampleOrder, { status: 201 })
  ),
  http.post('http://localhost:3001/orders/:id/cancel', ({ params }) =>
    HttpResponse.json({
      ...sampleOrder,
      id: String(params.id),
      status: 'CANCELLED',
    })
  ),
  http.post('http://localhost:3001/orders/:id/pay', ({ params }) =>
    HttpResponse.json({
      ...sampleOrder,
      id: String(params.id),
      status: 'PAID',
    })
  ),
];
