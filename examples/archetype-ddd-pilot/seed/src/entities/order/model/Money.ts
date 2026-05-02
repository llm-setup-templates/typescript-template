export class Money {
  private constructor(
    public readonly amount: number,
    public readonly currency: 'KRW' | 'USD',
  ) {
    if (!Number.isFinite(amount) || amount < 0) {
      throw new Error('Money.amount must be non-negative finite');
    }
  }
  static from(value: { amount: number; currency: 'KRW' | 'USD' }): Money {
    return new Money(value.amount, value.currency);
  }
  static zero(currency: 'KRW' | 'USD'): Money {
    return new Money(0, currency);
  }
  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new Error(`Currency mismatch: ${this.currency} vs ${other.currency}`);
    }
    return new Money(this.amount + other.amount, this.currency);
  }
  multiply(factor: number): Money {
    return new Money(this.amount * factor, this.currency);
  }
  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
  toJSON() {
    return { amount: this.amount, currency: this.currency };
  }
}
