import { Router } from 'express';
import { body, param, query } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { authMiddleware, AuthenticatedRequest } from '@/middleware/authMiddleware';
import { MarketplaceService } from '@/services/marketplaceService';

const router = Router();

// Get categories (public)
router.get('/categories',
  asyncHandler(async (req, res) => {
    try {
      const categories = await MarketplaceService.getCategories();

      res.status(200).json({
        success: true,
        data: {
          categories,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to get categories',
      });
    }
  })
);

// Purchase template (authenticated)
router.post('/purchase',
  authMiddleware,
  [
    body('templateId').isUUID().withMessage('Valid template ID is required'),
    body('paymentMethod').isIn(['stripe', 'iyzico']).withMessage('Invalid payment method'),
    body('paymentToken').notEmpty().withMessage('Payment token is required'),
  ],
  validateRequest([
    body('templateId').isUUID(),
    body('paymentMethod').isIn(['stripe', 'iyzico']),
    body('paymentToken').notEmpty(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Process payment and grant template access
    res.status(200).json({
      success: true,
      message: 'Template purchased successfully',
      data: {
        purchaseId: 'mock_purchase_id',
        templateId: req.body.templateId,
        amount: 25.0,
        currency: 'TRY',
        transactionId: 'mock_transaction_id',
        purchasedAt: new Date().toISOString(),
      },
    });
  })
);

// Get user purchases (authenticated)
router.get('/purchases',
  authMiddleware,
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Get user purchases from database
    const mockPurchases = [
      {
        id: 'purchase_1',
        templateId: 'template_2',
        templateTitle: 'İş Sözleşmesi',
        amount: 25.0,
        currency: 'TRY',
        status: 'completed',
        purchasedAt: new Date().toISOString(),
      },
    ];

    res.status(200).json({
      success: true,
      data: {
        purchases: mockPurchases,
      },
    });
  })
);

// Rate template (authenticated, must have purchased)
router.post('/rate',
  authMiddleware,
  [
    body('templateId').isUUID().withMessage('Valid template ID is required'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
    body('comment').optional().trim().isLength({ max: 500 }).withMessage('Comment must be less than 500 characters'),
  ],
  validateRequest([
    body('templateId').isUUID(),
    body('rating').isInt({ min: 1, max: 5 }),
    body('comment').optional().trim().isLength({ max: 500 }),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    try {
      const rating = await MarketplaceService.rateTemplate(
        req.user!.id,
        req.body.templateId,
        req.body.rating,
        req.body.comment
      );

      res.status(200).json({
        success: true,
        message: 'Rating submitted successfully',
        data: {
          rating,
        },
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to submit rating',
      });
    }
  })
);

// Get template ratings (public)
router.get('/templates/:templateId/ratings',
  param('templateId').isUUID().withMessage('Invalid template ID'),
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  ],
  validateRequest([
    param('templateId').isUUID(),
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 50 }),
  ]),
  asyncHandler(async (req, res) => {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      
      const result = await MarketplaceService.getTemplateRatings(
        req.params.templateId,
        page,
        limit
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to get template ratings',
      });
    }
  })
);

// Get featured templates (public)
router.get('/featured',
  [
    query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  ],
  validateRequest([
    query('limit').optional().isInt({ min: 1, max: 50 }),
  ]),
  asyncHandler(async (req, res) => {
    try {
      const limit = parseInt(req.query.limit as string) || 10;
      const templates = await MarketplaceService.getFeaturedTemplates(limit);

      res.status(200).json({
        success: true,
        data: {
          templates,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to get featured templates',
      });
    }
  })
);

// Get popular templates (public)
router.get('/popular',
  [
    query('period').optional().isIn(['7d', '30d', '90d', 'all']).withMessage('Invalid period'),
    query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  ],
  validateRequest([
    query('period').optional().isIn(['7d', '30d', '90d', 'all']),
    query('limit').optional().isInt({ min: 1, max: 50 }),
  ]),
  asyncHandler(async (req, res) => {
    try {
      const period = req.query.period as '7d' | '30d' | '90d' | 'all' || '30d';
      const limit = parseInt(req.query.limit as string) || 10;
      
      const templates = await MarketplaceService.getPopularTemplates(period, limit);

      res.status(200).json({
        success: true,
        data: {
          templates,
          period,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to get popular templates',
      });
    }
  })
);

// Get creator earnings (authenticated, creator only)
router.get('/earnings',
  authMiddleware,
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Get creator earnings from database
    res.status(200).json({
      success: true,
      data: {
        earnings: {
          totalEarnings: 0.0,
          availableBalance: 0.0,
          pendingBalance: 0.0,
          thisMonthEarnings: 0.0,
          totalSales: 0,
          templates: [],
        },
      },
    });
  })
);

export default router;