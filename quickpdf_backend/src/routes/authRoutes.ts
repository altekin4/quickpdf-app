import { Router } from 'express';
import { body } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { AuthService } from '@/services/authService';
import { authMiddleware, AuthenticatedRequest } from '@/middleware/authMiddleware';

const router = Router();

// Validation rules
const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email is required'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  body('fullName')
    .trim()
    .isLength({ min: 2 })
    .withMessage('Full name must be at least 2 characters long'),
  body('phone')
    .optional()
    .isMobilePhone('tr-TR')
    .withMessage('Valid Turkish phone number is required'),
  body('role')
    .optional()
    .isIn(['user', 'creator', 'admin'])
    .withMessage('Role must be user, creator, or admin'),
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Valid email is required'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
];

// Routes
router.post('/register', 
  validateRequest(registerValidation),
  asyncHandler(async (req, res) => {
    const { email, password, fullName, phone, role } = req.body;
    
    const result = await AuthService.register({
      email,
      password,
      fullName,
      phone,
      role,
    });

    res.status(201).json({
      success: true,
      message: 'User registered successfully. Please check your email for verification.',
      data: result,
    });
  })
);

router.post('/login',
  validateRequest(loginValidation),
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;
    
    const result = await AuthService.login({ email, password });

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: result,
    });
  })
);

router.post('/refresh',
  body('refreshToken').notEmpty().withMessage('Refresh token is required'),
  validateRequest([body('refreshToken').notEmpty()]),
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    
    const tokens = await AuthService.refreshToken(refreshToken);

    res.status(200).json({
      success: true,
      message: 'Token refreshed successfully',
      data: tokens,
    });
  })
);

router.post('/logout',
  body('refreshToken').optional(),
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    
    if (refreshToken) {
      await AuthService.logout(refreshToken);
    }

    res.status(200).json({
      success: true,
      message: 'Logout successful',
    });
  })
);

router.post('/forgot-password',
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  validateRequest([body('email').isEmail()]),
  asyncHandler(async (req, res) => {
    const { email } = req.body;
    
    await AuthService.forgotPassword(email);

    res.status(200).json({
      success: true,
      message: 'If an account with that email exists, a password reset email has been sent.',
    });
  })
);

router.post('/reset-password',
  [
    body('token').notEmpty().withMessage('Reset token is required'),
    body('password')
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters long')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  ],
  validateRequest([
    body('token').notEmpty(),
    body('password').isLength({ min: 6 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
  ]),
  asyncHandler(async (req, res) => {
    const { token, password } = req.body;
    
    await AuthService.resetPassword(token, password);

    res.status(200).json({
      success: true,
      message: 'Password reset successful. Please log in with your new password.',
    });
  })
);

router.get('/verify-email/:token',
  asyncHandler(async (req, res) => {
    const { token } = req.params;
    
    await AuthService.verifyEmail(token);

    res.status(200).json({
      success: true,
      message: 'Email verified successfully. You can now log in.',
    });
  })
);

router.post('/change-password',
  authMiddleware,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword')
      .isLength({ min: 6 })
      .withMessage('New password must be at least 6 characters long')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('New password must contain at least one lowercase letter, one uppercase letter, and one number'),
  ],
  validateRequest([
    body('currentPassword').notEmpty(),
    body('newPassword').isLength({ min: 6 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user!.id;
    
    await AuthService.changePassword(userId, currentPassword, newPassword);

    res.status(200).json({
      success: true,
      message: 'Password changed successfully. Please log in again.',
    });
  })
);

export default router;