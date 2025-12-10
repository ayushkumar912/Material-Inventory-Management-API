import { Router } from 'express';
import transactionController from '../controllers/transaction.controller';
import { resolveTenant } from '../middleware/tenant';

const router = Router();

// Apply tenant middleware to all transaction routes
router.use(resolveTenant);

/**
 * POST /materials/:id/transactions - Create transaction (IN/OUT) and update stock
 * Requires x-tenant-id header
 * Enforces tenant isolation - can only create transactions for own materials
 */
router.post(
  '/materials/:id/transactions',
  transactionController.createTransaction.bind(transactionController)
);

/**
 * GET /transactions - Get all transactions for tenant
 * Requires x-tenant-id header
 */
router.get('/transactions', transactionController.getTransactions.bind(transactionController));

/**
 * GET /transactions/:id - Get transaction by ID with material details
 * Requires x-tenant-id header
 */
router.get('/transactions/:id', transactionController.getTransactionById.bind(transactionController));

export default router;
