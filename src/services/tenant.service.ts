import prisma from '../db/prisma';
import { AppError } from '../middleware/error';
import { Plan } from '@prisma/client';

export interface CreateTenantDto {
  name: string;
  plan?: Plan;
}

export class TenantService {
  /**
   * Create a new tenant
   */
  async createTenant(data: CreateTenantDto) {
    const tenant = await prisma.tenant.create({
      data: {
        name: data.name,
        plan: data.plan || Plan.FREE
      }
    });

    return tenant;
  }

  /**
   * Get tenant by ID
   */
  async getTenantById(tenantId: string) {
    const tenant = await prisma.tenant.findUnique({
      where: { id: tenantId }
    });

    if (!tenant) {
      throw new AppError('Tenant not found', 404);
    }

    return tenant;
  }

  /**
   * Check if tenant can add more materials based on plan limits
   */
  async canAddMaterial(tenantId: string): Promise<boolean> {
    const tenant = await this.getTenantById(tenantId);
    
    if (tenant.plan === Plan.PRO) {
      return true;
    }

    // FREE plan: max 5 materials
    const materialCount = await prisma.material.count({
      where: { tenantId }
    });

    return materialCount < 5;
  }
}

export default new TenantService();
