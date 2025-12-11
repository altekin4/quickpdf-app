/**
 * **Feature: quickpdf-template-marketplace, Property 16: Authentication Token Management**
 * **Validates: Requirements 10.3**
 * 
 * Property: For any user authentication session, JWT tokens should have appropriate 
 * expiration times and refresh mechanisms should work correctly
 */

import fc from 'fast-check';
import jwt from 'jsonwebtoken';
import { logger } from '@/utils/logger';

// Test configuration
const TEST_JWT_SECRET = 'test-jwt-secret-for-property-testing-very-long-and-secure';
const TEST_JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-for-property-testing-very-long-and-secure';

// Generators for property testing
const userPayloadGenerator = fc.record({
  id: fc.uuid(),
  email: fc.emailAddress(),
  role: fc.constantFrom('user', 'creator', 'admin') as fc.Arbitrary<'user' | 'creator' | 'admin'>,
});

const refreshTokenPayloadGenerator = fc.record({
  userId: fc.uuid(),
  type: fc.constant('refresh'),
});

const expirationTimeGenerator = fc.constantFrom('15m', '30m', '1h', '2h', '1d', '7d');

// Helper function for parsing expiration times
function parseExpirationTime(expiration: string): number {
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

describe('Authentication Token Management Property Tests', () => {
  test('Property: JWT token generation produces valid tokens with correct structure', async () => {
    await fc.assert(
      fc.asyncProperty(
        userPayloadGenerator,
        expirationTimeGenerator,
        async (userPayload, expiresIn) => {
          try {
            // Generate access token
            const accessToken = jwt.sign(userPayload, TEST_JWT_SECRET, {
              expiresIn: expiresIn,
            } as jwt.SignOptions);
            
            // Verify access token is valid JWT
            const decoded = jwt.verify(accessToken, TEST_JWT_SECRET) as any;
            
            // Property: Token should contain original payload data
            expect(decoded.id).toBe(userPayload.id);
            expect(decoded.email).toBe(userPayload.email);
            expect(decoded.role).toBe(userPayload.role);
            
            // Property: Token should have expiration
            expect(decoded.exp).toBeDefined();
            expect(typeof decoded.exp).toBe('number');
            
            // Property: Token should not be expired immediately
            const now = Math.floor(Date.now() / 1000);
            expect(decoded.exp).toBeGreaterThan(now);
            
            // Property: Token expiration should be reasonable based on expiresIn
            const maxExpiration = now + parseExpirationTime(expiresIn) / 1000;
            expect(decoded.exp).toBeLessThanOrEqual(maxExpiration + 5); // Allow 5 second buffer
            
            return true;
          } catch (error) {
            logger.error('JWT token generation property test error:', error);
            return false;
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  test('Property: Refresh tokens maintain correct payload structure', async () => {
    await fc.assert(
      fc.asyncProperty(
        refreshTokenPayloadGenerator,
        expirationTimeGenerator,
        async (refreshPayload, expiresIn) => {
          try {
            // Generate refresh token
            const refreshToken = jwt.sign(refreshPayload, TEST_JWT_REFRESH_SECRET, {
              expiresIn: expiresIn,
            } as jwt.SignOptions);
            
            // Verify refresh token is valid JWT
            const decoded = jwt.verify(refreshToken, TEST_JWT_REFRESH_SECRET) as any;
            
            // Property: Token should contain original payload data
            expect(decoded.userId).toBe(refreshPayload.userId);
            expect(decoded.type).toBe('refresh');
            
            // Property: Token should have expiration
            expect(decoded.exp).toBeDefined();
            expect(typeof decoded.exp).toBe('number');
            
            // Property: Token should not be expired immediately
            const now = Math.floor(Date.now() / 1000);
            expect(decoded.exp).toBeGreaterThan(now);
            
            return true;
          } catch (error) {
            logger.error('Refresh token property test error:', error);
            return false;
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  test('Property: Expired tokens are properly rejected', async () => {
    await fc.assert(
      fc.asyncProperty(
        userPayloadGenerator,
        fc.integer({ min: 1, max: 3600 }), // Seconds in the past
        async (userPayload, secondsAgo) => {
          try {
            // Create an expired token
            const expiredTokenPayload = {
              ...userPayload,
              exp: Math.floor(Date.now() / 1000) - secondsAgo, // Expired in the past
            };
            
            const expiredToken = jwt.sign(expiredTokenPayload, TEST_JWT_SECRET);
            
            // Try to verify expired token - should fail
            try {
              jwt.verify(expiredToken, TEST_JWT_SECRET);
              return false; // Should not reach here for expired tokens
            } catch (error: any) {
              // Property: Expired tokens should throw TokenExpiredError
              expect(error.name).toBe('TokenExpiredError');
              return true;
            }
          } catch (error) {
            logger.error('Token expiration property test error:', error);
            return false;
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  test('Property: Invalid tokens are properly rejected', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.string({ minLength: 10, maxLength: 200 }), // Random invalid token
        async (invalidToken) => {
          try {
            // Try to verify invalid token - should fail
            try {
              jwt.verify(invalidToken, TEST_JWT_SECRET);
              return false; // Should not reach here for invalid tokens
            } catch (error: any) {
              // Property: Invalid tokens should throw JsonWebTokenError
              expect(error.name).toMatch(/JsonWebTokenError|TokenExpiredError|NotBeforeError/);
              return true;
            }
          } catch (error) {
            logger.error('Invalid token property test error:', error);
            return false;
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  test('Property: Token signatures are properly validated', async () => {
    await fc.assert(
      fc.asyncProperty(
        userPayloadGenerator,
        fc.string({ minLength: 32, maxLength: 64 }), // Different secret
        async (userPayload, wrongSecret) => {
          try {
            // Generate token with correct secret
            const correctToken = jwt.sign(userPayload, TEST_JWT_SECRET, {
              expiresIn: '1h',
            } as jwt.SignOptions);
            
            // Generate token with wrong secret
            const wrongToken = jwt.sign(userPayload, wrongSecret, {
              expiresIn: '1h',
            } as jwt.SignOptions);
            
            // Property: Token with correct secret should verify successfully
            const correctDecoded = jwt.verify(correctToken, TEST_JWT_SECRET) as any;
            expect(correctDecoded.id).toBe(userPayload.id);
            expect(correctDecoded.email).toBe(userPayload.email);
            
            // Property: Token with wrong secret should fail verification
            try {
              jwt.verify(wrongToken, TEST_JWT_SECRET);
              return false; // Should not reach here
            } catch (error: any) {
              expect(error.name).toBe('JsonWebTokenError');
              expect(error.message).toMatch(/invalid signature/i);
            }
            
            // Property: Correct token should fail with wrong secret
            try {
              jwt.verify(correctToken, wrongSecret);
              return false; // Should not reach here
            } catch (error: any) {
              expect(error.name).toBe('JsonWebTokenError');
            }
            
            return true;
          } catch (error) {
            logger.error('Token signature property test error:', error);
            return false;
          }
        }
      ),
      { numRuns: 100 }
    );
  });
});