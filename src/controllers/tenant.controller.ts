import { Request, Response, NextFunction } from 'express';
import tenantService from '../services/tenant.service';
import { Plan } from '@prisma/client';

export class TenantController {
  /**
   * POST /tenants - Create a new tenant
   */
  async createTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, plan } = req.body;

      // Validation
      if (!name || typeof name !== 'string' || name.trim().length === 0) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Name is required and must be a non-empty string'
        });
        return;
      }

      if (plan && !Object.values(Plan).includes(plan)) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Plan must be either FREE or PRO'
        });
        return;
      }

      const tenant = await tenantService.createTenant({
        name: name.trim(),
        plan: plan || Plan.FREE
      });

      res.status(201).json({
        message: 'Tenant created successfully',
        data: tenant
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /tenants/:id - Get tenant by ID
   */
  async getTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;

      const tenant = await tenantService.getTenantById(id);

      res.status(200).json({
        data: tenant
      });
    } catch (error) {
      next(error);
    }
  }
}

export default new TenantController();
