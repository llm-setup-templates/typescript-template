import { NextResponse } from 'next/server';
import { AppError, ErrorCode } from './errors';

export interface ErrorResponseBody {
  error: string;
  message: string;
}

export function errorResponse(error: unknown): NextResponse<ErrorResponseBody> {
  if (error instanceof AppError) {
    return NextResponse.json(
      { error: error.code, message: error.message },
      { status: error.statusCode }
    );
  }
  return NextResponse.json(
    { error: ErrorCode.INTERNAL_ERROR, message: 'Internal server error' },
    { status: 500 }
  );
}
