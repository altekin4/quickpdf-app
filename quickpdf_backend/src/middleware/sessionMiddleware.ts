import { Request, Response, NextFunction } from 'express';
import { EncryptionService } from '@/services/encryptionService';
import { logger } from '@/utils/logger';
import { createError } from './errorHandler';

export interface SecureSession {
  userId: string;
  email: string;
  role: string;
  sessionId: string;
  createdAt: number;
  lastActivity: number;
  ipAddress: string;
  userAgent: string;
}

export interface SessionRequest extends Request {
  session?: SecureSession;
  sessionId?: string;
}

export class SessionManager {
  private static sessions = new Map<string, SecureSession>();
  private static readonly SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes
  private static readonly MAX_SESSIONS_PER_USER = 5;

  /**
   * Creates a new secure session
   */
  static createSession(
    userId: string,
    email: string,
    role: string,
    ipAddress: string,
    userAgent: string
  ): string {
    try {
      // Clean up expired sessions
      this.cleanupExpiredSessions();

      // Check if user has too many active sessions
      this.enforceSessionLimit(userId);

      // Generate secure session ID
      const sessionId = EncryptionService.generateApiKey();

      // Create session data
      const session: SecureSession = {
        userId,
        email,
        role,
        sessionId,
        createdAt: Date.now(),
        lastActivity: Date.now(),
        ipAddress,
        userAgent,
      };

      // Store encrypted session
      const encryptedSession = EncryptionService.encryptSensitiveData(JSON.stringify(session));
      this.sessions.set(sessionId, JSON.parse(EncryptionService.decryptSensitiveData(encryptedSession)));

      logger.info('Secure session created', {
        userId,
        sessionId: sessionId.substring(0, 8) + '...',
        ipAddress,
      });

      return sessionId;
    } catch (error) {
      logger.error('Session creation failed:', error);
      throw createError('Failed to create session', 500);
    }
  }

  /**
   * Retrieves and validates a session
   */
  static getSession(sessionId: string): SecureSession | null {
    try {
      const session = this.sessions.get(sessionId);
      
      if (!session) {
        return null;
      }

      // Check if session is expired
      if (Date.now() - session.lastActivity > this.SESSION_TIMEOUT) {
        this.destroySession(sessionId);
        return null;
      }

      // Update last activity
      session.lastActivity = Date.now();
      this.sessions.set(sessionId, session);

      return session;
    } catch (error) {
      logger.error('Session retrieval failed:', error);
      return null;
    }
  }

  /**
   * Updates session activity
   */
  static updateSessionActivity(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.lastActivity = Date.now();
      this.sessions.set(sessionId, session);
    }
  }

  /**
   * Destroys a specific session
   */
  static destroySession(sessionId: string): void {
    try {
      const session = this.sessions.get(sessionId);
      if (session) {
        this.sessions.delete(sessionId);
        logger.info('Session destroyed', {
          userId: session.userId,
          sessionId: sessionId.substring(0, 8) + '...',
        });
      }
    } catch (error) {
      logger.error('Session destruction failed:', error);
    }
  }

  /**
   * Destroys all sessions for a user
   */
  static destroyUserSessions(userId: string): void {
    try {
      let destroyedCount = 0;
      for (const [sessionId, session] of this.sessions.entries()) {
        if (session.userId === userId) {
          this.sessions.delete(sessionId);
          destroyedCount++;
        }
      }
      
      logger.info('User sessions destroyed', {
        userId,
        count: destroyedCount,
      });
    } catch (error) {
      logger.error('User session destruction failed:', error);
    }
  }

  /**
   * Gets all active sessions for a user
   */
  static getUserSessions(userId: string): SecureSession[] {
    const userSessions: SecureSession[] = [];
    
    for (const session of this.sessions.values()) {
      if (session.userId === userId) {
        userSessions.push(session);
      }
    }
    
    return userSessions;
  }

  /**
   * Cleans up expired sessions
   */
  private static cleanupExpiredSessions(): void {
    const now = Date.now();
    const expiredSessions: string[] = [];

    for (const [sessionId, session] of this.sessions.entries()) {
      if (now - session.lastActivity > this.SESSION_TIMEOUT) {
        expiredSessions.push(sessionId);
      }
    }

    expiredSessions.forEach(sessionId => {
      this.sessions.delete(sessionId);
    });

    if (expiredSessions.length > 0) {
      logger.info('Expired sessions cleaned up', { count: expiredSessions.length });
    }
  }

  /**
   * Enforces session limit per user
   */
  private static enforceSessionLimit(userId: string): void {
    const userSessions = this.getUserSessions(userId);
    
    if (userSessions.length >= this.MAX_SESSIONS_PER_USER) {
      // Remove oldest session
      const oldestSession = userSessions.sort((a, b) => a.createdAt - b.createdAt)[0];
      this.destroySession(oldestSession.sessionId);
    }
  }
}

/**
 * Middleware for secure session management
 */
export const secureSessionMiddleware = (
  req: SessionRequest,
  res: Response,
  next: NextFunction
): void => {
  try {
    const sessionId = req.headers['x-session-id'] as string || 
                     req.cookies?.sessionId ||
                     req.query.sessionId as string;

    if (sessionId) {
      const session = SessionManager.getSession(sessionId);
      
      if (session) {
        // Validate session integrity
        const currentIp = req.ip || req.connection.remoteAddress || '';
        const currentUserAgent = req.get('User-Agent') || '';

        // Check for session hijacking
        if (session.ipAddress !== currentIp) {
          logger.warn('Session IP mismatch detected', {
            sessionId: sessionId.substring(0, 8) + '...',
            originalIp: session.ipAddress,
            currentIp,
            userId: session.userId,
          });
          
          SessionManager.destroySession(sessionId);
          return next(createError('Session security violation', 401));
        }

        // Update session activity
        SessionManager.updateSessionActivity(sessionId);

        // Attach session to request
        req.session = session;
        req.sessionId = sessionId;
      }
    }

    next();
  } catch (error) {
    logger.error('Session middleware error:', error);
    next(createError('Session processing failed', 500));
  }
};

/**
 * Middleware to require a valid session
 */
export const requireSession = (
  req: SessionRequest,
  res: Response,
  next: NextFunction
): void => {
  if (!req.session) {
    return next(createError('Valid session required', 401));
  }
  next();
};

/**
 * Middleware to create session on login
 */
export const createSessionOnLogin = (
  req: SessionRequest,
  res: Response,
  next: NextFunction
): void => {
  // This middleware should be used after successful authentication
  if (req.user && !req.session) {
    const sessionId = SessionManager.createSession(
      req.user.id,
      req.user.email,
      req.user.role,
      req.ip || req.connection.remoteAddress || '',
      req.get('User-Agent') || ''
    );

    // Set session cookie
    res.cookie('sessionId', sessionId, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 30 * 60 * 1000, // 30 minutes
    });

    req.sessionId = sessionId;
  }
  
  next();
};

export default {
  SessionManager,
  secureSessionMiddleware,
  requireSession,
  createSessionOnLogin,
};