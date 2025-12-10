import { Response, NextFunction } from 'express';
import { TenantRequest } from '../middleware/tenant';
import materialService from '../services/material.service';

export class MaterialController {
  /**
   * POST /materials - Create a new material (tenant-scoped)
   */
  async createMaterial(
    req: TenantRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { name, unit, currentStock } = req.body;
      const tenantId = req.tenantId!;

      // Validation
      if (!name || typeof name !== 'string' || name.trim().length === 0) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Name is required and must be a non-empty string'
        });
        return;
      }

      if (!unit || typeof unit !== 'string' || unit.trim().length === 0) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Unit is required and must be a non-empty string'
        });
        return;
      }

      if (currentStock !== undefined && (typeof currentStock !== 'number' || currentStock < 0)) {
        res.status(400).json({
          error: 'Validation error',
          message: 'Current stock must be a non-negative number'
        });
        return;
      }

      const material = await materialService.createMaterial(tenantId, {
        name: name.trim(),
        unit: unit.trim(),
        currentStock: currentStock || 0
      });

      res.status(201).json({
        message: 'Material created successfully',
        data: material
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /materials - List all materials for tenant
   */
  async getMaterials(
    req: TenantRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const tenantId = req.tenantId!;

      const materials = await materialService.getMaterialsByTenant(tenantId);

      res.status(200).json({
        data: materials,
        count: materials.length
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /materials/:id - Get material by ID with transactions (tenant-scoped)
   */
  async getMaterialById(
    req: TenantRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;

      const material = await materialService.getMaterialById(tenantId, id);

      res.status(200).json({
        data: material
      });
    } catch (error) {
      next(error);
    }
  }
}

export default new MaterialController();
