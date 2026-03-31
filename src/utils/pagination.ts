import { Request } from 'express';
import { PaginationMeta } from './response';

export interface PaginationParams {
  page: number;
  limit: number;
  skip: number;
}

export function parsePagination(query: Request['query']): PaginationParams {
  const page = Math.max(1, parseInt(query.page as string) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit as string) || 20));
  return { page, limit, skip: (page - 1) * limit };
}

export function buildMeta(total: number, page: number, limit: number): PaginationMeta {
  return { total, page, limit, totalPages: Math.ceil(total / limit) };
}
