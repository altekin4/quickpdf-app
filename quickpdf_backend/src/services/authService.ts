import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { UserModel, User, CreateUserData } from '@/models/User';
import { RefreshTokenModel } from '@/models/RefreshToken';
import { logger } from '@/utils/logger';
import { createError } from '@/middleware/errorHandler';
import { EncryptionService } from './encryptionService';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  fullName: string;
  phone?: string;
  role?: 'user' | 'creator' | 'admin';
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AuthResponse {
  user: Omit<User, 'password_hash' | 'email_verification_token' | 'password_reset_token'>;
  tokens: AuthTokens;
}

export class AuthService {
  private static get JWT_SECRET(): string {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('JWT_SECRET environment variable is required');
    }
    return secret;
  }

  private static get JWT_REFRESH_SECRET(): string {
    const secret = process.env.JWT_REFRESH_SECRET;
    if (!secret) {
      throw new Error('JWT_REFRESH_SECRET environment variable is required');
    }
    return secret;
  }

  private static readonly JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m';
  private static readonly JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
  private static readonly SALT_ROUNDS = 12;

  static async register(registerData: RegisterData): Promise<AuthResponse> {
    try {
      // Check if user already exists
      const existingUser = await UserModel.findByEmail(registerData.email);
      if (existingUser) {
        throw createError('User with this email already exists', 409);
      }

      // Hash password using encryption service
      const passwordHash = await EncryptionService.hashPassword(registerData.password);

      // Generate email verification token
      const emailVerificationToken = this.generateVerificationToken();

      // Create user data
      const userData: CreateUserData = {
        email: registerData.email,
        password_hash: passwordHash,
        full_name: registerData.fullName,
        phone: registerData.phone,
        role: registerData.role || 'user',
      };

      // Create user
      const user = await UserModel.create(userData);

      // Update user with verification token
      await UserModel.update(user.id, {
        email_verification_token: emailVerificationToken,
      });

      // Generate tokens
      const tokens = await this.generateTokens(user);

      // TODO: Send verification email
      logger.info(`User registered: ${user.email}, verification token: ${emailVerificationToken}`);

      return {
        user: this.sanitizeUser(user),
        tokens,
      };
    } catch (error) {
      logger.error('Registration error:', error);
      throw error;
    }
  }

  static async login(credentials: LoginCredentials): Promise<AuthResponse> {
    try {
      // Find user by email
      const user = await UserModel.findByEmail(credentials.email);
      if (!user) {
        throw createError('Invalid email or password', 401);
      }

      // Check if user is active
      if (!user.is_active) {
        throw createError('Account is deactivated', 401);
      }

      // Verify password using encryption service
      const isPasswordValid = await EncryptionService.verifyPassword(credentials.password, user.password_hash);
      if (!isPasswordValid) {
        throw createError('Invalid email or password', 401);
      }

      // Update last login
      await UserModel.update(user.id, { last_login: new Date() });

      // Generate tokens
      const tokens = await this.generateTokens(user);

      logger.info(`User logged in: ${user.email}`);

      return {
        user: this.sanitizeUser(user),
        tokens,
      };
    } catch (error) {
      logger.error('Login error:', error);
      throw error;
    }
  }

  static async refreshToken(refreshToken: string): Promise<AuthTokens> {
    try {
      // Verify refresh token
      const decoded = jwt.verify(refreshToken, this.JWT_REFRESH_SECRET) as any;
      
      // Check if refresh token exists in database
      const tokenRecord = await RefreshTokenModel.findByToken(refreshToken);
      if (!tokenRecord || tokenRecord.revoked_at) {
        throw createError('Invalid refresh token', 401);
      }

      // Check if token is expired
      if (new Date() > tokenRecord.expires_at) {
        await RefreshTokenModel.revoke(refreshToken);
        throw createError('Refresh token expired', 401);
      }

      // Get user
      const user = await UserModel.findById(decoded.userId);
      if (!user || !user.is_active) {
        throw createError('User not found or inactive', 401);
      }

      // Revoke old refresh token
      await RefreshTokenModel.revoke(refreshToken);

      // Generate new tokens
      const tokens = await this.generateTokens(user);

      logger.info(`Token refreshed for user: ${user.email}`);

      return tokens;
    } catch (error) {
      if (error instanceof jwt.JsonWebTokenError) {
        throw createError('Invalid refresh token', 401);
      }
      logger.error('Token refresh error:', error);
      throw error;
    }
  }

  static async logout(refreshToken: string): Promise<void> {
    try {
      if (refreshToken) {
        await RefreshTokenModel.revoke(refreshToken);
      }
      logger.info('User logged out');
    } catch (error) {
      logger.error('Logout error:', error);
      throw error;
    }
  }

  static async forgotPassword(email: string): Promise<void> {
    try {
      const user = await UserModel.findByEmail(email);
      if (!user) {
        // Don't reveal if email exists or not
        logger.info(`Password reset requested for non-existent email: ${email}`);
        return;
      }

      // Generate reset token
      const resetToken = this.generateVerificationToken();
      const resetExpires = new Date(Date.now() + 3600000); // 1 hour

      // Update user with reset token
      await UserModel.update(user.id, {
        password_reset_token: resetToken,
        password_reset_expires: resetExpires,
      });

      // TODO: Send password reset email
      logger.info(`Password reset token generated for user: ${user.email}, token: ${resetToken}`);
    } catch (error) {
      logger.error('Forgot password error:', error);
      throw error;
    }
  }

  static async resetPassword(token: string, newPassword: string): Promise<void> {
    try {
      // Find user by reset token
      const user = await UserModel.findByResetToken(token);
      if (!user) {
        throw createError('Invalid or expired reset token', 400);
      }

      // Check if token is expired
      if (!user.password_reset_expires || new Date() > user.password_reset_expires) {
        throw createError('Reset token has expired', 400);
      }

      // Hash new password using encryption service
      const passwordHash = await EncryptionService.hashPassword(newPassword);

      // Update user password and clear reset token
      await UserModel.update(user.id, {
        password_hash: passwordHash,
        password_reset_token: null,
        password_reset_expires: null,
      });

      // Revoke all refresh tokens for this user
      await RefreshTokenModel.revokeAllForUser(user.id);

      logger.info(`Password reset successful for user: ${user.email}`);
    } catch (error) {
      logger.error('Reset password error:', error);
      throw error;
    }
  }

  static async verifyEmail(token: string): Promise<void> {
    try {
      // Find user by verification token
      const user = await UserModel.findByVerificationToken(token);
      if (!user) {
        throw createError('Invalid verification token', 400);
      }

      // Update user as verified and clear token
      await UserModel.update(user.id, {
        is_verified: true,
        email_verification_token: null,
      });

      logger.info(`Email verified for user: ${user.email}`);
    } catch (error) {
      logger.error('Email verification error:', error);
      throw error;
    }
  }

  static async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<void> {
    try {
      // Get user
      const user = await UserModel.findById(userId);
      if (!user) {
        throw createError('User not found', 404);
      }

      // Verify current password using encryption service
      const isCurrentPasswordValid = await EncryptionService.verifyPassword(currentPassword, user.password_hash);
      if (!isCurrentPasswordValid) {
        throw createError('Current password is incorrect', 400);
      }

      // Hash new password using encryption service
      const passwordHash = await EncryptionService.hashPassword(newPassword);

      // Update password
      await UserModel.update(userId, { password_hash: passwordHash });

      // Revoke all refresh tokens for this user (force re-login)
      await RefreshTokenModel.revokeAllForUser(userId);

      logger.info(`Password changed for user: ${user.email}`);
    } catch (error) {
      logger.error('Change password error:', error);
      throw error;
    }
  }

  private static async generateTokens(user: User): Promise<AuthTokens> {
    const payload = {
      id: user.id,
      email: user.email,
      role: user.role,
    };

    // Generate access token
    const accessToken = jwt.sign(payload, this.JWT_SECRET, {
      expiresIn: this.JWT_EXPIRES_IN,
    } as jwt.SignOptions);

    // Generate refresh token
    const refreshTokenPayload = {
      userId: user.id,
      type: 'refresh',
    };

    const refreshToken = jwt.sign(refreshTokenPayload, this.JWT_REFRESH_SECRET, {
      expiresIn: this.JWT_REFRESH_EXPIRES_IN,
    } as jwt.SignOptions);

    // Store refresh token in database
    const expiresAt = new Date(Date.now() + this.parseExpirationTime(this.JWT_REFRESH_EXPIRES_IN));
    await RefreshTokenModel.create({
      user_id: user.id,
      token: refreshToken,
      expires_at: expiresAt,
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: this.parseExpirationTime(this.JWT_EXPIRES_IN),
    };
  }

  private static async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, this.SALT_ROUNDS);
  }

  private static async verifyPassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  private static generateVerificationToken(): string {
    return crypto.randomBytes(32).toString('hex');
  }

  private static parseExpirationTime(expiration: string): number {
    const unit = expiration.slice(-1);
    const value = parseInt(expiration.slice(0, -1));

    switch (unit) {
      case 's':
        return value * 1000;
      case 'm':
        return value * 60 * 1000;
      case 'h':
        return value * 60 * 60 * 1000;
      case 'd':
        return value * 24 * 60 * 60 * 1000;
      default:
        return 15 * 60 * 1000; // Default 15 minutes
    }
  }

  private static sanitizeUser(user: User): Omit<User, 'password_hash' | 'email_verification_token' | 'password_reset_token'> {
    const { password_hash, email_verification_token, password_reset_token, ...sanitizedUser } = user;
    return sanitizedUser;
  }
}