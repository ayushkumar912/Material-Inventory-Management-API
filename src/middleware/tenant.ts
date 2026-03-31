import { Request, Response, NextFunction } from 'express';
import prisma from '../db/prisma';

export interface TenantRequest extends Request {
  tenantId?: string;
}

/**
 * Middleware to extract and validate tenant from x-tenant-id header
 * Ensures all requests are associated with a valid tenant
 */
export const resolveTenant = async (
  req: TenantRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const tenantId = req.headers['x-tenant-id'] as string;

    if (!tenantId) {
      res.status(400).json({
        success: false,
        error: 'Missing tenant identifier',
        message: 'x-tenant-id header is required'
      });
      return;
    }

    // Validate tenant exists
    const tenant = await prisma.tenant.findUnique({
      where: { id: tenantId }
    });

    if (!tenant) {
      res.status(404).json({
        success: false,
        error: 'Tenant not found',
        message: `No tenant found with id: ${tenantId}`
      });
      return;
    }

    // Attach tenant ID to request for downstream use
    req.tenantId = tenantId;
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Optional tenant middleware for routes that don't require tenant context
 * (e.g., tenant creation endpoint)
 */
export const optionalTenant = (
  req: TenantRequest,
  res: Response,
  next: NextFunction
): void => {
  const tenantId = req.headers['x-tenant-id'] as string;
  if (tenantId) {
    req.tenantId = tenantId;
  }
  next();
};
