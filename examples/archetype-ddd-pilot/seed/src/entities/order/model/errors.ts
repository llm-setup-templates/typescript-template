export class InvariantViolationError extends Error {
  constructor(msg: string) {
    super(msg);
    this.name = 'InvariantViolationError';
  }
}

export class InvalidStatusTransitionError extends Error {
  constructor(
    public readonly from: string,
    public readonly to: string,
  ) {
    super(`Invalid transition: ${from} -> ${to}`);
    this.name = 'InvalidStatusTransitionError';
  }
}
