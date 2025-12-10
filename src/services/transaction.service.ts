import prisma from '../db/prisma';
import { AppError } from '../middleware/error';
import materialService from './material.service';

export interface CreateTransactionDto {
  quantity: number;
  type: 'IN' | 'OUT';
}

export class TransactionService {
  /**
   * Create a transaction (IN/OUT) and update material stock atomically
   * Enforces tenant isolation - cannot create transactions for other tenants' materials
   */
  async createTransaction(
    tenantId: string,
    materialId: string,
    data: CreateTransactionDto
  ) {
    // Verify material belongs to tenant
    const material = await materialService.getMaterialById(tenantId, materialId);

    // Calculate new stock
    let newStock = material.currentStock;
    
    if (data.type === 'IN') {
      newStock += data.quantity;
    } else if (data.type === 'OUT') {
      newStock -= data.quantity;
      
      // Prevent negative stock
      if (newStock < 0) {
        throw new AppError(
          `Insufficient stock. Available: ${material.currentStock}, Requested: ${data.quantity}`,
          400
        );
      }
    } else {
      throw new AppError('Invalid transaction type. Must be IN or OUT', 400);
    }

    // Use transaction to ensure atomicity
    const result = await prisma.$transaction(async (tx) => {
      // Create transaction record
      const transaction = await tx.transaction.create({
        data: {
          tenantId,
          materialId,
          quantity: data.quantity,
          type: data.type
        }
      });

      // Update material stock
      const updatedMaterial = await tx.material.update({
        where: { id: materialId },
        data: { currentStock: newStock }
      });

      return {
        transaction,
        material: updatedMaterial
      };
    });

    return result;
  }

  /**
   * Get all transactions for a tenant
   */
  async getTransactionsByTenant(tenantId: string) {
    const transactions = await prisma.transaction.findMany({
      where: { tenantId },
      include: {
        material: {
          select: {
            name: true,
            unit: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    return transactions;
  }

  /**
   * Get transactions for a specific material (tenant-scoped)
   */
  async getTransactionsByMaterial(tenantId: string, materialId: string) {
    // Verify material belongs to tenant
    await materialService.getMaterialById(tenantId, materialId);

    const transactions = await prisma.transaction.findMany({
      where: {
        tenantId,
        materialId
      },
      orderBy: { createdAt: 'desc' }
    });

    return transactions;
  }

  /**
   * Get a specific transaction by ID (tenant-scoped)
   */
  async getTransactionById(tenantId: string, transactionId: string) {
    const transaction = await prisma.transaction.findFirst({
      where: {
        id: transactionId,
        tenantId
      },
      include: {
        material: {
          select: {
            id: true,
            name: true,
            unit: true,
            currentStock: true
          }
        }
      }
    });

    if (!transaction) {
      throw new AppError('Transaction not found or access denied', 404);
    }

    return transaction;
  }
}

export default new TransactionService();
