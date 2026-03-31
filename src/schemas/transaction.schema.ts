import { z } from 'zod';

export const createTransactionSchema = z.object({
  quantity: z.number().positive('Quantity must be a positive number'),
  type: z.enum(['IN', 'OUT'], { message: 'Type must be either IN or OUT' })
});
