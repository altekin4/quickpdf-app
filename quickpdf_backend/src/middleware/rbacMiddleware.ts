import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './authMiddleware';

// Permission enum
export enum Permission {
  // User permissions
  READ_OWN_PROFILE = 'read:own_profile',
  UPDATE_OWN_PROFILE = 'update:own_profile',
  DELETE_OWN_ACCOUNT = 'delete:own_account',
  
  // Template permissions
  READ_TEMPLATE = 'read:template',
  CREATE_TEMPLATE = 'create:template',
  UPDATE_OWN_TEMPLATE = 'update:own_template',
  DELETE_OWN_TEMPLATE = 'delete:own_template',
  PUBLISH_TEMPLATE = 'publish:template',
  PURCHASE_TEMPLATE = 'purchase:template',
  
  // Purchase permissions
  VIEW_OWN_PURCHASES = 'view:own_purchases',
  
  // Rating permissions
  RATE_PURCHASED_TEMPLATE = 'rate:purchased_template',
  VIEW_RATINGS = 'view:ratings',
  
  // Document permissions
  CREATE_DOCUMENT = 'create:document',
  VIEW_OWN_DOCUMENTS = 'view:own_documents',
  DELETE_OWN_DOCUMENT = 'delete:own_document',
  
  // Admin permissions
  MANAGE_USERS = 'manage:users',
  MANAGE_TEMPLATES = 'manage:templates',
  MANAGE_CATEGORIES = 'manage:categories',
  VIEW_ANALYTICS = 'view:analytics',
  MODERATE_CONTENT = 'moderate:content',
  MANAGE_PAYOUTS = 'manage:payouts',
  
  // Creator permissions
  VIEW_EARNINGS = 'view:earnings',
  REQUEST_PAYOUT = 'request:payout',
  VIEW_TEMPLATE_ANALYTICS = 'view:template_analytics',
}

// Base permissions for each role
const USER_PERMISSIONS = [
  Permission.READ_OWN_PROFILE,
  Permission.UPDATE_OWN_PROFILE,
  Permission.DELETE_OWN_ACCOUNT,
  Permission.READ_TEMPLATE,
  Permission.PURCHASE_TEMPLATE,
  Permission.VIEW_OWN_PURCHASES,
  Permission.RATE_PURCHASED_TEMPLATE,
  Permission.VIEW_RATINGS,
  Permission.CREATE_DOCUMENT,
  Permission.VIEW_OWN_DOCUMENTS,
  Permission.DELETE_OWN_DOCUMENT,
];

const CREATOR_PERMISSIONS = [
  ...USER_PERMISSIONS,
  Permission.CREATE_TEMPLATE,
  Permission.UPDATE_OWN_TEMPLATE,
  Permission.DELETE_OWN_TEMPLATE,
  Permission.PUBLISH_TEMPLATE,
  Permission.VIEW_EARNINGS,
  Permission.REQUEST_PAYOUT,
  Permission.VIEW_TEMPLATE_ANALYTICS,
];

const ADMIN_PERMISSIONS = [
  ...CREATOR_PERMISSIONS,
  Permission.MANAGE_USERS,
  Permission.MANAGE_TEMPLATES,
  Permission.MANAGE_CATEGORIES,
  Permission.VIEW_ANALYTICS,
  Permission.MODERATE_CONTENT,
  Permission.MANAGE_PAYOUTS,
];

// Role definitions with their permissions
export const ROLE_PERMISSIONS: Record<string, Permission[]> = {
  user: USER_PERMISSIONS,
  creator: CREATOR_PERMISSIONS,
  admin: ADMIN_PERMISSIONS,
};

export interface RBACRequest extends AuthenticatedRequest {
  permissions?: Permission[];
}

/**
 * Middleware to check if user has required permissions
 */
export const requirePermissions = (requiredPermissions: Permission[]) => {
  return (req: RBACRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Authentication required'
          }
        });
      }

      const userRole = req.user.role;
      const userPermissions = ROLE_PERMISSIONS[userRole] || [];

      // Check if user has all required permissions
      const hasAllPermissions = requiredPermissions.every(permission =>
        userPermissions.includes(permission)
      );

      if (!hasAllPermissions) {
        return res.status(403).json({
          error: {
            code: 'FORBIDDEN',
            message: 'Insufficient permissions',
            required: requiredPermissions,
            current: userPermissions
          }
        });
      }

      // Add permissions to request for further use
      req.permissions = userPermissions;
      next();
    } catch (error) {
      return res.status(500).json({
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Permission check failed'
        }
      });
    }
  };
};

/**
 * Middleware to check if user has specific role
 */
export const requireRole = (allowedRoles: string[]) => {
  return (req: RBACRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Authentication required'
          }
        });
      }

      const userRole = req.user.role;

      if (!allowedRoles.includes(userRole)) {
        return res.status(403).json({
          error: {
            code: 'FORBIDDEN',
            message: 'Insufficient role privileges',
            required: allowedRoles,
            current: userRole
          }
        });
      }

      next();
    } catch (error) {
      return res.status(500).json({
        error: {
          code: 'INTERNAL_ERROR',
          message: 'Role check failed'
        }
      });
    }
  };
};

/**
 * Check if user has permission
 */
export const hasPermission = (userRole: string, permission: Permission): boolean => {
  const userPermissions = ROLE_PERMISSIONS[userRole] || [];
  return userPermissions.includes(permission);
};

/**
 * Get all permissions for a role
 */
export const getRolePermissions = (role: string): Permission[] => {
  return ROLE_PERMISSIONS[role] || [];
};