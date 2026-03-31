import { z } from 'zod';

export const createTenantSchema = z.object({
  name: z.string().min(1, 'Name is required and cannot be empty').max(100).trim(),
  plan: z.enum(['FREE', 'PRO'], { message: 'Plan must be either FREE or PRO' }).optional()
});
