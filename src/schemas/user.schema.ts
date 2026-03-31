import { z } from 'zod';

export const createUserSchema = z.object({
  email: z.string().email('Invalid email format').max(255).toLowerCase().trim(),
  name: z.string().min(1, 'Name is required and cannot be empty').max(100).trim(),
  role: z.enum(['ADMIN', 'USER'], { message: 'Role must be either ADMIN or USER' }).optional()
});

export const updateUserSchema = z
  .object({
    name: z.string().min(1, 'Name cannot be empty').max(100).trim().optional(),
    role: z.enum(['ADMIN', 'USER'], { message: 'Role must be either ADMIN or USER' }).optional()
  })
  .refine((data) => data.name !== undefined || data.role !== undefined, {
    message: 'At least one field (name or role) must be provided'
  });
