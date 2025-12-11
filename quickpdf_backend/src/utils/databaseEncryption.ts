import { EncryptionService } from '@/services/encryptionService';
import { logger } from './logger';

/**
 * Database field encryption utilities
 * Provides transparent encryption/decryption for sensitive database fields
 */

export interface EncryptedField {
  value: string;
  encrypted: boolean;
}

export class DatabaseEncryption {
  // Fields that should be encrypted in the database
  private static readonly ENCRYPTED_FIELDS = new Set([
    'email',
    'phone',
    'full_name',
    'address',
    'payment_info',
    'bank_details',
    'personal_data',
    'sensitive_content',
  ]);

  /**
   * Encrypts a field value if it's marked as sensitive
   */
  static encryptField(fieldName: string, value: any): any {
    if (!value || typeof value !== 'string') {
      return value;
    }

    if (this.ENCRYPTED_FIELDS.has(fieldName)) {
      try {
        return EncryptionService.encryptDatabaseField(value);
      } catch (error) {
        logger.error(`Failed to encrypt field ${fieldName}:`, error);
        throw new Error(`Database encryption failed for field: ${fieldName}`);
      }
    }

    return value;
  }

  /**
   * Decrypts a field value if it's encrypted
   */
  static decryptField(fieldName: string, value: any): any {
    if (!value || typeof value !== 'string') {
      return value;
    }

    if (this.ENCRYPTED_FIELDS.has(fieldName)) {
      try {
        // Check if the value is actually encrypted (JSON format)
        if (this.isEncryptedValue(value)) {
          return EncryptionService.decryptDatabaseField(value);
        }
      } catch (error) {
        logger.error(`Failed to decrypt field ${fieldName}:`, error);
        // Return original value if decryption fails (for backward compatibility)
        return value;
      }
    }

    return value;
  }

  /**
   * Encrypts all sensitive fields in an object
   */
  static encryptObject(data: Record<string, any>): Record<string, any> {
    const encrypted: Record<string, any> = {};

    for (const [key, value] of Object.entries(data)) {
      encrypted[key] = this.encryptField(key, value);
    }

    return encrypted;
  }

  /**
   * Decrypts all sensitive fields in an object
   */
  static decryptObject(data: Record<string, any>): Record<string, any> {
    const decrypted: Record<string, any> = {};

    for (const [key, value] of Object.entries(data)) {
      decrypted[key] = this.decryptField(key, value);
    }

    return decrypted;
  }

  /**
   * Encrypts sensitive fields in an array of objects
   */
  static encryptArray(data: Record<string, any>[]): Record<string, any>[] {
    return data.map(item => this.encryptObject(item));
  }

  /**
   * Decrypts sensitive fields in an array of objects
   */
  static decryptArray(data: Record<string, any>[]): Record<string, any>[] {
    return data.map(item => this.decryptObject(item));
  }

  /**
   * Checks if a value is encrypted (has the expected JSON structure)
   */
  private static isEncryptedValue(value: string): boolean {
    try {
      const parsed = JSON.parse(value);
      return (
        typeof parsed === 'object' &&
        parsed !== null &&
        'encrypted' in parsed &&
        'iv' in parsed
      );
    } catch {
      return false;
    }
  }

  /**
   * Adds a field to the encryption list
   */
  static addEncryptedField(fieldName: string): void {
    this.ENCRYPTED_FIELDS.add(fieldName);
    logger.info(`Added field to encryption list: ${fieldName}`);
  }

  /**
   * Removes a field from the encryption list
   */
  static removeEncryptedField(fieldName: string): void {
    this.ENCRYPTED_FIELDS.delete(fieldName);
    logger.info(`Removed field from encryption list: ${fieldName}`);
  }

  /**
   * Gets the list of encrypted fields
   */
  static getEncryptedFields(): string[] {
    return Array.from(this.ENCRYPTED_FIELDS);
  }

  /**
   * Creates a database query with encrypted search capability
   */
  static createEncryptedSearch(fieldName: string, searchValue: string): any {
    if (!this.ENCRYPTED_FIELDS.has(fieldName)) {
      // Regular search for non-encrypted fields
      return { [fieldName]: { $regex: searchValue, $options: 'i' } };
    }

    // For encrypted fields, we need to encrypt the search value
    // Note: This is a simplified approach. In practice, you might need
    // to implement searchable encryption or use field-level encryption
    // with deterministic encryption for exact matches only.
    try {
      const encryptedValue = EncryptionService.encryptDatabaseField(searchValue);
      return { [fieldName]: encryptedValue };
    } catch (error) {
      logger.error(`Failed to create encrypted search for ${fieldName}:`, error);
      throw new Error(`Encrypted search failed for field: ${fieldName}`);
    }
  }

  /**
   * Migrates existing unencrypted data to encrypted format
   */
  static async migrateToEncrypted(
    collection: any,
    batchSize: number = 100
  ): Promise<void> {
    try {
      logger.info('Starting database encryption migration');
      
      let processed = 0;
      let batch = 0;

      // This is a conceptual implementation
      // In practice, you'd need to adapt this to your specific database
      const cursor = collection.find({}).limit(batchSize);
      
      while (await cursor.hasNext()) {
        const documents = [];
        
        for (let i = 0; i < batchSize && await cursor.hasNext(); i++) {
          documents.push(await cursor.next());
        }

        // Process batch
        const updates = documents.map(doc => {
          const encryptedDoc = this.encryptObject(doc);
          return {
            updateOne: {
              filter: { _id: doc._id },
              update: { $set: encryptedDoc }
            }
          };
        });

        if (updates.length > 0) {
          await collection.bulkWrite(updates);
          processed += updates.length;
          batch++;
          
          logger.info(`Encryption migration progress: ${processed} documents processed (batch ${batch})`);
        }
      }

      logger.info(`Database encryption migration completed: ${processed} documents processed`);
    } catch (error) {
      logger.error('Database encryption migration failed:', error);
      throw error;
    }
  }

  /**
   * Validates encrypted data integrity
   */
  static validateEncryptedData(data: Record<string, any>): boolean {
    try {
      for (const [fieldName, value] of Object.entries(data)) {
        if (this.ENCRYPTED_FIELDS.has(fieldName) && value) {
          // Try to decrypt to validate integrity
          this.decryptField(fieldName, value);
        }
      }
      return true;
    } catch (error) {
      logger.error('Encrypted data validation failed:', error);
      return false;
    }
  }
}

export default DatabaseEncryption;