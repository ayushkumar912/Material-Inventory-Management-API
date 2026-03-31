import express, { Express } from 'express';
import tenantRoutes from './routes/tenant.routes';
import userRoutes from './routes/user.routes';
import materialRoutes from './routes/material.routes';
import transactionRoutes from './routes/transaction.routes';
import { errorHandler, notFoundHandler } from './middleware/error';
import prisma from './db/prisma';

const app: Express = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check with DB probe
app.get('/health', async (_req, res) => {
  let dbStatus: 'connected' | 'disconnected' = 'connected';
  try {
    await prisma.$queryRaw`SELECT 1`;
  } catch {
    dbStatus = 'disconnected';
  }

  const isHealthy = dbStatus === 'connected';
  res.status(isHealthy ? 200 : 503).json({
    success: true,
    data: {
      status: isHealthy ? 'ok' : 'degraded',
      db: dbStatus,
      timestamp: new Date().toISOString(),
      service: 'material-inventory-api'
    }
  });
});

// API Routes
app.use('/tenants', tenantRoutes);
app.use('/users', userRoutes);
app.use('/materials', materialRoutes);
app.use('/', transactionRoutes); // Handles /materials/:id/transactions and /transactions

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
