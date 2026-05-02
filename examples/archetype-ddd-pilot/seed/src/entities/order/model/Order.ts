import { Money } from './Money';
import { OrderItem } from './OrderItem';
import { canTransitionTo } from './OrderStatus';
import type { OrderStatusDto } from './order.schema';
import { OrderSchema } from './order.schema';
import {
  InvariantViolationError,
  InvalidStatusTransitionError,
} from './errors';
import { generateId } from '@/shared/lib/ids';

export class Order {
  private constructor(
    public readonly id: string,
    public readonly items: ReadonlyArray<OrderItem>,
    private _status: OrderStatusDto,
    public readonly total: Money,
    public readonly createdAt: string
  ) {}

  static create(items: OrderItem[]): Order {
    if (items.length === 0)
      throw new InvariantViolationError('Order must have at least one item');
    const currency = items[0].price.currency;
    if (!items.every((i) => i.price.currency === currency)) {
      throw new InvariantViolationError(
        'All OrderItem must share the same currency'
      );
    }
    const total = items.reduce(
      (sum, item) => sum.add(item.total()),
      Money.zero(currency)
    );
    return new Order(
      generateId(),
      items,
      'CREATED',
      total,
      new Date().toISOString()
    );
  }

  static fromDto(dto: unknown): Order {
    const parsed = OrderSchema.parse(dto);
    return new Order(
      parsed.id,
      parsed.items.map(OrderItem.fromDto),
      parsed.status,
      Money.from(parsed.total),
      parsed.createdAt
    );
  }

  get status(): OrderStatusDto {
    return this._status;
  }

  cancel(): void {
    if (!canTransitionTo(this._status, 'CANCELLED')) {
      throw new InvalidStatusTransitionError(this._status, 'CANCELLED');
    }
    this._status = 'CANCELLED';
  }

  pay(_paymentRef: string): void {
    if (!canTransitionTo(this._status, 'PAID')) {
      throw new InvalidStatusTransitionError(this._status, 'PAID');
    }
    this._status = 'PAID';
  }

  markShipped(): void {
    if (!canTransitionTo(this._status, 'SHIPPED'))
      throw new InvalidStatusTransitionError(this._status, 'SHIPPED');
    this._status = 'SHIPPED';
  }

  markDelivered(): void {
    if (!canTransitionTo(this._status, 'DELIVERED'))
      throw new InvalidStatusTransitionError(this._status, 'DELIVERED');
    this._status = 'DELIVERED';
  }

  toDto() {
    return {
      id: this.id,
      items: this.items.map((i) => i.toDto()),
      status: this._status,
      total: this.total.toJSON(),
      createdAt: this.createdAt,
    };
  }
}
