import { isAxiosError } from 'axios';

export class ApiClientError extends Error {
  constructor(
    public status: number,
    msg: string,
  ) {
    super(msg);
    this.name = 'ApiClientError';
  }
}

export class ApiServerError extends Error {
  constructor(
    public status: number,
    msg: string,
  ) {
    super(msg);
    this.name = 'ApiServerError';
  }
}

export class ApiNetworkError extends Error {
  constructor(msg: string) {
    super(msg);
    this.name = 'ApiNetworkError';
  }
}

export function fromAxiosError(
  e: unknown,
): ApiClientError | ApiServerError | ApiNetworkError {
  if (isAxiosError(e)) {
    if (e.response) {
      return e.response.status >= 500
        ? new ApiServerError(e.response.status, e.message)
        : new ApiClientError(e.response.status, e.message);
    }
    return new ApiNetworkError(e.message);
  }
  return new ApiNetworkError(String(e));
}
