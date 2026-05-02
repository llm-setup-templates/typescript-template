import { Money } from './Money';
import type { OrderItemDto } from './order.schema';

export class OrderItem {
  private constructor(
    public readonly productId: string,
    public readonly quantity: number,
    public readonly price: Money
  ) {
    if (quantity <= 0) throw new Error('OrderItem.quantity must be positive');
  }
  static create(productId: string, quantity: number, price: Money): OrderItem {
    return new OrderItem(productId, quantity, price);
  }
  static fromDto(dto: OrderItemDto): OrderItem {
    return new OrderItem(dto.productId, dto.quantity, Money.from(dto.price));
  }
  total(): Money {
    return this.price.multiply(this.quantity);
  }
  toDto(): OrderItemDto {
    return {
      productId: this.productId,
      quantity: this.quantity,
      price: this.price.toJSON(),
    };
  }
}
