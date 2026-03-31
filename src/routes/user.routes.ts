import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { resolveTenant } from '../middleware/tenant';
import { validateBody } from '../middleware/validate';
import { createUserSchema, updateUserSchema } from '../schemas/user.schema';

const router = Router();

router.use(resolveTenant);

router.post('/', validateBody(createUserSchema), userController.createUser.bind(userController));
router.get('/', userController.getUsers.bind(userController));
router.get('/:id', userController.getUserById.bind(userController));
router.put('/:id', validateBody(updateUserSchema), userController.updateUser.bind(userController));
router.delete('/:id', userController.deleteUser.bind(userController));

export default router;
