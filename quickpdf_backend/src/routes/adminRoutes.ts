import { Router } from 'express';
import { body, param, query } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { authMiddleware, AuthenticatedRequest } from '@/middleware/authMiddleware';
import { 
  requirePermission, 
  Permission, 
  RBACRequest 
} from '@/middleware/rbacMiddleware';
import { AdminService } from '@/services/adminService';
import { db } from '@/config/database';

const router = Router();
const adminService = new AdminService(db);

// All admin routes require authentication
router.use(authMiddleware);

// Get dashboard statistics
router.get('/dashboard',
  requirePermission(Permission.VIEW_ANALYTICS),
  asyncHandler(async (req: RBACRequest, res) => {
    const dashboardData = await adminService.getDashboardData();
    
    res.status(200).json({
      success: true,
      data: dashboardData,
    });
  })
);

// Get pending templates for review
router.get('/templates/pending',
  requirePermission(Permission.MODERATE_CONTENT),
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  ],
  validateRequest([
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    
    const result = await adminService.getPendingTemplates(page, limit);
    
    res.status(200).json({
      success: true,
      data: result,
    });
  })
);

// Approve template
router.put('/templates/:templateId/approve',
  requirePermission(Permission.MODERATE_CONTENT),
  param('templateId').isUUID().withMessage('Invalid template ID'),
  [
    body('isVerified').optional().isBoolean().withMessage('isVerified must be a boolean'),
    body('isFeatured').optional().isBoolean().withMessage('isFeatured must be a boolean'),
  ],
  validateRequest([
    param('templateId').isUUID(),
    body('isVerified').optional().isBoolean(),
    body('isFeatured').optional().isBoolean(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { templateId } = req.params;
    const { isVerified = false, isFeatured = false } = req.body;
    
    await adminService.approveTemplate(templateId, req.user!.id, isVerified, isFeatured);
    
    res.status(200).json({
      success: true,
      message: 'Template approved successfully',
      data: {
        templateId,
        status: 'published',
        isVerified,
        isFeatured,
        approvedBy: req.user?.id,
        approvedAt: new Date().toISOString(),
      },
    });
  })
);

// Get template details for review
router.get('/templates/:templateId/review',
  requirePermission(Permission.MODERATE_CONTENT),
  param('templateId').isUUID().withMessage('Invalid template ID'),
  validateRequest([
    param('templateId').isUUID(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { templateId } = req.params;
    
    const template = await adminService.getTemplateForReview(templateId);
    
    res.status(200).json({
      success: true,
      data: {
        template,
      },
    });
  })
);

// Validate template quality
router.get('/templates/:templateId/validate',
  requirePermission(Permission.MODERATE_CONTENT),
  param('templateId').isUUID().withMessage('Invalid template ID'),
  validateRequest([
    param('templateId').isUUID(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { templateId } = req.params;
    
    const validation = await adminService.validateTemplateQuality(templateId);
    
    res.status(200).json({
      success: true,
      data: validation,
    });
  })
);

// Reject template
router.put('/templates/:templateId/reject',
  requirePermission(Permission.MODERATE_CONTENT),
  param('templateId').isUUID().withMessage('Invalid template ID'),
  body('reason').trim().isLength({ min: 10, max: 500 }).withMessage('Rejection reason must be between 10 and 500 characters'),
  validateRequest([
    param('templateId').isUUID(),
    body('reason').trim().isLength({ min: 10, max: 500 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { templateId } = req.params;
    const { reason } = req.body;
    
    await adminService.rejectTemplate(templateId, req.user!.id, reason);
    
    res.status(200).json({
      success: true,
      message: 'Template rejected successfully',
      data: {
        templateId,
        status: 'rejected',
        rejectionReason: reason,
        rejectedBy: req.user?.id,
        rejectedAt: new Date().toISOString(),
      },
    });
  })
);

// Get all users
router.get('/users',
  requirePermission(Permission.MANAGE_USERS),
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('role').optional().isIn(['user', 'creator', 'admin']).withMessage('Invalid role'),
    query('status').optional().isIn(['active', 'banned', 'pending']).withMessage('Invalid status'),
    query('search').optional().isString().withMessage('Search must be a string'),
  ],
  validateRequest([
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('role').optional().isIn(['user', 'creator', 'admin']),
    query('status').optional().isIn(['active', 'banned', 'pending']),
    query('search').optional().isString(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const filters = {
      role: req.query.role as string,
      status: req.query.status as string,
      search: req.query.search as string,
    };
    
    const result = await adminService.getUsers(page, limit, filters);
    
    res.status(200).json({
      success: true,
      data: result,
    });
  })
);

// Ban/unban user
router.put('/users/:userId/ban',
  requirePermission(Permission.MANAGE_USERS),
  param('userId').isUUID().withMessage('Invalid user ID'),
  [
    body('banned').isBoolean().withMessage('banned must be a boolean'),
    body('reason').optional().trim().isLength({ max: 500 }).withMessage('Reason must be less than 500 characters'),
  ],
  validateRequest([
    param('userId').isUUID(),
    body('banned').isBoolean(),
    body('reason').optional().trim().isLength({ max: 500 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { userId } = req.params;
    const { banned, reason } = req.body;
    
    await adminService.banUser(userId, req.user!.id, banned, reason);
    
    res.status(200).json({
      success: true,
      message: banned ? 'User banned successfully' : 'User unbanned successfully',
      data: {
        userId,
        banned,
        reason,
        actionBy: req.user?.id,
        actionAt: new Date().toISOString(),
      },
    });
  })
);

// Manage categories
router.get('/categories',
  requirePermission(Permission.MANAGE_CATEGORIES),
  asyncHandler(async (req: RBACRequest, res) => {
    const categories = await adminService.getCategories();
    
    res.status(200).json({
      success: true,
      data: {
        categories,
      },
    });
  })
);

router.post('/categories',
  requirePermission(Permission.MANAGE_CATEGORIES),
  [
    body('name').trim().isLength({ min: 2, max: 50 }).withMessage('Category name must be between 2 and 50 characters'),
    body('description').optional().trim().isLength({ max: 200 }).withMessage('Description must be less than 200 characters'),
    body('parentId').optional().isUUID().withMessage('Invalid parent category ID'),
    body('icon').optional().isString().withMessage('Icon must be a string'),
  ],
  validateRequest([
    body('name').trim().isLength({ min: 2, max: 50 }),
    body('description').optional().trim().isLength({ max: 200 }),
    body('parentId').optional().isUUID(),
    body('icon').optional().isString(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const categoryData = {
      name: req.body.name,
      description: req.body.description,
      parentId: req.body.parentId,
      icon: req.body.icon,
    };
    
    const category = await adminService.createCategory(req.user!.id, categoryData);
    
    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: {
        category,
      },
    });
  })
);

router.put('/categories/:categoryId',
  requirePermission(Permission.MANAGE_CATEGORIES),
  param('categoryId').isUUID().withMessage('Invalid category ID'),
  [
    body('name').optional().trim().isLength({ min: 2, max: 50 }).withMessage('Category name must be between 2 and 50 characters'),
    body('description').optional().trim().isLength({ max: 200 }).withMessage('Description must be less than 200 characters'),
    body('parentId').optional().isUUID().withMessage('Invalid parent category ID'),
    body('icon').optional().isString().withMessage('Icon must be a string'),
    body('orderIndex').optional().isInt({ min: 0 }).withMessage('Order index must be a non-negative integer'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
  ],
  validateRequest([
    param('categoryId').isUUID(),
    body('name').optional().trim().isLength({ min: 2, max: 50 }),
    body('description').optional().trim().isLength({ max: 200 }),
    body('parentId').optional().isUUID(),
    body('icon').optional().isString(),
    body('orderIndex').optional().isInt({ min: 0 }),
    body('isActive').optional().isBoolean(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { categoryId } = req.params;
    const updateData = {
      name: req.body.name,
      description: req.body.description,
      parentId: req.body.parentId,
      icon: req.body.icon,
      orderIndex: req.body.orderIndex,
      isActive: req.body.isActive,
    };
    
    await adminService.updateCategory(categoryId, req.user!.id, updateData);
    
    res.status(200).json({
      success: true,
      message: 'Category updated successfully',
    });
  })
);

router.delete('/categories/:categoryId',
  requirePermission(Permission.MANAGE_CATEGORIES),
  param('categoryId').isUUID().withMessage('Invalid category ID'),
  validateRequest([
    param('categoryId').isUUID(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { categoryId } = req.params;
    
    await adminService.deleteCategory(categoryId, req.user!.id);
    
    res.status(200).json({
      success: true,
      message: 'Category deleted successfully',
    });
  })
);

// Get payment statistics
router.get('/payments',
  requirePermission(Permission.VIEW_ANALYTICS),
  [
    query('startDate').optional().isISO8601().withMessage('Invalid start date'),
    query('endDate').optional().isISO8601().withMessage('Invalid end date'),
    query('groupBy').optional().isIn(['day', 'week', 'month']).withMessage('Invalid groupBy option'),
  ],
  validateRequest([
    query('startDate').optional().isISO8601(),
    query('endDate').optional().isISO8601(),
    query('groupBy').optional().isIn(['day', 'week', 'month']),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const startDate = req.query.startDate as string;
    const endDate = req.query.endDate as string;
    const groupBy = (req.query.groupBy as 'day' | 'week' | 'month') || 'day';
    
    const result = await adminService.getPaymentStats(startDate, endDate, groupBy);
    
    res.status(200).json({
      success: true,
      data: result,
    });
  })
);

// Bulk ban/unban users
router.put('/users/bulk-ban',
  requirePermission(Permission.MANAGE_USERS),
  [
    body('userIds').isArray({ min: 1 }).withMessage('userIds must be a non-empty array'),
    body('userIds.*').isUUID().withMessage('Each user ID must be a valid UUID'),
    body('banned').isBoolean().withMessage('banned must be a boolean'),
    body('reason').optional().trim().isLength({ max: 500 }).withMessage('Reason must be less than 500 characters'),
  ],
  validateRequest([
    body('userIds').isArray({ min: 1 }),
    body('userIds.*').isUUID(),
    body('banned').isBoolean(),
    body('reason').optional().trim().isLength({ max: 500 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const { userIds, banned, reason } = req.body;
    
    const result = await adminService.bulkBanUsers(userIds, req.user!.id, banned, reason);
    
    res.status(200).json({
      success: true,
      message: `Bulk ${banned ? 'ban' : 'unban'} operation completed`,
      data: result,
    });
  })
);

// Get user activity monitoring
router.get('/activity',
  requirePermission(Permission.VIEW_ANALYTICS),
  [
    query('userId').optional().isUUID().withMessage('Invalid user ID'),
    query('startDate').optional().isISO8601().withMessage('Invalid start date'),
    query('endDate').optional().isISO8601().withMessage('Invalid end date'),
    query('limit').optional().isInt({ min: 1, max: 1000 }).withMessage('Limit must be between 1 and 1000'),
  ],
  validateRequest([
    query('userId').optional().isUUID(),
    query('startDate').optional().isISO8601(),
    query('endDate').optional().isISO8601(),
    query('limit').optional().isInt({ min: 1, max: 1000 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const userId = req.query.userId as string;
    const startDate = req.query.startDate as string;
    const endDate = req.query.endDate as string;
    const limit = parseInt(req.query.limit as string) || 100;
    
    const result = await adminService.getUserActivityMonitoring(userId, startDate, endDate, limit);
    
    res.status(200).json({
      success: true,
      data: result,
    });
  })
);

// Get system health metrics
router.get('/health',
  requirePermission(Permission.VIEW_ANALYTICS),
  asyncHandler(async (req: RBACRequest, res) => {
    const metrics = await adminService.getSystemHealthMetrics();
    
    res.status(200).json({
      success: true,
      data: metrics,
    });
  })
);

export default router;