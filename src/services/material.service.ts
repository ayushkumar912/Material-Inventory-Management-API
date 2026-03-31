import prisma from '../db/prisma';
import { AppError } from '../middleware/error';
import tenantService from './tenant.service';
import { PaginationParams } from '../utils/pagination';

export interface CreateMaterialDto {
  name: string;
  unit: string;
  currentStock?: number;
}

export class MaterialService {
  async createMaterial(tenantId: string, data: CreateMaterialDto) {
    const canAdd = await tenantService.canAddMaterial(tenantId);

    if (!canAdd) {
      throw new AppError('Material limit reached. Upgrade to PRO plan to add more materials.', 403);
    }

    const material = await prisma.material.create({
      data: { tenantId, name: data.name, unit: data.unit, currentStock: data.currentStock || 0 }
    });

    return material;
  }

  async getMaterialsByTenant(tenantId: string, pagination: PaginationParams) {
    const [materials, total] = await Promise.all([
      prisma.material.findMany({
        where: { tenantId },
        orderBy: { createdAt: 'desc' },
        skip: pagination.skip,
        take: pagination.limit
      }),
      prisma.material.count({ where: { tenantId } })
    ]);

    return { data: materials, total };
  }

  async getMaterialById(tenantId: string, materialId: string) {
    const material = await prisma.material.findFirst({
      where: { id: materialId, tenantId },
      include: { transactions: { orderBy: { createdAt: 'desc' } } }
    });

    if (!material) {
      throw new AppError('Material not found or access denied', 404);
    }

    return material;
  }

  async updateStock(tenantId: string, materialId: string, newStock: number) {
    await this.getMaterialById(tenantId, materialId);

    const material = await prisma.material.update({
      where: { id: materialId },
      data: { currentStock: newStock }
    });

    return material;
  }
}

export default new MaterialService();
