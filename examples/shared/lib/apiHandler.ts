/**
 * (Optional) Route Handler HOF — reduces repetitive try-catch boilerplate.
 *
 * @example
 * // Pattern A: Direct handling (Next.js standard)
 * export async function GET(req: NextRequest) {
 *   try {
 *     const data = await service.getData();
 *     return NextResponse.json(data);
 *   } catch (error) {
 *     return errorResponse(error);
 *   }
 * }
 *
 * // Pattern B: HOF usage (optional)
 * export const GET = apiHandler(async (req) => {
 *   const data = await service.getData();
 *   return NextResponse.json(data);
 * });
 *
 * // Dynamic routes: const { id } = await ctx.params;
 */
import { NextRequest, NextResponse } from 'next/server';
import { errorResponse } from './errorResponse';

type HandlerFn = (
  req: NextRequest,
  ctx: { params: Promise<Record<string, string>> }
) => Promise<NextResponse>;

export function apiHandler(handler: HandlerFn) {
  return async (
    req: NextRequest,
    ctx: { params: Promise<Record<string, string>> }
  ) => {
    try {
      return await handler(req, ctx);
    } catch (error) {
      return errorResponse(error);
    }
  };
}
