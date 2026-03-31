import prisma from '../db/prisma';
import { AppError } from '../middleware/error';
import materialService from './material.service';
import { PaginationParams } from '../utils/pagination';

export interface CreateTransactionDto {
  quantity: number;
  type: 'IN' | 'OUT';
}

export class TransactionService {
  async createTransaction(tenantId: string, materialId: string, data: CreateTransactionDto) {
    const material = await materialService.getMaterialById(tenantId, materialId);

    let newStock = material.currentStock;

    if (data.type === 'IN') {
      newStock += data.quantity;
    } else {
      newStock -= data.quantity;

      if (newStock < 0) {
        throw new AppError(
          `Insufficient stock. Available: ${material.currentStock}, Requested: ${data.quantity}`,
          400
        );
      }
    }

    const result = await prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.create({
        data: { tenantId, materialId, quantity: data.quantity, type: data.type }
      });

      const updatedMaterial = await tx.material.update({
        where: { id: materialId },
        data: { currentStock: newStock }
      });

      return { transaction, material: updatedMaterial };
    });

    return result;
  }

  async getTransactionsByTenant(tenantId: string, pagination: PaginationParams) {
    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where: { tenantId },
        include: { material: { select: { name: true, unit: true } } },
        orderBy: { createdAt: 'desc' },
        skip: pagination.skip,
        take: pagination.limit
      }),
      prisma.transaction.count({ where: { tenantId } })
    ]);

    return { data: transactions, total };
  }

  async getTransactionsByMaterial(tenantId: string, materialId: string) {
    await materialService.getMaterialById(tenantId, materialId);

    const transactions = await prisma.transaction.findMany({
      where: { tenantId, materialId },
      orderBy: { createdAt: 'desc' }
    });

    return transactions;
  }

  async getTransactionById(tenantId: string, transactionId: string) {
    const transaction = await prisma.transaction.findFirst({
      where: { id: transactionId, tenantId },
      include: {
        material: { select: { id: true, name: true, unit: true, currentStock: true } }
      }
    });

    if (!transaction) {
      throw new AppError('Transaction not found or access denied', 404);
    }

    return transaction;
  }
}

export default new TransactionService();
