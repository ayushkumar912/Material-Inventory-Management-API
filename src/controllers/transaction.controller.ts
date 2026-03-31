import { Response, NextFunction } from 'express';
import { TenantRequest } from '../middleware/tenant';
import transactionService from '../services/transaction.service';
import { sendSuccess, sendCreated, sendList } from '../utils/response';
import { parsePagination, buildMeta } from '../utils/pagination';

export class TransactionController {
  async createTransaction(req: TenantRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id: materialId } = req.params;
      const { quantity, type } = req.body;
      const tenantId = req.tenantId!;
      const result = await transactionService.createTransaction(tenantId, materialId, { quantity, type });
      sendCreated(res, result, 'Transaction created successfully');
    } catch (error) {
      next(error);
    }
  }

  async getTransactions(req: TenantRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const tenantId = req.tenantId!;
      const pagination = parsePagination(req.query);
      const { data, total } = await transactionService.getTransactionsByTenant(tenantId, pagination);
      sendList(res, data, buildMeta(total, pagination.page, pagination.limit));
    } catch (error) {
      next(error);
    }
  }

  async getTransactionById(req: TenantRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;
      const transaction = await transactionService.getTransactionById(tenantId, id);
      sendSuccess(res, transaction);
    } catch (error) {
      next(error);
    }
  }
}

export default new TransactionController();
