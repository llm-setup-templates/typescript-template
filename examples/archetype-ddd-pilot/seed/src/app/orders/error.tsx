'use client';
import {
  ApiClientError,
  ApiServerError,
  ApiNetworkError,
} from '@/shared/lib/errors';

export default function OrdersError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  let message = '주문 데이터를 불러오는 중 오류가 발생했습니다.';
  if (error instanceof ApiClientError)
    message = `클라이언트 오류 (${error.status}): ${error.message}`;
  else if (error instanceof ApiServerError)
    message = `서버 오류 (${error.status}). 잠시 후 다시 시도해주세요.`;
  else if (error instanceof ApiNetworkError)
    message = '네트워크 연결을 확인해주세요.';
  return (
    <main className="p-6">
      <h2 className="text-lg font-bold">주문 페이지 오류</h2>
      <p className="mt-2 text-sm text-gray-600">{message}</p>
      <button
        onClick={reset}
        className="mt-4 rounded bg-blue-600 px-4 py-2 text-white"
      >
        다시 시도
      </button>
    </main>
  );
}
