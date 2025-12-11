import { Router, Response } from 'express';
import { body, param } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { AuthenticatedRequest, authMiddleware } from '@/middleware/authMiddleware';
import { 
  requirePermission, 
  Permission, 
  RBACRequest,
  requireOwnership 
} from '@/middleware/rbacMiddleware';
import { UserModel } from '@/models/User';
import { UserProfileService } from '@/services/userProfileService';
import multer from 'multer';

const router = Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPG, PNG, and WebP files are allowed'));
    }
  },
});

// Get current user profile
router.get('/profile',
  authMiddleware,
  requirePermission(Permission.READ_OWN_PROFILE),
  asyncHandler(async (req: RBACRequest, res) => {
    const profile = await UserProfileService.getProfile(req.user!.id);
    
    res.status(200).json({
      success: true,
      data: {
        user: profile,
      },
    });
  })
);

// Update user profile
router.put('/profile',
  authMiddleware,
  requirePermission(Permission.UPDATE_OWN_PROFILE),
  [
    body('fullName')
      .optional()
      .trim()
      .isLength({ min: 2 })
      .withMessage('Full name must be at least 2 characters long'),
    body('phone')
      .optional()
      .isMobilePhone('tr-TR')
      .withMessage('Valid Turkish phone number is required'),
  ],
  validateRequest([
    body('fullName').optional().trim().isLength({ min: 2 }),
    body('phone').optional().isMobilePhone('tr-TR'),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const updatedProfile = await UserProfileService.updateProfile(req.user!.id, {
      fullName: req.body.fullName,
      phone: req.body.phone,
    });
    
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: updatedProfile,
      },
    });
  })
);

// Change password
router.put('/password',
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters long'),
  ],
  validateRequest([
    body('currentPassword').notEmpty(),
    body('newPassword').isLength({ min: 6 }),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Verify current password and update to new password
    res.status(200).json({
      success: true,
      message: 'Password changed successfully',
    });
  })
);

// Get user statistics
router.get('/stats',
  authMiddleware,
  requirePermission(Permission.READ_OWN_PROFILE),
  asyncHandler(async (req: RBACRequest, res) => {
    const stats = await UserModel.getUserStats(req.user!.id);
    
    res.status(200).json({
      success: true,
      data: {
        stats,
      },
    });
  })
);

// Upload profile picture
router.post('/profile-picture',
  authMiddleware,
  requirePermission(Permission.UPDATE_OWN_PROFILE),
  upload.single('profilePicture'),
  asyncHandler(async (req: RBACRequest, res) => {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file provided',
      });
    }

    const profilePictureUrl = await UserProfileService.uploadProfilePicture(req.user!.id, req.file);
    
    res.status(200).json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        profilePictureUrl,
      },
    });
  })
);

// Delete profile picture
router.delete('/profile-picture',
  authMiddleware,
  requirePermission(Permission.UPDATE_OWN_PROFILE),
  asyncHandler(async (req: RBACRequest, res) => {
    await UserProfileService.deleteProfilePicture(req.user!.id);
    
    res.status(200).json({
      success: true,
      message: 'Profile picture deleted successfully',
    });
  })
);

// Delete user account
router.delete('/account',
  authMiddleware,
  requirePermission(Permission.DELETE_OWN_ACCOUNT),
  body('password').notEmpty().withMessage('Password confirmation is required'),
  validateRequest([body('password').notEmpty()]),
  asyncHandler(async (req: RBACRequest, res) => {
    await UserProfileService.deleteAccount(req.user!.id, req.body.password);
    
    res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  })
);

// Admin routes for user management
router.get('/admin/users',
  authMiddleware,
  requirePermission(Permission.MANAGE_USERS),
  asyncHandler(async (req: RBACRequest, res) => {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const role = req.query.role as string;
    const search = req.query.search as string;
    const isActive = req.query.isActive === 'true' ? true : req.query.isActive === 'false' ? false : undefined;

    const result = await UserModel.findAll(page, limit, {
      role,
      is_active: isActive,
      search,
    });

    res.status(200).json({
      success: true,
      data: {
        users: result.users.map(user => {
          const { password_hash, email_verification_token, password_reset_token, ...userProfile } = user;
          return userProfile;
        }),
        pagination: {
          page,
          limit,
          total: result.total,
          pages: Math.ceil(result.total / limit),
        },
      },
    });
  })
);

router.get('/admin/users/:userId',
  authMiddleware,
  requirePermission(Permission.MANAGE_USERS),
  param('userId').isUUID().withMessage('Valid user ID is required'),
  validateRequest([param('userId').isUUID()]),
  asyncHandler(async (req: RBACRequest, res) => {
    const user = await UserModel.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const { password_hash, email_verification_token, password_reset_token, ...userProfile } = user;
    const stats = await UserModel.getUserStats(user.id);

    res.status(200).json({
      success: true,
      data: {
        user: userProfile,
        stats,
      },
    });
  })
);

router.put('/admin/users/:userId',
  authMiddleware,
  requirePermission(Permission.MANAGE_USERS),
  [
    param('userId').isUUID().withMessage('Valid user ID is required'),
    body('role').optional().isIn(['user', 'creator', 'admin']).withMessage('Role must be user, creator, or admin'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
    body('isVerified').optional().isBoolean().withMessage('isVerified must be a boolean'),
  ],
  validateRequest([
    param('userId').isUUID(),
    body('role').optional().isIn(['user', 'creator', 'admin']),
    body('isActive').optional().isBoolean(),
    body('isVerified').optional().isBoolean(),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const updateData: any = {};
    if (req.body.role) updateData.role = req.body.role;
    if (req.body.isActive !== undefined) updateData.is_active = req.body.isActive;
    if (req.body.isVerified !== undefined) updateData.is_verified = req.body.isVerified;

    const updatedUser = await UserModel.update(req.params.userId, updateData);
    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const { password_hash, email_verification_token, password_reset_token, ...userProfile } = updatedUser;

    res.status(200).json({
      success: true,
      message: 'User updated successfully',
      data: {
        user: userProfile,
      },
    });
  })
);

// Get user settings
router.get('/settings',
  authMiddleware,
  requirePermission(Permission.READ_OWN_PROFILE),
  asyncHandler(async (req: RBACRequest, res) => {
    const settings = await UserProfileService.getUserSettings(req.user!.id);
    
    res.status(200).json({
      success: true,
      data: {
        settings,
      },
    });
  })
);

// Update user settings
router.put('/settings',
  authMiddleware,
  requirePermission(Permission.UPDATE_OWN_PROFILE),
  [
    body('emailNotifications').optional().isBoolean().withMessage('emailNotifications must be a boolean'),
    body('marketingEmails').optional().isBoolean().withMessage('marketingEmails must be a boolean'),
    body('language').optional().isIn(['tr', 'en']).withMessage('Language must be tr or en'),
    body('timezone').optional().isString().withMessage('Timezone must be a string'),
    body('currency').optional().isIn(['TRY', 'USD', 'EUR']).withMessage('Currency must be TRY, USD, or EUR'),
  ],
  validateRequest([
    body('emailNotifications').optional().isBoolean(),
    body('marketingEmails').optional().isBoolean(),
    body('language').optional().isIn(['tr', 'en']),
    body('timezone').optional().isString(),
    body('currency').optional().isIn(['TRY', 'USD', 'EUR']),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const updatedSettings = await UserProfileService.updateUserSettings(req.user!.id, req.body);
    
    res.status(200).json({
      success: true,
      message: 'Settings updated successfully',
      data: {
        settings: updatedSettings,
      },
    });
  })
);

// Get user preferences
router.get('/preferences',
  authMiddleware,
  requirePermission(Permission.READ_OWN_PROFILE),
  asyncHandler(async (req: RBACRequest, res) => {
    const preferences = await UserProfileService.getUserPreferences(req.user!.id);
    
    res.status(200).json({
      success: true,
      data: {
        preferences,
      },
    });
  })
);

// Update user preferences
router.put('/preferences',
  authMiddleware,
  requirePermission(Permission.UPDATE_OWN_PROFILE),
  [
    body('theme').optional().isIn(['light', 'dark', 'auto']).withMessage('Theme must be light, dark, or auto'),
    body('defaultTemplateCategory').optional().isUUID().withMessage('Default template category must be a valid UUID'),
    body('autoSaveDocuments').optional().isBoolean().withMessage('autoSaveDocuments must be a boolean'),
    body('documentRetentionDays').optional().isInt({ min: 1, max: 365 }).withMessage('Document retention days must be between 1 and 365'),
  ],
  validateRequest([
    body('theme').optional().isIn(['light', 'dark', 'auto']),
    body('defaultTemplateCategory').optional().isUUID(),
    body('autoSaveDocuments').optional().isBoolean(),
    body('documentRetentionDays').optional().isInt({ min: 1, max: 365 }),
  ]),
  asyncHandler(async (req: RBACRequest, res) => {
    const updatedPreferences = await UserProfileService.updateUserPreferences(req.user!.id, req.body);
    
    res.status(200).json({
      success: true,
      message: 'Preferences updated successfully',
      data: {
        preferences: updatedPreferences,
      },
    });
  })
);

// Get complete account summary
router.get('/account-summary',
  authMiddleware,
  requirePermission(Permission.READ_OWN_PROFILE),
  asyncHandler(async (req: RBACRequest, res) => {
    const accountSummary = await UserProfileService.getAccountSummary(req.user!.id);
    
    res.status(200).json({
      success: true,
      data: accountSummary,
    });
  })
);

export default router;