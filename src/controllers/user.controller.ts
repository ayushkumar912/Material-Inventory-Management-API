import { Request, Response, NextFunction } from 'express';
import { userService } from '../services/user.service';
import { TenantRequest } from '../middleware/tenant';

export class UserController {
  async createUser(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { email, name, role } = req.body;
      const tenantId = req.tenantId!;

      if (!email || !name) {
        return res.status(400).json({
          error: 'Validation error',
          message: 'Email and name are required'
        });
      }

      // Validate role if provided
      if (role && !['ADMIN', 'USER'].includes(role)) {
        return res.status(400).json({
          error: 'Validation error',
          message: 'Role must be either ADMIN or USER'
        });
      }

      const user = await userService.createUser({
        email,
        name,
        role: role || 'USER',
        tenantId
      });

      res.status(201).json({
        message: 'User created successfully',
        data: user
      });
    } catch (error) {
      next(error);
    }
  }

  async getUsers(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const tenantId = req.tenantId!;
      const users = await userService.getUsersByTenant(tenantId);

      res.json({
        data: users,
        count: users.length
      });
    } catch (error) {
      next(error);
    }
  }

  async getUserById(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;

      const user = await userService.getUserById(id, tenantId);

      if (!user) {
        return res.status(404).json({
          error: 'User not found or access denied',
          statusCode: 404
        });
      }

      res.json({ data: user });
    } catch (error) {
      next(error);
    }
  }

  async updateUser(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { name, role } = req.body;
      const tenantId = req.tenantId!;

      // Validate role if provided
      if (role && !['ADMIN', 'USER'].includes(role)) {
        return res.status(400).json({
          error: 'Validation error',
          message: 'Role must be either ADMIN or USER'
        });
      }

      const user = await userService.updateUser(id, tenantId, {
        name,
        role
      });

      res.json({
        message: 'User updated successfully',
        data: user
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteUser(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;

      await userService.deleteUser(id, tenantId);

      res.json({
        message: 'User deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
