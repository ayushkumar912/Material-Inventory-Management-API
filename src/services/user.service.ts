import prisma from '../db/prisma';
import { AppError } from '../middleware/error';
import { PaginationParams } from '../utils/pagination';

interface CreateUserInput {
  email: string;
  name: string;
  role: 'ADMIN' | 'USER';
  tenantId: string;
}

interface UpdateUserInput {
  name?: string;
  role?: 'ADMIN' | 'USER';
}

class UserService {
  async createUser(input: CreateUserInput) {
    const { email, name, role, tenantId } = input;

    try {
      const user = await prisma.user.create({
        data: { email, name, role, tenantId }
      });

      return user;
    } catch (error: any) {
      if (error.code === 'P2002') {
        throw new AppError('Email already exists', 409);
      }
      throw error;
    }
  }

  async getUsersByTenant(tenantId: string, pagination: PaginationParams) {
    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where: { tenantId },
        select: { id: true, email: true, name: true, role: true, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip: pagination.skip,
        take: pagination.limit
      }),
      prisma.user.count({ where: { tenantId } })
    ]);

    return { data: users, total };
  }

  async getUserById(userId: string, tenantId: string) {
    const user = await prisma.user.findFirst({
      where: { id: userId, tenantId },
      select: { id: true, email: true, name: true, role: true, tenantId: true, createdAt: true }
    });

    return user;
  }

  async updateUser(userId: string, tenantId: string, updates: UpdateUserInput) {
    const user = await prisma.user.findFirst({ where: { id: userId, tenantId } });

    if (!user) {
      throw new AppError('User not found', 404);
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(updates.name && { name: updates.name }),
        ...(updates.role && { role: updates.role })
      },
      select: { id: true, email: true, name: true, role: true, updatedAt: true }
    });

    return updated;
  }

  async deleteUser(userId: string, tenantId: string) {
    const user = await prisma.user.findFirst({ where: { id: userId, tenantId } });

    if (!user) {
      throw new AppError('User not found', 404);
    }

    await prisma.user.delete({ where: { id: userId } });
  }
}

export const userService = new UserService();
