import { Router } from 'express';
import tenantController from '../controllers/tenant.controller';

const router = Router();

/**
 * POST /tenants - Create a new tenant
 * No tenant middleware required for this endpoint
 */
router.post('/', tenantController.createTenant.bind(tenantController));

/**
 * GET /tenants/:id - Get tenant by ID
 */
router.get('/:id', tenantController.getTenant.bind(tenantController));

export default router;
