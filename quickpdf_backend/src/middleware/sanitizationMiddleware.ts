import { Request, Response, NextFunction } from 'express';
import validator from 'validator';
import { logger } from '@/utils/logger';
import { createError } from './errorHandler';

// Simple HTML tag removal function for server-side use
const stripHtmlTags = (str: string, allowedTags: string[] = []): string => {
  if (allowedTags.length === 0) {
    // Remove all HTML tags
    return str.replace(/<[^>]*>/g, '');
  }
  
  // Remove only non-allowed tags
  const tagRegex = /<\/?([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>/g;
  return str.replace(tagRegex, (match, tagName) => {
    return allowedTags.includes(tagName.toLowerCase()) ? match : '';
  });
};

export interface SanitizationOptions {
  allowedTags?: string[];
  allowedAttributes?: string[];
  stripTags?: boolean;
  maxLength?: number;
  allowHTML?: boolean;
}

/**
 * Sanitizes a string value to prevent XSS attacks
 */
export const sanitizeString = (
  value: string, 
  options: SanitizationOptions = {}
): string => {
  if (typeof value !== 'string') {
    return '';
  }

  const {
    allowedTags = [],
    allowedAttributes = [],
    stripTags = true,
    maxLength = 10000,
    allowHTML = false
  } = options;

  let sanitized = value;

  // Remove dangerous JavaScript patterns first
  const dangerousPatterns = [
    /javascript:/gi,
    /on\w+\s*=/gi,
    /eval\s*\(/gi,
    /setTimeout\s*\(/gi,
    /setInterval\s*\(/gi,
    /Function\s*\(/gi,
    /document\.cookie/gi,
    /window\.location/gi,
    /alert\s*\(/gi
  ];

  dangerousPatterns.forEach(pattern => {
    sanitized = sanitized.replace(pattern, '');
  });

  // Remove SQL injection patterns
  const sqlPatterns = [
    /DROP\s+TABLE/gi,
    /UNION\s+SELECT/gi,
    /INSERT\s+INTO/gi,
    /EXEC\s+xp_/gi,
    /'--/g,
    /'\s+OR\s+'/gi
  ];

  sqlPatterns.forEach(pattern => {
    sanitized = sanitized.replace(pattern, '');
  });

  if (allowHTML) {
    // Allow specific HTML tags
    const defaultAllowedTags = ['b', 'i', 'u', 'strong', 'em', 'p', 'br'];
    const tagsToAllow = allowedTags.length > 0 ? allowedTags : defaultAllowedTags;
    sanitized = stripHtmlTags(sanitized, tagsToAllow);
  } else if (stripTags) {
    // Strip all HTML tags
    sanitized = validator.stripLow(sanitized);
    sanitized = stripHtmlTags(sanitized);
  }

  // Escape remaining special characters
  sanitized = validator.escape(sanitized);

  // Trim and limit length after escaping (since escaping can increase length)
  sanitized = sanitized.trim().substring(0, maxLength);

  return sanitized;
};

/**
 * Sanitizes template content with specific rules for PDF generation
 */
export const sanitizeTemplateContent = (content: string): string => {
  if (typeof content !== 'string') {
    return '';
  }

  // Additional validation for template placeholders
  // Allow {placeholder} patterns but sanitize the content around them
  const placeholderRegex = /\{[a-zA-Z_][a-zA-Z0-9_]*\}/g;
  const placeholders = content.match(placeholderRegex) || [];
  
  // Temporarily replace placeholders with safe tokens
  const tokens: { [key: string]: string } = {};
  let sanitized = content;
  placeholders.forEach((placeholder, index) => {
    const token = `__PLACEHOLDER_${index}__`;
    tokens[token] = placeholder;
    sanitized = sanitized.replace(placeholder, token);
  });

  // Sanitize the content (allowing HTML for templates)
  sanitized = sanitizeString(sanitized, { 
    allowHTML: true, 
    allowedTags: ['b', 'i', 'u', 'strong', 'em', 'p', 'br', 'h1', 'h2', 'h3'],
    stripTags: false 
  });

  // Restore placeholders after sanitization
  Object.entries(tokens).forEach(([token, placeholder]) => {
    sanitized = sanitized.replace(token, placeholder);
  });

  return sanitized;
};

/**
 * Validates file upload security
 */
export const validateFileUpload = (file: Express.Multer.File): boolean => {
  if (!file) {
    return false;
  }

  // Check file size (max 10MB)
  const maxSize = 10 * 1024 * 1024;
  if (file.size > maxSize) {
    throw createError('File size exceeds maximum limit of 10MB', 400);
  }

  // Allowed MIME types
  const allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/gif',
    'text/plain',
    'application/json'
  ];

  if (!allowedMimeTypes.includes(file.mimetype)) {
    throw createError('File type not allowed', 400);
  }

  // Validate file extension
  const allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.gif', '.txt', '.json'];
  const fileExtension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
  
  if (!allowedExtensions.includes(fileExtension)) {
    throw createError('File extension not allowed', 400);
  }

  // Check for null bytes in filename
  if (file.originalname.includes('\0')) {
    throw createError('Invalid filename', 400);
  }

  return true;
};

/**
 * Recursively sanitizes an object's string properties
 */
export const sanitizeObject = (
  obj: any, 
  options: SanitizationOptions = {}
): any => {
  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj === 'string') {
    return sanitizeString(obj, options);
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item, options));
  }

  if (typeof obj === 'object') {
    const sanitized: any = {};
    for (const [key, value] of Object.entries(obj)) {
      // Sanitize the key as well
      const sanitizedKey = sanitizeString(key, { stripTags: true, maxLength: 100 });
      sanitized[sanitizedKey] = sanitizeObject(value, options);
    }
    return sanitized;
  }

  return obj;
};

/**
 * Middleware to sanitize request body, query, and params
 */
export const sanitizationMiddleware = (options: SanitizationOptions = {}) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      // Sanitize request body
      if (req.body) {
        req.body = sanitizeObject(req.body, options);
      }

      // Sanitize query parameters
      if (req.query) {
        req.query = sanitizeObject(req.query, options);
      }

      // Sanitize URL parameters
      if (req.params) {
        req.params = sanitizeObject(req.params, options);
      }

      // Log sanitization activity
      logger.debug('Request sanitized', {
        method: req.method,
        path: req.path,
        ip: req.ip,
        timestamp: new Date().toISOString(),
      });

      next();
    } catch (error) {
      logger.error('Sanitization error:', error);
      next(createError('Invalid input data', 400));
    }
  };
};

/**
 * Middleware specifically for template content sanitization
 */
export const templateSanitizationMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  try {
    if (req.body && req.body.content) {
      req.body.content = sanitizeTemplateContent(req.body.content);
    }

    if (req.body && req.body.body) {
      req.body.body = sanitizeTemplateContent(req.body.body);
    }

    next();
  } catch (error) {
    logger.error('Template sanitization error:', error);
    next(createError('Invalid template content', 400));
  }
};

/**
 * SQL injection prevention middleware
 */
export const sqlInjectionPreventionMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  try {
    // Check for common SQL injection patterns
    const sqlInjectionPatterns = [
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)/gi,
      /(--|\/\*|\*\/|;|'|"|`)/g,
      /(\bOR\b|\bAND\b).*?[=<>]/gi,
      /\b(WAITFOR|DELAY)\b/gi,
      /\b(XP_|SP_)/gi
    ];

    const checkForSQLInjection = (value: string): boolean => {
      return sqlInjectionPatterns.some(pattern => pattern.test(value));
    };

    const validateInput = (obj: any): void => {
      if (typeof obj === 'string') {
        if (checkForSQLInjection(obj)) {
          throw createError('Potentially malicious input detected', 400);
        }
      } else if (Array.isArray(obj)) {
        obj.forEach(validateInput);
      } else if (typeof obj === 'object' && obj !== null) {
        Object.values(obj).forEach(validateInput);
      }
    };

    // Validate all input sources
    if (req.body) validateInput(req.body);
    if (req.query) validateInput(req.query);
    if (req.params) validateInput(req.params);

    next();
  } catch (error) {
    logger.error('SQL injection prevention error:', error);
    next(error);
  }
};

export default {
  sanitizeString,
  sanitizeTemplateContent,
  validateFileUpload,
  sanitizeObject,
  sanitizationMiddleware,
  templateSanitizationMiddleware,
  sqlInjectionPreventionMiddleware,
};