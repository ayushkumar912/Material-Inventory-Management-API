import { Request, Response, NextFunction } from 'express';
import tenantService from '../services/tenant.service';
import { sendSuccess, sendCreated } from '../utils/response';

export class TenantController {
  async createTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, plan } = req.body;
      const tenant = await tenantService.createTenant({ name, plan });
      sendCreated(res, tenant, 'Tenant created successfully');
    } catch (error) {
      next(error);
    }
  }

  async getTenant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const tenant = await tenantService.getTenantById(id);
      sendSuccess(res, tenant);
    } catch (error) {
      next(error);
    }
  }
}

export default new TenantController();
