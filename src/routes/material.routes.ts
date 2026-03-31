import { Router } from 'express';
import materialController from '../controllers/material.controller';
import { resolveTenant } from '../middleware/tenant';
import { validateBody } from '../middleware/validate';
import { createMaterialSchema } from '../schemas/material.schema';

const router = Router();

router.use(resolveTenant);

router.post('/', validateBody(createMaterialSchema), materialController.createMaterial.bind(materialController));
router.get('/', materialController.getMaterials.bind(materialController));
router.get('/:id', materialController.getMaterialById.bind(materialController));

export default router;
