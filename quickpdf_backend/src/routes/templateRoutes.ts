import { Router } from 'express';
import { body, query, param } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { authMiddleware, AuthenticatedRequest } from '@/middleware/authMiddleware';
import { 
  requirePermission, 
  Permission, 
  RBACRequest,
  requireOwnership 
} from '@/middleware/rbacMiddleware';
import { TemplateService } from '@/services/templateService';
import { TemplateModel } from '@/models/Template';
import { TemplateDataInjectionService } from '@/services/templateDataInjectionService';
import { MarketplaceService } from '@/services/marketplaceService';
import { templateSanitizationMiddleware } from '@/middleware/sanitizationMiddleware';

const router = Router();

// Get all templates (public)
router.get('/',
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('category').optional().isString().withMessage('Category must be a string'),
    query('search').optional().isString().withMessage('Search must be a string'),
    query('sort').optional().isIn(['rating', 'downloads', 'price', 'date', 'popularity']).withMessage('Invalid sort option'),
    query('order').optional().isIn(['asc', 'desc']).withMessage('Order must be asc or desc'),
    query('priceMin').optional().isFloat({ min: 0 }).withMessage('Minimum price must be non-negative'),
    query('priceMax').optional().isFloat({ min: 0 }).withMessage('Maximum price must be non-negative'),
    query('rating').optional().isFloat({ min: 0, max: 5 }).withMessage('Rating must be between 0 and 5'),
    query('featured').optional().isBoolean().withMessage('Featured must be a boolean'),
    query('verified').optional().isBoolean().withMessage('Verified must be a boolean'),
    query('tags').optional().isString().withMessage('Tags must be a string'),
  ],
  validateRequest([
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('category').optional().isString(),
    query('search').optional().isString(),
    query('sort').optional().isIn(['rating', 'downloads', 'price', 'date', 'popularity']),
    query('order').optional().isIn(['asc', 'desc']),
    query('priceMin').optional().isFloat({ min: 0 }),
    query('priceMax').optional().isFloat({ min: 0 }),
    query('rating').optional().isFloat({ min: 0, max: 5 }),
    query('featured').optional().isBoolean(),
    query('verified').optional().isBoolean(),
    query('tags').optional().isString(),
  ]),
  asyncHandler(async (req, res) => {
    try {
      const filters = {
        search: req.query.search as string,
        categoryId: req.query.category as string,
        priceMin: req.query.priceMin ? parseFloat(req.query.priceMin as string) : undefined,
        priceMax: req.query.priceMax ? parseFloat(req.query.priceMax as string) : undefined,
        rating: req.query.rating ? parseFloat(req.query.rating as string) : undefined,
        isFeatured: req.query.featured ? req.query.featured === 'true' : undefined,
        isVerified: req.query.verified ? req.query.verified === 'true' : undefined,
        tags: req.query.tags ? (req.query.tags as string).split(',') : undefined,
      };

      const options = {
        page: parseInt(req.query.page as string) || 1,
        limit: parseInt(req.query.limit as string) || 20,
        sortBy: req.query.sort as 'rating' | 'downloads' | 'price' | 'date' | 'popularity' || 'date',
        sortOrder: req.query.order as 'asc' | 'desc' || 'desc',
      };

      const result = await MarketplaceService.searchTemplates(filters, options);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to search templates',
      });
    }
  })
);

// Get template by ID (public)
router.get('/:id',
  param('id').isUUID().withMessage('Invalid template ID'),
  validateRequest([param('id').isUUID()]),
  asyncHandler(async (req, res) => {
    try {
      const template = await TemplateModel.findById(req.params.id);
      
      if (!template) {
        return res.status(404).json({
          success: false,
          message: 'Template not found',
        });
      }

      res.status(200).json({
        success: true,
        data: {
          template,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to get template',
      });
    }
  })
);

// Create new template (creator only)
router.post('/',
  authMiddleware,
  requirePermission(Permission.CREATE_TEMPLATE),
  templateSanitizationMiddleware,
  [
    body('title').trim().isLength({ min: 5, max: 100 }).withMessage('Title must be between 5 and 100 characters'),
    body('description').trim().isLength({ min: 20, max: 500 }).withMessage('Description must be between 20 and 500 characters'),
    body('categoryId').isUUID().withMessage('Valid category ID is required'),
    body('body').trim().isLength({ min: 10 }).withMessage('Template body is required'),
    body('placeholders').isObject().withMessage('Placeholders must be an object'),
    body('price').isFloat({ min: 0, max: 500 }).withMessage('Price must be between 0 and 500'),
  ],
  validateRequest([
    body('title').trim().isLength({ min: 5, max: 100 }),
    body('description').trim().isLength({ min: 20, max: 500 }),
    body('categoryId').isUUID(),
    body('body').trim().isLength({ min: 10 }),
    body('placeholders').isObject(),
    body('price').isFloat({ min: 0, max: 500 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    try {
      const template = await TemplateService.createTemplate(req.user!.id, {
        title: req.body.title,
        description: req.body.description,
        categoryId: req.body.categoryId,
        subCategoryId: req.body.subCategoryId,
        body: req.body.body,
        placeholders: req.body.placeholders,
        price: req.body.price,
        currency: req.body.currency || 'TRY'
      });

      res.status(201).json({
        success: true,
        message: 'Template created successfully and submitted for review',
        data: {
          template,
        },
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to create template',
      });
    }
  })
);

// Update template (creator only, own templates)
router.put('/:id',
  authMiddleware,
  requirePermission(Permission.UPDATE_OWN_TEMPLATE),
  requireOwnership(async (req) => {
    // TODO: Get template owner from database
    return req.user!.id; // Mock for now
  }),
  templateSanitizationMiddleware,
  param('id').isUUID().withMessage('Invalid template ID'),
  [
    body('title').optional().trim().isLength({ min: 5, max: 100 }).withMessage('Title must be between 5 and 100 characters'),
    body('description').optional().trim().isLength({ min: 20, max: 500 }).withMessage('Description must be between 20 and 500 characters'),
    body('body').optional().trim().isLength({ min: 10 }).withMessage('Template body is required'),
    body('placeholders').optional().isObject().withMessage('Placeholders must be an object'),
    body('price').optional().isFloat({ min: 0, max: 500 }).withMessage('Price must be between 0 and 500'),
  ],
  validateRequest([
    param('id').isUUID(),
    body('title').optional().trim().isLength({ min: 5, max: 100 }),
    body('description').optional().trim().isLength({ min: 20, max: 500 }),
    body('body').optional().trim().isLength({ min: 10 }),
    body('placeholders').optional().isObject(),
    body('price').optional().isFloat({ min: 0, max: 500 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    // TODO: Update template in database (check ownership)
    res.status(200).json({
      success: true,
      message: 'Template updated successfully',
      data: {
        template: {
          id: req.params.id,
          ...req.body,
          updatedAt: new Date().toISOString(),
        },
      },
    });
  })
);

// Delete template (creator only, own templates)
router.delete('/:id',
  authMiddleware,
  requirePermission(Permission.DELETE_OWN_TEMPLATE),
  requireOwnership(async (req) => {
    // TODO: Get template owner from database
    return req.user!.id; // Mock for now
  }),
  param('id').isUUID().withMessage('Invalid template ID'),
  validateRequest([param('id').isUUID()]),
  asyncHandler(async (req: RBACRequest, res) => {
    // TODO: Delete template from database (check ownership)
    res.status(200).json({
      success: true,
      message: 'Template deleted successfully',
    });
  })
);

// Get template form configuration (public)
router.get('/:id/form',
  param('id').isUUID().withMessage('Invalid template ID'),
  validateRequest([param('id').isUUID()]),
  asyncHandler(async (req, res) => {
    try {
      const template = await TemplateModel.findById(req.params.id);
      
      if (!template) {
        return res.status(404).json({
          success: false,
          message: 'Template not found',
        });
      }

      const formConfig = TemplateService.generateFormConfig(template);

      res.status(200).json({
        success: true,
        data: {
          formConfig,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to generate form configuration',
      });
    }
  })
);

// Process template with user data (authenticated)
router.post('/:id/process',
  authMiddleware,
  param('id').isUUID().withMessage('Invalid template ID'),
  body('userData').isObject().withMessage('User data must be an object'),
  validateRequest([
    param('id').isUUID(),
    body('userData').isObject(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    try {
      const template = await TemplateModel.findById(req.params.id);
      
      if (!template) {
        return res.status(404).json({
          success: false,
          message: 'Template not found',
        });
      }

      const processedTemplate = TemplateDataInjectionService.processTemplate(template, req.body.userData);

      res.status(200).json({
        success: true,
        data: {
          processedTemplate,
        },
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to process template',
      });
    }
  })
);

// Generate preview of template with user data (authenticated)
router.post('/:id/preview',
  authMiddleware,
  param('id').isUUID().withMessage('Invalid template ID'),
  body('userData').isObject().withMessage('User data must be an object'),
  validateRequest([
    param('id').isUUID(),
    body('userData').isObject(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    try {
      const template = await TemplateModel.findById(req.params.id);
      
      if (!template) {
        return res.status(404).json({
          success: false,
          message: 'Template not found',
        });
      }

      const preview = TemplateDataInjectionService.generatePreview(template, req.body.userData);

      res.status(200).json({
        success: true,
        data: {
          preview,
        },
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to generate preview',
      });
    }
  })
);

// Validate template for data injection (creator only)
router.get('/:id/validate',
  authMiddleware,
  requirePermission(Permission.CREATE_TEMPLATE),
  param('id').isUUID().withMessage('Invalid template ID'),
  validateRequest([param('id').isUUID()]),
  asyncHandler(async (req: RBACRequest, res) => {
    try {
      const template = await TemplateModel.findById(req.params.id);
      
      if (!template) {
        return res.status(404).json({
          success: false,
          message: 'Template not found',
        });
      }

      const validation = TemplateDataInjectionService.validateTemplateForInjection(template);

      res.status(200).json({
        success: true,
        data: {
          validation,
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to validate template',
      });
    }
  })
);

// Get template preview with sample data (public)
router.get('/:id/preview',
  param('id').isUUID().withMessage('Invalid template ID'),
  validateRequest([param('id').isUUID()]),
  asyncHandler(async (req, res) => {
    try {
      const preview = await MarketplaceService.generateTemplatePreview(req.params.id);

      res.status(200).json({
        success: true,
        data: {
          preview,
        },
      });
    } catch (error) {
      res.status(404).json({
        success: false,
        message: error instanceof Error ? error.message : 'Failed to generate preview',
      });
    }
  })
);

// Get my templates (creator only)
router.get('/my/templates',
  authMiddleware,
  requirePermission(Permission.CREATE_TEMPLATE),
  asyncHandler(async (req: RBACRequest, res) => {
    // TODO: Get user's templates from database
    res.status(200).json({
      success: true,
      data: {
        templates: [],
      },
    });
  })
);

export default router;