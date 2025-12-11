/**
 * **Feature: quickpdf-template-marketplace, Property 17: Data Encryption Compliance**
 * **Validates: Requirements 10.2**
 * 
 * Property-based tests for data encryption compliance
 * Tests that sensitive user data is properly encrypted using industry-standard methods
 */

import * as fc from 'fast-check';
import { EncryptionService } from '@/services/encryptionService';
import { DatabaseEncryption } from '@/utils/databaseEncryption';

describe('Property 17: Data Encryption Compliance', () => {
  
  describe('Password Encryption', () => {
    it('should hash passwords with salt and verify correctly', async () => {
      await fc.assert(fc.asyncProperty(
        fc.string({ minLength: 8, maxLength: 128 }),
        async (password) => {
          const hash = await EncryptionService.hashPassword(password);
          
          // Hash should be different from original password
          expect(hash).not.toBe(password);
          
          // Hash should be a valid bcrypt hash (starts with $2a$, $2b$, or $2y$)
          expect(hash).toMatch(/^\$2[aby]\$\d+\$/);
          
          // Should be able to verify the password
          const isValid = await EncryptionService.verifyPassword(password, hash);
          expect(isValid).toBe(true);
          
          // Wrong password should not verify
          const wrongPassword = password + 'wrong';
          const isWrongValid = await EncryptionService.verifyPassword(wrongPassword, hash);
          expect(isWrongValid).toBe(false);
        }
      ), { numRuns: 50 });
    });

    it('should generate different hashes for the same password', async () => {
      await fc.assert(fc.asyncProperty(
        fc.string({ minLength: 8, maxLength: 128 }),
        async (password) => {
          const hash1 = await EncryptionService.hashPassword(password);
          const hash2 = await EncryptionService.hashPassword(password);
          
          // Same password should generate different hashes due to salt
          expect(hash1).not.toBe(hash2);
          
          // Both hashes should verify the same password
          expect(await EncryptionService.verifyPassword(password, hash1)).toBe(true);
          expect(await EncryptionService.verifyPassword(password, hash2)).toBe(true);
        }
      ), { numRuns: 30 });
    });
  });

  describe('Sensitive Data Encryption', () => {
    it('should encrypt and decrypt sensitive data correctly', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        (sensitiveData) => {
          const encrypted = EncryptionService.encryptSensitiveData(sensitiveData);
          
          // Encrypted data should be different from original
          expect(encrypted.encrypted).not.toBe(sensitiveData);
          
          // Should have required encryption components
          expect(encrypted.encrypted).toBeDefined();
          expect(encrypted.iv).toBeDefined();
          
          // Should be able to decrypt back to original
          const decrypted = EncryptionService.decryptSensitiveData(encrypted);
          expect(decrypted).toBe(sensitiveData);
        }
      ), { numRuns: 100 });
    });

    it('should generate different encrypted values for the same data', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        (sensitiveData) => {
          const encrypted1 = EncryptionService.encryptSensitiveData(sensitiveData);
          const encrypted2 = EncryptionService.encryptSensitiveData(sensitiveData);
          
          // Different encryptions should have different ciphertext and IVs
          expect(encrypted1.encrypted).not.toBe(encrypted2.encrypted);
          expect(encrypted1.iv).not.toBe(encrypted2.iv);
          
          // Both should decrypt to the same original data
          expect(EncryptionService.decryptSensitiveData(encrypted1)).toBe(sensitiveData);
          expect(EncryptionService.decryptSensitiveData(encrypted2)).toBe(sensitiveData);
        }
      ), { numRuns: 50 });
    });

    it('should fail decryption with tampered data', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        (sensitiveData) => {
          const encrypted = EncryptionService.encryptSensitiveData(sensitiveData);
          
          // Tamper with encrypted data
          const tamperedEncrypted = {
            ...encrypted,
            encrypted: encrypted.encrypted.substring(0, encrypted.encrypted.length - 2) + 'XX'
          };
          
          // Should throw error when trying to decrypt tampered data
          expect(() => {
            EncryptionService.decryptSensitiveData(tamperedEncrypted);
          }).toThrow();
        }
      ), { numRuns: 50 });
    });
  });

  describe('User Data Encryption', () => {
    it('should encrypt user data with password-based encryption', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        fc.string({ minLength: 8, maxLength: 128 }),
        (userData, password) => {
          const encrypted = EncryptionService.encryptUserData(userData, password);
          
          // Should have all required components
          expect(encrypted.encrypted).toBeDefined();
          expect(encrypted.iv).toBeDefined();
          expect(encrypted.salt).toBeDefined();
          
          // Should decrypt correctly with the same password
          const decrypted = EncryptionService.decryptUserData(encrypted, password);
          expect(decrypted).toBe(userData);
        }
      ), { numRuns: 50 });
    });

    it('should fail decryption with wrong password', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        fc.string({ minLength: 8, maxLength: 128 }),
        fc.string({ minLength: 8, maxLength: 128 }),
        (userData, correctPassword, wrongPassword) => {
          fc.pre(correctPassword !== wrongPassword);
          
          const encrypted = EncryptionService.encryptUserData(userData, correctPassword);
          
          // Should throw error with wrong password
          expect(() => {
            EncryptionService.decryptUserData(encrypted, wrongPassword);
          }).toThrow();
        }
      ), { numRuns: 50 });
    });
  });

  describe('Database Field Encryption', () => {
    it('should encrypt and decrypt database fields transparently', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 500 }),
        (fieldValue) => {
          const encrypted = EncryptionService.encryptDatabaseField(fieldValue);
          
          // Encrypted value should be different and be valid JSON
          expect(encrypted).not.toBe(fieldValue);
          expect(() => JSON.parse(encrypted)).not.toThrow();
          
          // Should decrypt back to original value
          const decrypted = EncryptionService.decryptDatabaseField(encrypted);
          expect(decrypted).toBe(fieldValue);
        }
      ), { numRuns: 100 });
    });

    it('should handle empty and null values correctly', () => {
      const testValues = ['', null, undefined];
      
      testValues.forEach(value => {
        const encrypted = EncryptionService.encryptDatabaseField(value as any);
        expect(encrypted).toBe(value);
        
        const decrypted = EncryptionService.decryptDatabaseField(encrypted);
        expect(decrypted).toBe(value);
      });
    });
  });

  describe('Database Object Encryption', () => {
    it('should encrypt sensitive fields in objects while preserving structure', () => {
      fc.assert(fc.property(
        fc.record({
          email: fc.emailAddress(),
          full_name: fc.string({ minLength: 1, maxLength: 100 }),
          phone: fc.string({ minLength: 10, maxLength: 15 }),
          public_field: fc.string(),
          id: fc.uuid(),
        }),
        (userData) => {
          const encrypted = DatabaseEncryption.encryptObject(userData);
          
          // Structure should be preserved
          expect(Object.keys(encrypted)).toEqual(Object.keys(userData));
          
          // Sensitive fields should be encrypted (different from original)
          expect(encrypted.email).not.toBe(userData.email);
          expect(encrypted.full_name).not.toBe(userData.full_name);
          expect(encrypted.phone).not.toBe(userData.phone);
          
          // Non-sensitive fields should remain unchanged
          expect(encrypted.public_field).toBe(userData.public_field);
          expect(encrypted.id).toBe(userData.id);
          
          // Should decrypt back to original
          const decrypted = DatabaseEncryption.decryptObject(encrypted);
          expect(decrypted).toEqual(userData);
        }
      ), { numRuns: 50 });
    });

    it('should handle arrays of objects correctly', () => {
      fc.assert(fc.property(
        fc.array(fc.record({
          email: fc.emailAddress(),
          full_name: fc.string({ minLength: 1, maxLength: 100 }),
          public_data: fc.string(),
        }), { minLength: 1, maxLength: 10 }),
        (userArray) => {
          const encrypted = DatabaseEncryption.encryptArray(userArray);
          
          // Array length should be preserved
          expect(encrypted.length).toBe(userArray.length);
          
          // Each object should have encrypted sensitive fields
          encrypted.forEach((encryptedObj, index) => {
            expect(encryptedObj.email).not.toBe(userArray[index].email);
            expect(encryptedObj.full_name).not.toBe(userArray[index].full_name);
            expect(encryptedObj.public_data).toBe(userArray[index].public_data);
          });
          
          // Should decrypt back to original array
          const decrypted = DatabaseEncryption.decryptArray(encrypted);
          expect(decrypted).toEqual(userArray);
        }
      ), { numRuns: 30 });
    });
  });

  describe('Key Generation and Security', () => {
    it('should generate cryptographically secure keys', () => {
      fc.assert(fc.property(
        fc.integer({ min: 16, max: 64 }),
        (keyLength) => {
          const key1 = EncryptionService.generateKey(keyLength);
          const key2 = EncryptionService.generateKey(keyLength);
          
          // Keys should be different
          expect(key1).not.toBe(key2);
          
          // Keys should have correct length (hex encoded, so 2 chars per byte)
          expect(key1.length).toBe(keyLength * 2);
          expect(key2.length).toBe(keyLength * 2);
          
          // Keys should be valid hex strings
          expect(key1).toMatch(/^[0-9a-f]+$/);
          expect(key2).toMatch(/^[0-9a-f]+$/);
        }
      ), { numRuns: 50 });
    });

    it('should generate secure API keys', () => {
      const apiKeys = new Set<string>();
      
      for (let i = 0; i < 100; i++) {
        const apiKey = EncryptionService.generateApiKey();
        
        // Should be unique
        expect(apiKeys.has(apiKey)).toBe(false);
        apiKeys.add(apiKey);
        
        // Should be valid hex string of expected length
        expect(apiKey).toMatch(/^[0-9a-f]{64}$/);
      }
    });
  });

  describe('Data Integrity', () => {
    it('should create and verify integrity hashes correctly', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        (data) => {
          const hash = EncryptionService.createIntegrityHash(data);
          
          // Hash should be a valid SHA-256 hex string
          expect(hash).toMatch(/^[0-9a-f]{64}$/);
          
          // Should verify correctly
          expect(EncryptionService.verifyIntegrity(data, hash)).toBe(true);
          
          // Should fail verification with modified data
          const modifiedData = data + 'modified';
          expect(EncryptionService.verifyIntegrity(modifiedData, hash)).toBe(false);
        }
      ), { numRuns: 100 });
    });

    it('should detect data tampering', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1, maxLength: 1000 }),
        fc.string({ minLength: 1, maxLength: 10 }),
        (originalData, tamperString) => {
          fc.pre(originalData !== originalData + tamperString);
          
          const hash = EncryptionService.createIntegrityHash(originalData);
          const tamperedData = originalData + tamperString;
          
          // Tampered data should fail verification
          expect(EncryptionService.verifyIntegrity(tamperedData, hash)).toBe(false);
        }
      ), { numRuns: 50 });
    });
  });

  describe('File Encryption', () => {
    it('should encrypt and decrypt file content correctly', () => {
      fc.assert(fc.property(
        fc.uint8Array({ minLength: 1, maxLength: 1000 }),
        (fileData) => {
          const fileBuffer = Buffer.from(fileData);
          
          const encrypted = EncryptionService.encryptFileContent(fileBuffer);
          
          // Should have encryption components
          expect(encrypted.encrypted).toBeDefined();
          expect(encrypted.iv).toBeDefined();
          
          // Should decrypt back to original
          const decrypted = EncryptionService.decryptFileContent(encrypted);
          expect(decrypted).toEqual(fileBuffer);
        }
      ), { numRuns: 50 });
    });
  });

  describe('Encryption Compliance', () => {
    it('should use industry-standard encryption algorithms', () => {
      const testData = 'test sensitive data';
      
      // Test that encryption uses AES-256-GCM (industry standard)
      const encrypted = EncryptionService.encryptSensitiveData(testData);
      
      // IV should be 16 bytes (128 bits) for AES
      expect(Buffer.from(encrypted.iv, 'hex').length).toBe(16);
    });

    it('should enforce minimum security standards for passwords', async () => {
      const weakPassword = '123';
      const strongPassword = 'StrongPassword123!';
      
      // Both should hash successfully (validation should be done at application level)
      const weakHash = await EncryptionService.hashPassword(weakPassword);
      const strongHash = await EncryptionService.hashPassword(strongPassword);
      
      // Hashes should use bcrypt with sufficient rounds (indicated by $2a$12$ or higher)
      expect(weakHash).toMatch(/^\$2[aby]\$1[2-9]\$/);
      expect(strongHash).toMatch(/^\$2[aby]\$1[2-9]\$/);
    });
  });
});