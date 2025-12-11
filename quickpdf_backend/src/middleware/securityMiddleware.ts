import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';
import { logger } from '@/utils/logger';
import { createError } from './errorHandler';
import { SecurityMonitoringService } from '@/services/securityMonitoringService';

export interface SecurityRequest extends Request {
  csrfToken?: string;
  sessionId?: string;
}

export interface CSRFTokenStore {
  [sessionId: string]: {
    token: string;
    expires: number;
  };
}

export class SecurityService {
  private static csrfTokens: CSRFTokenStore = {};
  private static readonly CSRF_TOKEN_EXPIRY = 3600000; // 1 hour

  /**
   * Generates a secure CSRF token
   */
  static generateCSRFToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  /**
   * Stores CSRF token for a session
   */
  static storeCSRFToken(sessionId: string, token: string): void {
    this.csrfTokens[sessionId] = {
      token,
      expires: Date.now() + this.CSRF_TOKEN_EXPIRY,
    };
  }

  /**
   * Validates CSRF token
   */
  static validateCSRFToken(sessionId: string, token: string): boolean {
    const storedToken = this.csrfTokens[sessionId];
    
    if (!storedToken) {
      return false;
    }

    if (Date.now() > storedToken.expires) {
      delete this.csrfTokens[sessionId];
      return false;
    }

    return crypto.timingSafeEqual(
      Buffer.from(storedToken.token),
      Buffer.from(token)
    );
  }

  /**
   * Cleans up expired CSRF tokens
   */
  static cleanupExpiredTokens(): void {
    const now = Date.now();
    Object.keys(this.csrfTokens).forEach(sessionId => {
      if (this.csrfTokens[sessionId].expires < now) {
        delete this.csrfTokens[sessionId];
      }
    });
  }
}

/**
 * Enhanced security headers middleware
 */
export const securityHeadersMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Strict Transport Security
  res.setHeader(
    'Strict-Transport-Security',
    'max-age=31536000; includeSubDomains; preload'
  );

  // Content Security Policy
  res.setHeader(
    'Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'; " +
    "style-src 'self' 'unsafe-inline'; " +
    "img-src 'self' data: https:; " +
    "font-src 'self' data:; " +
    "connect-src 'self'; " +
    "frame-ancestors 'none'; " +
    "base-uri 'self'; " +
    "form-action 'self'"
  );

  // X-Frame-Options
  res.setHeader('X-Frame-Options', 'DENY');

  // X-Content-Type-Options
  res.setHeader('X-Content-Type-Options', 'nosniff');

  // X-XSS-Protection
  res.setHeader('X-XSS-Protection', '1; mode=block');

  // Referrer Policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  // Permissions Policy
  res.setHeader(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=(), payment=()'
  );

  // Remove server information
  res.removeHeader('X-Powered-By');
  res.removeHeader('Server');

  // Cache Control for sensitive endpoints
  if (req.path.includes('/api/')) {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }

  next();
};

/**
 * CSRF protection middleware
 */
export const csrfProtectionMiddleware = (
  req: SecurityRequest,
  res: Response,
  next: NextFunction
): void => {
  try {
    // Skip CSRF for GET, HEAD, OPTIONS requests
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      return next();
    }

    // Skip CSRF for webhook endpoints
    if (req.path.includes('/webhook')) {
      return next();
    }

    const sessionId = req.sessionId || req.headers['x-session-id'] as string;
    
    if (!sessionId) {
      return next(createError('Session required for CSRF protection', 403));
    }

    const csrfToken = req.headers['x-csrf-token'] as string || 
                     req.body._csrf || 
                     req.query._csrf as string;

    if (!csrfToken) {
      return next(createError('CSRF token required', 403));
    }

    if (!SecurityService.validateCSRFToken(sessionId, csrfToken)) {
      SecurityMonitoringService.recordEvent({
        type: 'csrf_violation',
        severity: 'high',
        ip: req.ip || 'unknown',
        userAgent: req.get('User-Agent'),
        details: {
          sessionId: sessionId.substring(0, 8) + '...',
          path: req.path,
          method: req.method,
        },
      });

      logger.warn('Invalid CSRF token attempt', {
        sessionId: sessionId.substring(0, 8) + '...',
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        path: req.path,
      });
      return next(createError('Invalid CSRF token', 403));
    }

    req.csrfToken = csrfToken;
    next();
  } catch (error) {
    logger.error('CSRF protection error:', error);
    next(createError('CSRF protection failed', 500));
  }
};

/**
 * CSRF token generation endpoint middleware
 */
export const generateCSRFTokenMiddleware = (
  req: SecurityRequest,
  res: Response,
  next: NextFunction
): void => {
  try {
    const sessionId = req.sessionId || req.headers['x-session-id'] as string;
    
    if (!sessionId) {
      return next(createError('Session required to generate CSRF token', 403));
    }

    const csrfToken = SecurityService.generateCSRFToken();
    SecurityService.storeCSRFToken(sessionId, csrfToken);

    res.json({
      success: true,
      csrfToken,
      expiresIn: SecurityService['CSRF_TOKEN_EXPIRY'],
    });
  } catch (error) {
    logger.error('CSRF token generation error:', error);
    next(createError('Failed to generate CSRF token', 500));
  }
};

/**
 * Request logging middleware for security monitoring
 */
export const securityLoggingMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const startTime = Date.now();

  // Log security-relevant request information
  logger.info('Security request log', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    referer: req.get('Referer'),
    contentType: req.get('Content-Type'),
    contentLength: req.get('Content-Length'),
    timestamp: new Date().toISOString(),
  });

  // Log response information
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    
    logger.info('Security response log', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration,
      ip: req.ip,
      timestamp: new Date().toISOString(),
    });

    // Log suspicious activity
    if (res.statusCode >= 400) {
      logger.warn('Suspicious request detected', {
        method: req.method,
        path: req.path,
        statusCode: res.statusCode,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        timestamp: new Date().toISOString(),
      });
    }
  });

  next();
};

/**
 * Request size limiting middleware
 */
export const requestSizeLimitMiddleware = (maxSize: number = 10 * 1024 * 1024) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const contentLength = parseInt(req.get('Content-Length') || '0');
    
    if (contentLength > maxSize) {
      logger.warn('Request size limit exceeded', {
        contentLength,
        maxSize,
        ip: req.ip,
        path: req.path,
      });
      return next(createError('Request entity too large', 413));
    }

    next();
  };
};

/**
 * IP-based rate limiting middleware
 */
export const ipRateLimitMiddleware = (
  windowMs: number = 15 * 60 * 1000, // 15 minutes
  maxRequests: number = 100
) => {
  const requests = new Map<string, { count: number; resetTime: number }>();

  return (req: Request, res: Response, next: NextFunction): void => {
    const ip = req.ip;
    const now = Date.now();
    const windowStart = now - windowMs;

    // Clean up old entries
    for (const [key, value] of requests.entries()) {
      if (value.resetTime < windowStart) {
        requests.delete(key);
      }
    }

    const requestData = requests.get(ip);
    
    if (!requestData) {
      requests.set(ip, { count: 1, resetTime: now + windowMs });
      return next();
    }

    if (requestData.resetTime < now) {
      // Reset window
      requests.set(ip, { count: 1, resetTime: now + windowMs });
      return next();
    }

    if (requestData.count >= maxRequests) {
      SecurityMonitoringService.recordEvent({
        type: 'rate_limit_exceeded',
        severity: 'medium',
        ip: ip || 'unknown',
        userAgent: req.get('User-Agent'),
        details: {
          count: requestData.count,
          maxRequests,
          path: req.path,
          method: req.method,
        },
      });

      logger.warn('Rate limit exceeded', {
        ip,
        count: requestData.count,
        maxRequests,
        path: req.path,
      });
      
      res.setHeader('Retry-After', Math.ceil((requestData.resetTime - now) / 1000));
      return next(createError('Too many requests', 429));
    }

    requestData.count++;
    next();
  };
};

/**
 * Suspicious activity detection middleware
 */
export const suspiciousActivityMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const suspiciousPatterns = [
    /\.\.\//g, // Directory traversal
    /<script/gi, // XSS attempts
    /union.*select/gi, // SQL injection
    /exec\s*\(/gi, // Code execution
    /eval\s*\(/gi, // Code evaluation
    /javascript:/gi, // JavaScript protocol
  ];

  const checkString = (str: string): boolean => {
    return suspiciousPatterns.some(pattern => pattern.test(str));
  };

  const checkObject = (obj: any): boolean => {
    if (typeof obj === 'string') {
      return checkString(obj);
    }
    
    if (Array.isArray(obj)) {
      return obj.some(checkObject);
    }
    
    if (typeof obj === 'object' && obj !== null) {
      return Object.values(obj).some(checkObject);
    }
    
    return false;
  };

  // Check URL, query parameters, and body for suspicious patterns
  const suspicious = 
    checkString(req.url) ||
    checkObject(req.query) ||
    checkObject(req.body);

  if (suspicious) {
    SecurityMonitoringService.recordEvent({
      type: 'injection_attempt',
      severity: 'critical',
      ip: req.ip || 'unknown',
      userAgent: req.get('User-Agent'),
      details: {
        method: req.method,
        path: req.path,
        query: req.query,
        body: typeof req.body === 'object' ? '[OBJECT]' : req.body,
      },
    });

    logger.warn('Suspicious activity detected', {
      method: req.method,
      path: req.path,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      query: req.query,
      body: typeof req.body === 'object' ? '[OBJECT]' : req.body,
      timestamp: new Date().toISOString(),
    });

    return next(createError('Suspicious request detected', 400));
  }

  next();
};

// Cleanup expired tokens periodically
setInterval(() => {
  SecurityService.cleanupExpiredTokens();
}, 300000); // Every 5 minutes

export default {
  SecurityService,
  securityHeadersMiddleware,
  csrfProtectionMiddleware,
  generateCSRFTokenMiddleware,
  securityLoggingMiddleware,
  requestSizeLimitMiddleware,
  ipRateLimitMiddleware,
  suspiciousActivityMiddleware,
};