import prisma from '../db/prisma';
import { AppError } from '../middleware/error';
import tenantService from './tenant.service';

export interface CreateMaterialDto {
  name: string;
  unit: string;
  currentStock?: number;
}

export class MaterialService {
  /**
   * Create a new material (tenant-scoped)
   * Enforces plan limits: FREE = max 5 materials, PRO = unlimited
   */
  async createMaterial(tenantId: string, data: CreateMaterialDto) {
    // Check plan limits
    const canAdd = await tenantService.canAddMaterial(tenantId);
    
    if (!canAdd) {
      throw new AppError(
        'Material limit reached. Upgrade to PRO plan to add more materials.',
        403
      );
    }

    const material = await prisma.material.create({
      data: {
        tenantId,
        name: data.name,
        unit: data.unit,
        currentStock: data.currentStock || 0
      }
    });

    return material;
  }

  /**
   * Get all materials for a tenant
   */
  async getMaterialsByTenant(tenantId: string) {
    const materials = await prisma.material.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' }
    });

    return materials;
  }

  /**
   * Get a single material by ID (tenant-scoped)
   * Includes all transactions for this material
   */
  async getMaterialById(tenantId: string, materialId: string) {
    const material = await prisma.material.findFirst({
      where: {
        id: materialId,
        tenantId // Enforce tenant isolation
      },
      include: {
        transactions: {
          orderBy: { createdAt: 'desc' }
        }
      }
    });

    if (!material) {
      throw new AppError('Material not found or access denied', 404);
    }

    return material;
  }

  /**
   * Update material stock
   */
  async updateStock(tenantId: string, materialId: string, newStock: number) {
    // Verify material belongs to tenant
    await this.getMaterialById(tenantId, materialId);

    const material = await prisma.material.update({
      where: { id: materialId },
      data: { currentStock: newStock }
    });

    return material;
  }
}

export default new MaterialService();
