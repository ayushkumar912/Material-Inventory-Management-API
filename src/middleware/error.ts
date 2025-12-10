import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: err.message,
      statusCode: err.statusCode
    });
    return;
  }

  // Prisma errors
  if (err.constructor.name === 'PrismaClientKnownRequestError') {
    const prismaError = err as any;
    
    if (prismaError.code === 'P2002') {
      res.status(409).json({
        error: 'Duplicate entry',
        message: 'A record with this value already exists'
      });
      return;
    }

    if (prismaError.code === 'P2025') {
      res.status(404).json({
        error: 'Not found',
        message: 'The requested record was not found'
      });
      return;
    }
  }

  // Log unexpected errors
  console.error('Unexpected error:', err);

  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'An unexpected error occurred'
  });
};

export const notFoundHandler = (
  req: Request,
  res: Response
): void => {
  res.status(404).json({
    error: 'Not found',
    message: `Route ${req.method} ${req.path} not found`
  });
};
