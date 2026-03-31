import { Router } from 'express';
import transactionController from '../controllers/transaction.controller';
import { resolveTenant } from '../middleware/tenant';
import { validateBody } from '../middleware/validate';
import { createTransactionSchema } from '../schemas/transaction.schema';

const router = Router();

router.use(resolveTenant);

router.post(
  '/materials/:id/transactions',
  validateBody(createTransactionSchema),
  transactionController.createTransaction.bind(transactionController)
);

router.get('/transactions', transactionController.getTransactions.bind(transactionController));
router.get('/transactions/:id', transactionController.getTransactionById.bind(transactionController));

export default router;
