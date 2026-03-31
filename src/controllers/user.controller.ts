import { Response, NextFunction } from 'express';
import { userService } from '../services/user.service';
import { TenantRequest } from '../middleware/tenant';
import { sendSuccess, sendCreated, sendList, sendMessage } from '../utils/response';
import { parsePagination, buildMeta } from '../utils/pagination';

export class UserController {
  async createUser(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { email, name, role } = req.body;
      const tenantId = req.tenantId!;
      const user = await userService.createUser({ email, name, role: role || 'USER', tenantId });
      sendCreated(res, user, 'User created successfully');
    } catch (error) {
      next(error);
    }
  }

  async getUsers(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const tenantId = req.tenantId!;
      const pagination = parsePagination(req.query);
      const { data, total } = await userService.getUsersByTenant(tenantId, pagination);
      sendList(res, data, buildMeta(total, pagination.page, pagination.limit));
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
        res.status(404).json({ success: false, error: 'User not found or access denied' });
        return;
      }

      sendSuccess(res, user);
    } catch (error) {
      next(error);
    }
  }

  async updateUser(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { name, role } = req.body;
      const tenantId = req.tenantId!;
      const user = await userService.updateUser(id, tenantId, { name, role });
      sendSuccess(res, user, 'User updated successfully');
    } catch (error) {
      next(error);
    }
  }

  async deleteUser(req: TenantRequest, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const tenantId = req.tenantId!;
      await userService.deleteUser(id, tenantId);
      sendMessage(res, 'User deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

export const userController = new UserController();
