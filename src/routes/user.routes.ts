import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { resolveTenant } from '../middleware/tenant';

const router = Router();

// Apply tenant middleware to all user routes
router.use(resolveTenant);

/**
 * POST /users - Create a new user (tenant-scoped)
 * Requires x-tenant-id header
 */
router.post('/', userController.createUser.bind(userController));

/**
 * GET /users - List all users for tenant
 * Requires x-tenant-id header
 */
router.get('/', userController.getUsers.bind(userController));

/**
 * GET /users/:id - Get user by ID
 * Requires x-tenant-id header
 * Enforces tenant isolation
 */
router.get('/:id', userController.getUserById.bind(userController));

/**
 * PUT /users/:id - Update user
 * Requires x-tenant-id header
 */
router.put('/:id', userController.updateUser.bind(userController));

/**
 * DELETE /users/:id - Delete user
 * Requires x-tenant-id header
 */
router.delete('/:id', userController.deleteUser.bind(userController));

export default router;
