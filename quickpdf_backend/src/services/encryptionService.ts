import crypto from 'crypto';
import CryptoJS from 'crypto-js';
import bcrypt from 'bcryptjs';
import { logger } from '@/utils/logger';

export interface EncryptionConfig {
  algorithm: string;
  keyLength: number;
  ivLength: number;
  saltLength: number;
  iterations: number;
}

export interface EncryptedData {
  encrypted: string;
  iv: string;
  salt?: string;
  tag?: string;
}

export class EncryptionService {
  private static readonly config: EncryptionConfig = {
    algorithm: 'aes-256-gcm',
    keyLength: 32, // 256 bits
    ivLength: 16,  // 128 bits
    saltLength: 32, // 256 bits
    iterations: 100000, // PBKDF2 iterations
  };

  private static readonly masterKey = process.env.ENCRYPTION_KEY || 'default-key-change-in-production';

  /**
   * Generates a cryptographically secure random key
   */
  static generateKey(length: number = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * Generates a cryptographically secure random salt
   */
  static generateSalt(length: number = 32): string {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * Derives a key from password using PBKDF2
   */
  static deriveKey(password: string, salt: string): Buffer {
    return crypto.pbkdf2Sync(
      password,
      salt,
      this.config.iterations,
      this.config.keyLength,
      'sha512'
    );
  }

  /**
   * Encrypts sensitive data using AES-256-CBC
   */
  static encryptSensitiveData(data: string, userKey?: string): EncryptedData {
    try {
      const key = userKey ? Buffer.from(userKey, 'hex') : crypto.scryptSync(this.masterKey, 'salt', 32);
      const iv = crypto.randomBytes(this.config.ivLength);
      
      const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
      
      let encrypted = cipher.update(data, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      return {
        encrypted,
        iv: iv.toString('hex'),
      };
    } catch (error) {
      logger.error('Encryption failed:', error);
      throw new Error('Failed to encrypt sensitive data');
    }
  }

  /**
   * Decrypts sensitive data using AES-256-CBC
   */
  static decryptSensitiveData(encryptedData: EncryptedData, userKey?: string): string {
    try {
      const key = userKey ? Buffer.from(userKey, 'hex') : crypto.scryptSync(this.masterKey, 'salt', 32);
      const iv = Buffer.from(encryptedData.iv, 'hex');
      
      const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
      
      let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      logger.error('Decryption failed:', error);
      throw new Error('Failed to decrypt sensitive data');
    }
  }

  /**
   * Encrypts user data with password-based encryption
   */
  static encryptUserData(data: string, password: string): EncryptedData {
    try {
      const salt = this.generateSalt();
      const key = this.deriveKey(password, salt);
      const iv = crypto.randomBytes(this.config.ivLength);
      
      const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
      
      let encrypted = cipher.update(data, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      return {
        encrypted,
        iv: iv.toString('hex'),
        salt,
      };
    } catch (error) {
      logger.error('User data encryption failed:', error);
      throw new Error('Failed to encrypt user data');
    }
  }

  /**
   * Decrypts user data with password-based encryption
   */
  static decryptUserData(encryptedData: EncryptedData, password: string): string {
    try {
      const key = this.deriveKey(password, encryptedData.salt!);
      const iv = Buffer.from(encryptedData.iv, 'hex');
      
      const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
      
      let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      logger.error('User data decryption failed:', error);
      throw new Error('Failed to decrypt user data');
    }
  }

  /**
   * Hashes passwords with bcrypt and salt
   */
  static async hashPassword(password: string): Promise<string> {
    try {
      const saltRounds = 12; // High security level
      return await bcrypt.hash(password, saltRounds);
    } catch (error) {
      logger.error('Password hashing failed:', error);
      throw new Error('Failed to hash password');
    }
  }

  /**
   * Verifies password against hash
   */
  static async verifyPassword(password: string, hash: string): Promise<boolean> {
    try {
      return await bcrypt.compare(password, hash);
    } catch (error) {
      logger.error('Password verification failed:', error);
      return false;
    }
  }

  /**
   * Encrypts database fields that contain sensitive information
   */
  static encryptDatabaseField(value: string): string {
    if (!value) return value;
    
    try {
      const encrypted = this.encryptSensitiveData(value);
      return JSON.stringify(encrypted);
    } catch (error) {
      logger.error('Database field encryption failed:', error);
      throw new Error('Failed to encrypt database field');
    }
  }

  /**
   * Decrypts database fields that contain sensitive information
   */
  static decryptDatabaseField(encryptedValue: string): string {
    if (!encryptedValue) return encryptedValue;
    
    try {
      const encryptedData: EncryptedData = JSON.parse(encryptedValue);
      return this.decryptSensitiveData(encryptedData);
    } catch (error) {
      logger.error('Database field decryption failed:', error);
      throw new Error('Failed to decrypt database field');
    }
  }

  /**
   * Creates a secure session token
   */
  static createSecureToken(payload: any, expiresIn: string = '1h'): string {
    try {
      const secret = process.env.JWT_SECRET || 'default-jwt-secret';
      const token = CryptoJS.AES.encrypt(
        JSON.stringify({
          ...payload,
          exp: Date.now() + this.parseExpirationTime(expiresIn),
          iat: Date.now(),
        }),
        secret
      ).toString();
      
      return token;
    } catch (error) {
      logger.error('Token creation failed:', error);
      throw new Error('Failed to create secure token');
    }
  }

  /**
   * Verifies and decodes a secure session token
   */
  static verifySecureToken(token: string): any {
    try {
      const secret = process.env.JWT_SECRET || 'default-jwt-secret';
      const decrypted = CryptoJS.AES.decrypt(token, secret);
      const payload = JSON.parse(decrypted.toString(CryptoJS.enc.Utf8));
      
      if (payload.exp && Date.now() > payload.exp) {
        throw new Error('Token expired');
      }
      
      return payload;
    } catch (error) {
      logger.error('Token verification failed:', error);
      throw new Error('Invalid or expired token');
    }
  }

  /**
   * Encrypts file content before storage
   */
  static encryptFileContent(content: Buffer): EncryptedData {
    try {
      const encrypted = this.encryptSensitiveData(content.toString('base64'));
      return encrypted;
    } catch (error) {
      logger.error('File encryption failed:', error);
      throw new Error('Failed to encrypt file content');
    }
  }

  /**
   * Decrypts file content after retrieval
   */
  static decryptFileContent(encryptedData: EncryptedData): Buffer {
    try {
      const decrypted = this.decryptSensitiveData(encryptedData);
      return Buffer.from(decrypted, 'base64');
    } catch (error) {
      logger.error('File decryption failed:', error);
      throw new Error('Failed to decrypt file content');
    }
  }

  /**
   * Generates a secure API key
   */
  static generateApiKey(): string {
    const timestamp = Date.now().toString();
    const randomBytes = crypto.randomBytes(32).toString('hex');
    const combined = `${timestamp}-${randomBytes}`;
    
    return crypto.createHash('sha256').update(combined).digest('hex');
  }

  /**
   * Creates a hash for data integrity verification
   */
  static createIntegrityHash(data: string): string {
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  /**
   * Verifies data integrity using hash
   */
  static verifyIntegrity(data: string, hash: string): boolean {
    const computedHash = this.createIntegrityHash(data);
    return crypto.timingSafeEqual(
      Buffer.from(hash, 'hex'),
      Buffer.from(computedHash, 'hex')
    );
  }

  /**
   * Parses expiration time string to milliseconds
   */
  private static parseExpirationTime(expiresIn: string): number {
    const units: { [key: string]: number } = {
      's': 1000,
      'm': 60 * 1000,
      'h': 60 * 60 * 1000,
      'd': 24 * 60 * 60 * 1000,
    };

    const match = expiresIn.match(/^(\d+)([smhd])$/);
    if (!match) {
      throw new Error('Invalid expiration time format');
    }

    const [, value, unit] = match;
    return parseInt(value) * units[unit];
  }
}

export default EncryptionService;