import { Response } from 'express';

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export function sendSuccess(res: Response, data: unknown, message?: string, status = 200): void {
  const body: Record<string, unknown> = { success: true, data };
  if (message) body.message = message;
  res.status(status).json(body);
}

export function sendCreated(res: Response, data: unknown, message?: string): void {
  sendSuccess(res, data, message, 201);
}

export function sendList(res: Response, data: unknown[], meta: PaginationMeta): void {
  res.status(200).json({ success: true, data, meta });
}

export function sendMessage(res: Response, message: string): void {
  res.status(200).json({ success: true, message });
}
