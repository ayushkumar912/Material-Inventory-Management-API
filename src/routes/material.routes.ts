import { Router } from 'express';
import materialController from '../controllers/material.controller';
import { resolveTenant } from '../middleware/tenant';

const router = Router();

// Apply tenant middleware to all material routes
router.use(resolveTenant);

/**
 * POST /materials - Create a new material (tenant-scoped)
 * Requires x-tenant-id header
 */
router.post('/', materialController.createMaterial.bind(materialController));

/**
 * GET /materials - List all materials for tenant
 * Requires x-tenant-id header
 */
router.get('/', materialController.getMaterials.bind(materialController));

/**
 * GET /materials/:id - Get material by ID with transactions
 * Requires x-tenant-id header
 * Enforces tenant isolation
 */
router.get('/:id', materialController.getMaterialById.bind(materialController));

export default router;
