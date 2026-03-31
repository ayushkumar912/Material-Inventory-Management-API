import { z } from 'zod';

export const createMaterialSchema = z.object({
  name: z.string().min(1, 'Name is required and cannot be empty').max(100).trim(),
  unit: z.string().min(1, 'Unit is required and cannot be empty').max(50).trim(),
  currentStock: z.number().nonnegative('Current stock must be a non-negative number').optional()
});
