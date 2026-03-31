import { Router } from 'express';
import tenantController from '../controllers/tenant.controller';
import { validateBody } from '../middleware/validate';
import { createTenantSchema } from '../schemas/tenant.schema';

const router = Router();

router.post('/', validateBody(createTenantSchema), tenantController.createTenant.bind(tenantController));
router.get('/:id', tenantController.getTenant.bind(tenantController));

export default router;
