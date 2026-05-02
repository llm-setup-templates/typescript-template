'use client';
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className="p-6">
      <h2 className="text-lg font-bold">문제가 발생했습니다.</h2>
      <p className="mt-2 text-sm text-gray-600">{error.message}</p>
      <button
        onClick={reset}
        className="mt-4 rounded bg-blue-600 px-4 py-2 text-white"
      >
        다시 시도
      </button>
    </main>
  );
}
