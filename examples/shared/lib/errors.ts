export enum ErrorCode {
  USER_NOT_FOUND = 'USER_NOT_FOUND',
  DUPLICATE_EMAIL = 'DUPLICATE_EMAIL',
  INVALID_INPUT = 'INVALID_INPUT',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
}

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message?: string,
    public readonly statusCode: number = 400
  ) {
    super(message ?? code);
    this.name = 'AppError';
  }
}
