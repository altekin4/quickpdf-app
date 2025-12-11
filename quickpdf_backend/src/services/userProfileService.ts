import { UserModel, User, UpdateUserData } from '@/models/User';
import { AuthService } from './authService';
import { logger } from '@/utils/logger';
import { createError } from '@/middleware/errorHandler';
import path from 'path';
import fs from 'fs/promises';
import crypto from 'crypto';

export interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  phone?: string;
  role: 'user' | 'creator' | 'admin';
  is_verified: boolean;
  is_active: boolean;
  balance: number;
  total_earnings: number;
  profile_picture_url?: string;
  created_at: Date;
  updated_at: Date;
  last_login?: Date;
}

export interface UpdateProfileData {
  fullName?: string;
  phone?: string;
}

export interface UserSettings {
  emailNotifications: boolean;
  marketingEmails: boolean;
  language: string;
  timezone: string;
  currency: string;
}

export interface UserPreferences {
  theme: 'light' | 'dark' | 'auto';
  defaultTemplateCategory?: string;
  autoSaveDocuments: boolean;
  documentRetentionDays: number;
}

export class UserProfileService {
  private static readonly UPLOAD_DIR = process.env.UPLOAD_PATH || './uploads';
  private static readonly PROFILE_PICTURES_DIR = path.join(this.UPLOAD_DIR, 'profiles');
  private static readonly MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
  private static readonly ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];

  static async getProfile(userId: string): Promise<UserProfile> {
    try {
      const user = await UserModel.findById(userId);
      if (!user) {
        throw createError('User not found', 404);
      }

      return this.sanitizeUserProfile(user);
    } catch (error) {
      logger.error('Error getting user profile:', error);
      throw error;
    }
  }

  static async updateProfile(userId: string, updateData: UpdateProfileData): Promise<UserProfile> {
    try {
      const user = await UserModel.findById(userId);
      if (!user) {
        throw createError('User not found', 404);
      }

      const dbUpdateData: UpdateUserData = {};
      if (updateData.fullName) dbUpdateData.full_name = updateData.fullName;
      if (updateData.phone) dbUpdateData.phone = updateData.phone;

      const updatedUser = await UserModel.update(userId, dbUpdateData);
      if (!updatedUser) {
        throw createError('Failed to update profile', 500);
      }

      logger.info(`Profile updated for user: ${updatedUser.email}`);
      return this.sanitizeUserProfile(updatedUser);
    } catch (error) {
      logger.error('Error updating user profile:', error);
      throw error;
    }
  }

  static async uploadProfilePicture(userId: string, file: Express.Multer.File): Promise<string> {
    try {
      // Validate file
      this.validateProfilePicture(file);

      // Ensure upload directory exists
      await this.ensureUploadDirectory();

      // Generate unique filename
      const fileExtension = path.extname(file.originalname).toLowerCase();
      const fileName = `${userId}_${Date.now()}_${crypto.randomBytes(8).toString('hex')}${fileExtension}`;
      const filePath = path.join(this.PROFILE_PICTURES_DIR, fileName);

      // Save file
      await fs.writeFile(filePath, file.buffer);

      // Update user profile with new picture URL
      const profilePictureUrl = `/uploads/profiles/${fileName}`;
      await UserModel.update(userId, { profile_picture_url: profilePictureUrl });

      logger.info(`Profile picture uploaded for user: ${userId}`);
      return profilePictureUrl;
    } catch (error) {
      logger.error('Error uploading profile picture:', error);
      throw error;
    }
  }

  static async deleteProfilePicture(userId: string): Promise<void> {
    try {
      const user = await UserModel.findById(userId);
      if (!user) {
        throw createError('User not found', 404);
      }

      if (user.profile_picture_url) {
        // Delete file from filesystem
        const fileName = path.basename(user.profile_picture_url);
        const filePath = path.join(this.PROFILE_PICTURES_DIR, fileName);
        
        try {
          await fs.unlink(filePath);
        } catch (error) {
          logger.warn(`Failed to delete profile picture file: ${filePath}`, error);
        }

        // Remove URL from database
        await UserModel.update(userId, { profile_picture_url: undefined });
      }

      logger.info(`Profile picture deleted for user: ${userId}`);
    } catch (error) {
      logger.error('Error deleting profile picture:', error);
      throw error;
    }
  }

  static async getUserSettings(userId: string): Promise<UserSettings> {
    try {
      // TODO: Implement user settings storage
      // For now, return default settings
      return {
        emailNotifications: true,
        marketingEmails: false,
        language: 'tr',
        timezone: 'Europe/Istanbul',
        currency: 'TRY',
      };
    } catch (error) {
      logger.error('Error getting user settings:', error);
      throw error;
    }
  }

  static async updateUserSettings(userId: string, settings: Partial<UserSettings>): Promise<UserSettings> {
    try {
      // TODO: Implement user settings storage
      // For now, return the provided settings merged with defaults
      const currentSettings = await this.getUserSettings(userId);
      const updatedSettings = { ...currentSettings, ...settings };

      logger.info(`Settings updated for user: ${userId}`);
      return updatedSettings;
    } catch (error) {
      logger.error('Error updating user settings:', error);
      throw error;
    }
  }

  static async getUserPreferences(userId: string): Promise<UserPreferences> {
    try {
      // TODO: Implement user preferences storage
      // For now, return default preferences
      return {
        theme: 'light',
        autoSaveDocuments: true,
        documentRetentionDays: 90,
      };
    } catch (error) {
      logger.error('Error getting user preferences:', error);
      throw error;
    }
  }

  static async updateUserPreferences(userId: string, preferences: Partial<UserPreferences>): Promise<UserPreferences> {
    try {
      // TODO: Implement user preferences storage
      // For now, return the provided preferences merged with defaults
      const currentPreferences = await this.getUserPreferences(userId);
      const updatedPreferences = { ...currentPreferences, ...preferences };

      logger.info(`Preferences updated for user: ${userId}`);
      return updatedPreferences;
    } catch (error) {
      logger.error('Error updating user preferences:', error);
      throw error;
    }
  }

  static async deleteAccount(userId: string, password: string): Promise<void> {
    try {
      const user = await UserModel.findById(userId);
      if (!user) {
        throw createError('User not found', 404);
      }

      // Verify password before deletion
      const bcrypt = require('bcryptjs');
      const isPasswordValid = await bcrypt.compare(password, user.password_hash);
      if (!isPasswordValid) {
        throw createError('Invalid password', 400);
      }

      // Delete profile picture if exists
      if (user.profile_picture_url) {
        await this.deleteProfilePicture(userId);
      }

      // TODO: Handle related data cleanup (documents, templates, etc.)
      // This should be done in a transaction

      // Delete user account
      const deleted = await UserModel.delete(userId);
      if (!deleted) {
        throw createError('Failed to delete account', 500);
      }

      logger.info(`Account deleted for user: ${user.email}`);
    } catch (error) {
      logger.error('Error deleting user account:', error);
      throw error;
    }
  }

  static async getAccountSummary(userId: string): Promise<{
    profile: UserProfile;
    stats: any;
    settings: UserSettings;
    preferences: UserPreferences;
  }> {
    try {
      const [profile, stats, settings, preferences] = await Promise.all([
        this.getProfile(userId),
        UserModel.getUserStats(userId),
        this.getUserSettings(userId),
        this.getUserPreferences(userId),
      ]);

      return {
        profile,
        stats,
        settings,
        preferences,
      };
    } catch (error) {
      logger.error('Error getting account summary:', error);
      throw error;
    }
  }

  private static validateProfilePicture(file: Express.Multer.File): void {
    if (!file) {
      throw createError('No file provided', 400);
    }

    if (file.size > this.MAX_FILE_SIZE) {
      throw createError('File size too large. Maximum size is 5MB', 400);
    }

    const fileExtension = path.extname(file.originalname).toLowerCase();
    if (!this.ALLOWED_EXTENSIONS.includes(fileExtension)) {
      throw createError('Invalid file type. Only JPG, PNG, and WebP files are allowed', 400);
    }

    // Validate MIME type
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!allowedMimeTypes.includes(file.mimetype)) {
      throw createError('Invalid file type', 400);
    }
  }

  private static async ensureUploadDirectory(): Promise<void> {
    try {
      await fs.mkdir(this.PROFILE_PICTURES_DIR, { recursive: true });
    } catch (error) {
      logger.error('Error creating upload directory:', error);
      throw createError('Failed to create upload directory', 500);
    }
  }

  private static sanitizeUserProfile(user: User): UserProfile {
    const { password_hash, email_verification_token, password_reset_token, password_reset_expires, ...profile } = user;
    return profile;
  }
}