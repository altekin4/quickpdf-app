import * as fc from 'fast-check';
import { Request, Response } from 'express';

/**
 * Test helpers for property-based testing
 */

// Custom arbitraries for common data types
export const arbitraries = {
  // Valid email addresses
  email: () => fc.string({ minLength: 3, maxLength: 20 })
    .filter(s => /^[a-zA-Z0-9]/.test(s))
    .map(local => `${local}@example.com`),

  // Valid passwords
  password: () => fc.string({ minLength: 6, maxLength: 50 })
    .filter(s => s.length >= 6),

  // Valid user names
  fullName: () => fc.string({ minLength: 2, maxLength: 100 })
    .filter(s => s.trim().length >= 2)
    .map(s => s.trim()),

  // Valid phone numbers (Turkish format)
  phoneNumber: () => fc.integer({ min: 5000000000, max: 5999999999 })
    .map(n => `0${n}`),

  // Valid template titles
  templateTitle: () => fc.string({ minLength: 5, maxLength: 100 })
    .filter(s => s.trim().length >= 5)
    .map(s => s.trim()),

  // Valid template descriptions
  templateDescription: () => fc.string({ minLength: 20, maxLength: 500 })
    .filter(s => s.trim().length >= 20)
    .map(s => s.trim()),

  // Valid prices
  price: () => fc.float({ min: 0, max: 500, noNaN: true })
    .map(p => Math.round(p * 100) / 100), // Round to 2 decimal places

  // Valid UUIDs
  uuid: () => fc.uuid(),

  // HTTP status codes
  httpStatus: () => fc.integer({ min: 200, max: 599 }),

  // Valid JSON objects
  jsonObject: () => fc.oneof(
    fc.record({
      string: fc.string(),
      number: fc.integer(),
      boolean: fc.boolean(),
    }),
    fc.array(fc.string()),
    fc.string(),
    fc.integer(),
    fc.boolean()
  ),

  // Rate limiting scenarios
  rateLimitScenario: () => fc.record({
    requestCount: fc.integer({ min: 1, max: 50 }),
    windowMs: fc.integer({ min: 1000, max: 60000 }),
    maxRequests: fc.integer({ min: 1, max: 20 }),
    clientIp: fc.ipV4(),
  }),
};

// Test utilities
export const testUtils = {
  // Wait for a specified amount of time
  wait: (ms: number): Promise<void> => 
    new Promise(resolve => setTimeout(resolve, ms)),

  // Generate a random delay
  randomDelay: () => fc.integer({ min: 10, max: 100 }),

  // Create mock request object
  mockRequest: (overrides: Partial<Request> = {}): Partial<Request> => ({
    body: {},
    params: {},
    query: {},
    headers: {},
    ip: '127.0.0.1',
    method: 'GET',
    url: '/',
    ...overrides,
  }),

  // Create mock response object
  mockResponse: (): Partial<Response> => {
    const res: any = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    res.setHeader = jest.fn().mockReturnValue(res);
    return res;
  },

  // Validate response structure
  validateApiResponse: (response: any, expectedFields: string[]) => {
    expect(response).toBeDefined();
    expect(typeof response).toBe('object');
    
    expectedFields.forEach(field => {
      expect(response).toHaveProperty(field);
    });
  },

  // Validate error response structure
  validateErrorResponse: (response: any) => {
    expect(response).toHaveProperty('success', false);
    expect(response).toHaveProperty('error');
    expect(response.error).toHaveProperty('message');
    expect(response.error).toHaveProperty('timestamp');
  },

  // Validate success response structure
  validateSuccessResponse: (response: any) => {
    expect(response).toHaveProperty('success', true);
    expect(response).toHaveProperty('data');
  },

  // Check if string is valid ISO date
  isValidISODate: (dateString: string): boolean => {
    const date = new Date(dateString);
    return date instanceof Date && !isNaN(date.getTime()) && 
           dateString === date.toISOString();
  },

  // Check if value is within range
  isInRange: (value: number, min: number, max: number): boolean => {
    return value >= min && value <= max;
  },

  // Validate UUID format
  isValidUUID: (uuid: string): boolean => {
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return uuidRegex.test(uuid);
  },

  // Validate email format
  isValidEmail: (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  },

  // Generate test data for rate limiting
  generateRateLimitTestData: () => ({
    validRequests: fc.integer({ min: 1, max: 5 }),
    excessiveRequests: fc.integer({ min: 6, max: 20 }),
    clientIps: fc.array(fc.ipV4(), { minLength: 1, maxLength: 10 }),
    windowMs: fc.constantFrom(1000, 5000, 10000, 60000),
  }),
};

// Property test configurations
export const propertyTestConfig = {
  // Standard configuration for most tests
  standard: {
    numRuns: 100,
    timeout: 30000,
  },

  // Configuration for performance-sensitive tests
  performance: {
    numRuns: 50,
    timeout: 60000,
  },

  // Configuration for integration tests
  integration: {
    numRuns: 20,
    timeout: 120000,
  },

  // Configuration for rate limiting tests
  rateLimiting: {
    numRuns: 10,
    timeout: 30000,
  },
};

// Common property test patterns
export const propertyPatterns = {
  // Test that a function doesn't throw for valid inputs
  noThrow: <T>(fn: (input: T) => any, arbitrary: fc.Arbitrary<T>) =>
    fc.property(arbitrary, (input) => {
      expect(() => fn(input)).not.toThrow();
    }),

  // Test that a function returns consistent results
  consistent: <T, R>(fn: (input: T) => R, arbitrary: fc.Arbitrary<T>) =>
    fc.property(arbitrary, (input) => {
      const result1 = fn(input);
      const result2 = fn(input);
      expect(result1).toEqual(result2);
    }),

  // Test that a function preserves certain properties
  preserves: <T>(
    fn: (input: T) => T,
    arbitrary: fc.Arbitrary<T>,
    property: (input: T) => boolean
  ) =>
    fc.property(arbitrary, (input) => {
      fc.pre(property(input)); // Precondition
      const result = fn(input);
      expect(property(result)).toBe(true);
    }),
};

// Database helpers for marketplace tests
export const marketplaceHelpers = {
  // Update template properties directly in database
  updateTemplateDirectly: async (templateId: string, updates: any): Promise<void> => {
    const pool = require('../../config/database').default;
    
    const updateFields = [];
    const values = [];
    let paramCount = 1;

    if (updates.status !== undefined) {
      updateFields.push(`status = $${paramCount++}`);
      values.push(updates.status);
    }
    if (updates.rating !== undefined) {
      updateFields.push(`rating = $${paramCount++}`);
      values.push(updates.rating);
    }
    if (updates.isVerified !== undefined) {
      updateFields.push(`is_verified = $${paramCount++}`);
      values.push(updates.isVerified);
    }
    if (updates.isFeatured !== undefined) {
      updateFields.push(`is_featured = $${paramCount++}`);
      values.push(updates.isFeatured);
    }
    if (updates.downloadCount !== undefined) {
      updateFields.push(`download_count = $${paramCount++}`);
      values.push(updates.downloadCount);
    }

    if (updateFields.length > 0) {
      values.push(templateId);
      const query = `
        UPDATE templates 
        SET ${updateFields.join(', ')}, updated_at = NOW()
        WHERE id = $${paramCount}
      `;
      await pool.query(query, values);
    }
  },

  // Add tags to template
  addTagsToTemplate: async (templateId: string, tags: string[]): Promise<void> => {
    const pool = require('../../config/database').default;
    
    for (const tagName of tags) {
      // Create tag if it doesn't exist
      const tagQuery = `
        INSERT INTO tags (name, slug) 
        VALUES ($1, $2) 
        ON CONFLICT (slug) DO NOTHING
        RETURNING id
      `;
      let tagResult = await pool.query(tagQuery, [tagName, tagName.toLowerCase()]);
      
      if (tagResult.rows.length === 0) {
        // Tag already exists, get its ID
        const existingTagQuery = 'SELECT id FROM tags WHERE slug = $1';
        tagResult = await pool.query(existingTagQuery, [tagName.toLowerCase()]);
      }

      const tagId = tagResult.rows[0].id;

      // Link template to tag
      const linkQuery = `
        INSERT INTO template_tags (template_id, tag_id)
        VALUES ($1, $2)
        ON CONFLICT (template_id, tag_id) DO NOTHING
      `;
      await pool.query(linkQuery, [templateId, tagId]);
    }
  },

  // Get template tags
  getTemplateTags: async (templateId: string): Promise<string[]> => {
    const pool = require('../../config/database').default;
    
    const query = `
      SELECT t.name
      FROM tags t
      JOIN template_tags tt ON t.id = tt.tag_id
      WHERE tt.template_id = $1
    `;
    const result = await pool.query(query, [templateId]);
    return result.rows.map((row: any) => row.name);
  },

  // Setup test database
  setupTestDatabase: async (): Promise<void> => {
    // Database setup is handled by the test environment
    // This is a placeholder for any additional setup needed
  },

  // Cleanup test database
  cleanupTestDatabase: async (): Promise<void> => {
    // Database cleanup is handled by the test environment
    // This is a placeholder for any additional cleanup needed
  },

  // Clear test data
  clearTestData: async (): Promise<void> => {
    const pool = require('../../config/database').default;
    
    // Clear in order to respect foreign key constraints
    await pool.query('DELETE FROM template_tags');
    await pool.query('DELETE FROM ratings');
    await pool.query('DELETE FROM purchases');
    await pool.query('DELETE FROM templates');
    await pool.query('DELETE FROM tags');
    await pool.query('DELETE FROM categories');
    await pool.query('DELETE FROM users WHERE email LIKE \'%test%\'');
  },

  // Create mock purchase for testing
  createMockPurchase: async (userId: string, templateId: string): Promise<void> => {
    const pool = require('../../config/database').default;
    
    const query = `
      INSERT INTO purchases (user_id, template_id, amount, currency, payment_method, payment_gateway, transaction_id, status, purchased_at, completed_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
    `;
    
    await pool.query(query, [
      userId,
      templateId,
      0.00, // Free for testing
      'TRY',
      'test',
      'test',
      `test_transaction_${Date.now()}`,
      'completed'
    ]);
  },

  // Create test category
  createTestCategory: async (): Promise<any> => {
    const MarketplaceService = require('../../services/marketplaceService').MarketplaceService;
    
    return await MarketplaceService.createCategory({
      name: `Test Category ${Date.now()}`,
      slug: `test-category-${Date.now()}`,
      description: 'Test category for property testing',
    });
  },
};