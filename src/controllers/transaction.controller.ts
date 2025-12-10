import { Response, NextFunction } from 'express';
import { TenantRequest } from '../middleware/tenant';
import transactionService from '../services/transaction.service';

export class TransactionController {
  /**
   * POST /materials/:id/transactions - Create a transaction (IN/OUT) and update stock
   */
  async createTransaction(
    req: TenantRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { id: materialId } = req.params;
      const { quantity, type } = req.body;
      const tenantId = req.tenantId!;

      // Validation
      if (!quantity || typeof quantity !== 'number' || quantity <= 0) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Quantity is required and must be a positive number'
        });
        return;
      }

      if (!type || !['IN', 'OUT'].includes(type)) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Type is required and must be either IN or OUT'
        });
        return;
      }

      const result = await transactionService.createTransaction(
        tenantId,
        materialId,
        { quantity, type }
      );

      res.status(201).json({
        message: 'Transaction created successfully',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /transactions - Get all transactions for tenant
   */
  async getTransactions(
    req: TenantRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const tenantId = req.tenantId!;

      const transactions = await transactionService.getTransactionsByTenant(tenantId);

      res.status(200).json({
        data: transactions,
        count: transactions.length
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /transactions/:id - Get transaction by ID with material details
   */
  async getTransactionById(
    req: TenantRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;

      const transaction = await transactionService.getTransactionById(tenantId, id);

      res.status(200).json({
        data: transaction
      });
    } catch (error) {
      next(error);
    }
  }
}

export default new TransactionController();
