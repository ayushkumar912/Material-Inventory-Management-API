import { Response, NextFunction } from 'express';
import { TenantRequest } from '../middleware/tenant';
import materialService from '../services/material.service';
import { sendSuccess, sendCreated, sendList } from '../utils/response';
import { parsePagination, buildMeta } from '../utils/pagination';

export class MaterialController {
  async createMaterial(req: TenantRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, unit, currentStock } = req.body;
      const tenantId = req.tenantId!;
      const material = await materialService.createMaterial(tenantId, { name, unit, currentStock });
      sendCreated(res, material, 'Material created successfully');
    } catch (error) {
      next(error);
    }
  }

  async getMaterials(req: TenantRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const tenantId = req.tenantId!;
      const pagination = parsePagination(req.query);
      const { data, total } = await materialService.getMaterialsByTenant(tenantId, pagination);
      sendList(res, data, buildMeta(total, pagination.page, pagination.limit));
    } catch (error) {
      next(error);
    }
  }

  async getMaterialById(req: TenantRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;
      const material = await materialService.getMaterialById(tenantId, id);
      sendSuccess(res, material);
    } catch (error) {
      next(error);
    }
  }
}

export default new MaterialController();
