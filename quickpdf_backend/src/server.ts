import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import { logger } from '@/utils/logger';
import { testConnection, closePool } from '@/config/database';
import { migrationRunner } from '@/utils/migrationRunner';
import { errorHandler } from '@/middleware/errorHandler';
import { notFoundHandler } from '@/middleware/notFoundHandler';
import { authMiddleware } from '@/middleware/authMiddleware';
import { validateRequest } from '@/middleware/validateRequest';
import { 
  sanitizationMiddleware, 
  sqlInjectionPreventionMiddleware 
} from '@/middleware/sanitizationMiddleware';
import {
  securityHeadersMiddleware,
  csrfProtectionMiddleware,
  generateCSRFTokenMiddleware,
  securityLoggingMiddleware,
  requestSizeLimitMiddleware,
  ipRateLimitMiddleware,
  suspiciousActivityMiddleware,
} from '@/middleware/securityMiddleware';

// Routes
import authRoutes from '@/routes/authRoutes';
import userRoutes from '@/routes/userRoutes';
import templateRoutes from '@/routes/templateRoutes';
import pdfRoutes from '@/routes/pdfRoutes';
import marketplaceRoutes from '@/routes/marketplaceRoutes';
import adminRoutes from '@/routes/adminRoutes';
import paymentRoutes from '@/routes/paymentRoutes';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const API_VERSION = process.env.API_VERSION || 'v1';

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // We'll use our custom CSP
  hsts: false, // We'll use our custom HSTS
}));

// Enhanced security headers
app.use(securityHeadersMiddleware);

// Security logging
app.use(securityLoggingMiddleware);

// Suspicious activity detection
app.use(suspiciousActivityMiddleware);

// Request size limiting
app.use(requestSizeLimitMiddleware(10 * 1024 * 1024)); // 10MB limit

// IP-based rate limiting (more restrictive than the general rate limiter)
app.use(ipRateLimitMiddleware(15 * 60 * 1000, 50)); // 50 requests per 15 minutes per IP

// CORS configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'), // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Input sanitization middleware
app.use(sanitizationMiddleware({
  stripTags: true,
  maxLength: 10000,
  allowHTML: false
}));

// SQL injection prevention
app.use(sqlInjectionPreventionMiddleware);

// Compression middleware
app.use(compression());

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString(),
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
    version: process.env.npm_package_version || '1.0.0',
  });
});

// CSRF token endpoint
app.get('/api/csrf-token', generateCSRFTokenMiddleware);

// API routes
const apiRouter = express.Router();

// Public routes (no authentication required)
apiRouter.use('/auth', authRoutes);

// Protected routes (authentication required)
apiRouter.use('/users', authMiddleware, csrfProtectionMiddleware, userRoutes);
apiRouter.use('/templates', csrfProtectionMiddleware, templateRoutes); // Some endpoints public, some protected
apiRouter.use('/pdf', authMiddleware, csrfProtectionMiddleware, pdfRoutes);
apiRouter.use('/marketplace', csrfProtectionMiddleware, marketplaceRoutes); // Some endpoints public, some protected
apiRouter.use('/admin', authMiddleware, csrfProtectionMiddleware, adminRoutes); // Admin only
apiRouter.use('/payments', paymentRoutes); // Some endpoints public (webhook), some protected - no CSRF for webhooks

// Mount API routes
app.use(`/api/${API_VERSION}`, apiRouter);

// Serve static files
app.use('/uploads', express.static('uploads'));
app.use('/assets', express.static('assets'));

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// Initialize database and start server
async function startServer() {
  try {
    // Test database connection
    const connected = await testConnection();
    if (!connected) {
      logger.error('❌ Cannot connect to database. Server startup failed.');
      process.exit(1);
    }

    // Run migrations
    if (process.env.NODE_ENV !== 'test') {
      await migrationRunner.runMigrations();
    }

    // Start server
    app.listen(PORT, () => {
      logger.info(`🚀 QuickPDF Backend Server started on port ${PORT}`);
      logger.info(`📚 API Documentation: http://localhost:${PORT}/api/${API_VERSION}`);
      logger.info(`🏥 Health Check: http://localhost:${PORT}/health`);
      logger.info(`🌍 Environment: ${process.env.NODE_ENV}`);
    });
  } catch (error) {
    logger.error('💥 Server startup failed:', error);
    process.exit(1);
  }
}

// Graceful shutdown
const gracefulShutdown = async (signal: string) => {
  logger.info(`${signal} received, shutting down gracefully`);
  
  try {
    await closePool();
    logger.info('Database connections closed');
    process.exit(0);
  } catch (error) {
    logger.error('Error during graceful shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Start the server
startServer();

export default app;