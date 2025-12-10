import express, { Express } from 'express';
import tenantRoutes from './routes/tenant.routes';
import userRoutes from './routes/user.routes';
import materialRoutes from './routes/material.routes';
import transactionRoutes from './routes/transaction.routes';
import { errorHandler, notFoundHandler } from './middleware/error';

const app: Express = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'material-inventory-api'
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
