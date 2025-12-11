/**
 * **Feature: quickpdf-template-marketplace, Property 18: Rate Limiting Enforcement**
 * **Validates: Requirements 10.5**
 * 
 * Property-based test for rate limiting enforcement.
 * Tests that the system enforces rate limits to prevent abuse while allowing normal usage.
 */

import * as fc from 'fast-check';
import request from 'supertest';
import express from 'express';
import rateLimit from 'express-rate-limit';

describe('Property 18: Rate Limiting Enforcement', () => {
  let app: express.Application;
  
  beforeEach(() => {
    // Create a test app with rate limiting
    app = express();
    
    // Configure rate limiter for testing (more restrictive)
    const limiter = rateLimit({
      windowMs: 60000, // 1 minute
      max: 5, // limit each IP to 5 requests per windowMs
      message: {
        error: 'Too many requests from this IP, please try again later.',
      },
      standardHeaders: true,
      legacyHeaders: false,
    });
    
    app.use(limiter);
    
    // Test endpoint
    app.get('/test', (req, res) => {
      res.status(200).json({ success: true, message: 'Request successful' });
    });
    
    // Health endpoint (should not be rate limited)
    app.get('/health', (req, res) => {
      res.status(200).json({ status: 'OK' });
    });
  });

  /**
   * Property: For any sequence of API requests from a single source,
   * the system should enforce rate limits to prevent abuse while allowing normal usage.
   */
  test('should enforce rate limits for excessive requests', async () => {
    await fc.assert(
      fc.asyncProperty(
        // Generate a sequence of request counts that exceed the limit
        fc.integer({ min: 6, max: 20 }), // More than the 5 request limit
        async (requestCount) => {
          const responses: request.Response[] = [];
          
          // Make multiple requests rapidly
          for (let i = 0; i < requestCount; i++) {
            const response = await request(app)
              .get('/test')
              .set('X-Forwarded-For', '192.168.1.100'); // Simulate same IP
            
            responses.push(response);
          }
          
          // Check that initial requests succeed
          const successfulRequests = responses.filter(r => r.status === 200);
          const rateLimitedRequests = responses.filter(r => r.status === 429);
          
          // Property: Should allow some requests but block excessive ones
          expect(successfulRequests.length).toBeGreaterThan(0);
          expect(successfulRequests.length).toBeLessThanOrEqual(5);
          expect(rateLimitedRequests.length).toBeGreaterThan(0);
          
          // Property: Rate limited responses should have appropriate message
          rateLimitedRequests.forEach(response => {
            expect(response.body).toHaveProperty('error');
            expect(response.body.error).toContain('Too many requests');
          });
          
          // Property: Total requests should equal successful + rate limited
          expect(successfulRequests.length + rateLimitedRequests.length).toBe(requestCount);
        }
      ),
      { numRuns: 10 } // Run 10 iterations
    );
  });

  test('should allow normal usage within rate limits', async () => {
    await fc.assert(
      fc.asyncProperty(
        // Generate request counts within the limit
        fc.integer({ min: 1, max: 5 }),
        fc.array(fc.ipV4(), { minLength: 1, maxLength: 10 }), // Different IPs
        async (requestCount, ips) => {
          // Test that different IPs can make requests within limits
          for (const ip of ips) {
            const responses: request.Response[] = [];
            
            // Make requests within the limit
            for (let i = 0; i < requestCount; i++) {
              const response = await request(app)
                .get('/test')
                .set('X-Forwarded-For', ip);
              
              responses.push(response);
            }
            
            // Property: All requests within limit should succeed
            responses.forEach(response => {
              expect(response.status).toBe(200);
              expect(response.body).toHaveProperty('success', true);
            });
          }
        }
      ),
      { numRuns: 10 }
    );
  });

  test('should reset rate limit after window expires', async () => {
    // This test uses a shorter window for faster testing
    const shortLimitApp = express();
    const shortLimiter = rateLimit({
      windowMs: 1000, // 1 second window
      max: 2, // 2 requests per second
      message: { error: 'Rate limited' },
    });
    
    shortLimitApp.use(shortLimiter);
    shortLimitApp.get('/test', (req, res) => {
      res.status(200).json({ success: true });
    });

    await fc.assert(
      fc.asyncProperty(
        fc.constant('192.168.1.200'), // Fixed IP for this test
        async (ip) => {
          // Make requests to exceed limit
          const firstBatch = await Promise.all([
            request(shortLimitApp).get('/test').set('X-Forwarded-For', ip),
            request(shortLimitApp).get('/test').set('X-Forwarded-For', ip),
            request(shortLimitApp).get('/test').set('X-Forwarded-For', ip), // This should be rate limited
          ]);
          
          // Property: First 2 should succeed, 3rd should be rate limited
          expect(firstBatch[0].status).toBe(200);
          expect(firstBatch[1].status).toBe(200);
          expect(firstBatch[2].status).toBe(429);
          
          // Wait for window to reset
          await new Promise(resolve => setTimeout(resolve, 1100));
          
          // Make requests after window reset
          const secondBatch = await Promise.all([
            request(shortLimitApp).get('/test').set('X-Forwarded-For', ip),
            request(shortLimitApp).get('/test').set('X-Forwarded-For', ip),
          ]);
          
          // Property: After window reset, requests should succeed again
          expect(secondBatch[0].status).toBe(200);
          expect(secondBatch[1].status).toBe(200);
        }
      ),
      { numRuns: 5 } // Fewer runs due to timing requirements
    );
  });

  test('should handle concurrent requests from different IPs correctly', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(fc.ipV4(), { minLength: 2, maxLength: 5 }), // Multiple different IPs
        fc.integer({ min: 1, max: 5 }), // Requests per IP
        async (ips, requestsPerIp) => {
          // Make concurrent requests from different IPs
          const allRequests = ips.flatMap(ip => 
            Array(requestsPerIp).fill(null).map(() =>
              request(app)
                .get('/test')
                .set('X-Forwarded-For', ip)
            )
          );
          
          const responses = await Promise.all(allRequests);
          
          // Property: Each IP should be rate limited independently
          const responsesByIp = new Map<string, request.Response[]>();
          
          ips.forEach((ip, ipIndex) => {
            const ipResponses = responses.slice(
              ipIndex * requestsPerIp,
              (ipIndex + 1) * requestsPerIp
            );
            responsesByIp.set(ip, ipResponses);
          });
          
          // Property: Each IP should have all requests succeed (within limit)
          responsesByIp.forEach((ipResponses, ip) => {
            ipResponses.forEach(response => {
              expect(response.status).toBe(200);
            });
          });
        }
      ),
      { numRuns: 10 }
    );
  });

  test('should preserve rate limit headers in responses', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 3 }), // Within limit
        async (requestCount) => {
          const responses: request.Response[] = [];
          
          for (let i = 0; i < requestCount; i++) {
            const response = await request(app)
              .get('/test')
              .set('X-Forwarded-For', '192.168.1.300');
            
            responses.push(response);
          }
          
          // Property: Responses should include rate limit headers
          responses.forEach((response, index) => {
            expect(response.headers).toHaveProperty('x-ratelimit-limit');
            expect(response.headers).toHaveProperty('x-ratelimit-remaining');
            expect(response.headers).toHaveProperty('x-ratelimit-reset');
            
            // Property: Remaining count should decrease with each request
            const remaining = parseInt(response.headers['x-ratelimit-remaining']);
            expect(remaining).toBe(5 - (index + 1));
          });
        }
      ),
      { numRuns: 10 }
    );
  });
});