/**
 * **Feature: quickpdf-template-marketplace, Property 15: Input Sanitization Security**
 * **Validates: Requirements 10.4**
 * 
 * Property-based tests for input sanitization security
 * Tests that all user inputs are properly sanitized to prevent XSS and injection attacks
 */

import * as fc from 'fast-check';
import { 
  sanitizeString, 
  sanitizeTemplateContent, 
  sanitizeObject,
  validateFileUpload 
} from '@/middleware/sanitizationMiddleware';

describe('Property 15: Input Sanitization Security', () => {
  
  describe('String Sanitization', () => {
    it('should remove all script tags from any input string', () => {
      fc.assert(fc.property(
        fc.string().map(str => str + '<script>alert("xss")</script>' + fc.sample(fc.string(), 1)[0]),
        (maliciousInput) => {
          const sanitized = sanitizeString(maliciousInput);
          expect(sanitized).not.toContain('<script>');
          expect(sanitized).not.toContain('</script>');
          // alert( should be removed by dangerous pattern removal
          expect(sanitized).not.toMatch(/alert\s*\(/);
        }
      ), { numRuns: 100 });
    });

    it('should escape HTML entities in any input string', () => {
      fc.assert(fc.property(
        fc.string().map(str => str + '<>&"\''),
        (inputWithHtml) => {
          const sanitized = sanitizeString(inputWithHtml);
          // After escaping, these characters should be converted to HTML entities
          expect(sanitized).not.toContain('<');
          expect(sanitized).not.toContain('>');
          // & might still exist as part of HTML entities like &amp;
          expect(sanitized).not.toContain('"');
          expect(sanitized).not.toContain("'");
        }
      ), { numRuns: 100 });
    });

    it('should limit string length to maximum specified', () => {
      fc.assert(fc.property(
        fc.string({ minLength: 1000 }),
        fc.integer({ min: 10, max: 500 }),
        (longString, maxLength) => {
          const sanitized = sanitizeString(longString, { maxLength });
          expect(sanitized.length).toBeLessThanOrEqual(maxLength);
        }
      ), { numRuns: 100 });
    });

    it('should remove dangerous JavaScript patterns', () => {
      const dangerousPatterns = [
        'javascript:',
        'onload=',
        'onerror=',
        'onclick=',
        'onmouseover=',
        'eval(',
        'setTimeout(',
        'setInterval(',
        'Function(',
        'document.cookie',
        'window.location'
      ];

      fc.assert(fc.property(
        fc.constantFrom(...dangerousPatterns),
        fc.string(),
        (pattern, randomString) => {
          const maliciousInput = randomString + pattern + 'malicious_code()';
          const sanitized = sanitizeString(maliciousInput);
          expect(sanitized.toLowerCase()).not.toContain(pattern.toLowerCase());
        }
      ), { numRuns: 100 });
    });
  });

  describe('Template Content Sanitization', () => {
    it('should preserve valid template placeholders while sanitizing content', () => {
      fc.assert(fc.property(
        fc.array(fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s))),
        fc.string(),
        (placeholderNames, content) => {
          const placeholders = placeholderNames.map(name => `{${name}}`);
          const templateContent = content + placeholders.join(' ') + '<script>alert("xss")</script>';
          
          const sanitized = sanitizeTemplateContent(templateContent);
          
          // Should preserve valid placeholders
          placeholders.forEach(placeholder => {
            expect(sanitized).toContain(placeholder);
          });
          
          // Should remove script tags
          expect(sanitized).not.toContain('<script>');
          expect(sanitized).not.toContain('</script>');
        }
      ), { numRuns: 100 });
    });

    it('should allow safe formatting tags while removing dangerous ones', () => {
      const safeTags = ['<b>', '<i>', '<u>', '<strong>', '<em>', '<p>', '<br>', '<h1>', '<h2>', '<h3>'];
      const dangerousTags = ['<script>', '<iframe>', '<object>', '<embed>', '<link>', '<meta>'];

      fc.assert(fc.property(
        fc.constantFrom(...safeTags),
        fc.constantFrom(...dangerousTags),
        fc.string(),
        (safeTag, dangerousTag, content) => {
          const templateContent = content + safeTag + 'content' + dangerousTag + 'malicious';
          const sanitized = sanitizeTemplateContent(templateContent);
          
          // Should preserve safe tags (or their content)
          expect(sanitized).toContain('content');
          
          // Should remove dangerous tags
          expect(sanitized).not.toContain(dangerousTag);
        }
      ), { numRuns: 100 });
    });
  });

  describe('Object Sanitization', () => {
    it('should recursively sanitize all string properties in nested objects', () => {
      fc.assert(fc.property(
        fc.record({
          name: fc.string(),
          description: fc.string(),
          nested: fc.record({
            content: fc.string(),
            tags: fc.array(fc.string())
          })
        }),
        (inputObject) => {
          // Add malicious content to all strings
          const maliciousObject = JSON.parse(JSON.stringify(inputObject));
          const addMalicious = (obj: any): any => {
            if (typeof obj === 'string') {
              return obj + '<script>alert("xss")</script>';
            }
            if (Array.isArray(obj)) {
              return obj.map(addMalicious);
            }
            if (typeof obj === 'object' && obj !== null) {
              const result: any = {};
              for (const [key, value] of Object.entries(obj)) {
                result[key] = addMalicious(value);
              }
              return result;
            }
            return obj;
          };
          
          const maliciousInput = addMalicious(maliciousObject);
          const sanitized = sanitizeObject(maliciousInput);
          
          // Check that no script tags remain anywhere in the object
          const checkNoScripts = (obj: any): void => {
            if (typeof obj === 'string') {
              expect(obj).not.toContain('<script>');
              expect(obj).not.toContain('</script>');
            } else if (Array.isArray(obj)) {
              obj.forEach(checkNoScripts);
            } else if (typeof obj === 'object' && obj !== null) {
              Object.values(obj).forEach(checkNoScripts);
            }
          };
          
          checkNoScripts(sanitized);
        }
      ), { numRuns: 100 });
    });

    it('should sanitize object keys as well as values', () => {
      fc.assert(fc.property(
        fc.string(),
        fc.string(),
        (key, value) => {
          const maliciousKey = key + '<script>alert("xss")</script>';
          const maliciousValue = value + '<img src=x onerror=alert("xss")>';
          const inputObject = { [maliciousKey]: maliciousValue };
          
          const sanitized = sanitizeObject(inputObject);
          const sanitizedKeys = Object.keys(sanitized);
          const sanitizedValues = Object.values(sanitized);
          
          // Check keys are sanitized
          sanitizedKeys.forEach(k => {
            expect(k).not.toContain('<script>');
            expect(k).not.toContain('</script>');
          });
          
          // Check values are sanitized
          sanitizedValues.forEach(v => {
            if (typeof v === 'string') {
              expect(v).not.toContain('<img');
              expect(v).not.toContain('onerror=');
            }
          });
        }
      ), { numRuns: 100 });
    });
  });

  describe('File Upload Validation', () => {
    it('should reject files with dangerous extensions', () => {
      const dangerousExtensions = ['.exe', '.bat', '.cmd', '.scr', '.pif', '.com', '.js', '.vbs', '.jar'];
      
      fc.assert(fc.property(
        fc.constantFrom(...dangerousExtensions),
        fc.string({ minLength: 1, maxLength: 50 }),
        (extension, filename) => {
          const mockFile = {
            originalname: filename + extension,
            mimetype: 'application/octet-stream',
            size: 1024,
          } as Express.Multer.File;
          
          expect(() => validateFileUpload(mockFile)).toThrow();
        }
      ), { numRuns: 100 });
    });

    it('should reject files exceeding size limit', () => {
      fc.assert(fc.property(
        fc.integer({ min: 10 * 1024 * 1024 + 1, max: 100 * 1024 * 1024 }), // Files larger than 10MB
        (fileSize) => {
          const mockFile = {
            originalname: 'test.pdf',
            mimetype: 'application/pdf',
            size: fileSize,
          } as Express.Multer.File;
          
          expect(() => validateFileUpload(mockFile)).toThrow('File size exceeds maximum limit');
        }
      ), { numRuns: 100 });
    });

    it('should reject files with null bytes in filename', () => {
      fc.assert(fc.property(
        fc.string(),
        fc.string(),
        (prefix, suffix) => {
          const maliciousFilename = prefix + '\0' + suffix + '.pdf';
          const mockFile = {
            originalname: maliciousFilename,
            mimetype: 'application/pdf',
            size: 1024,
          } as Express.Multer.File;
          
          expect(() => validateFileUpload(mockFile)).toThrow('Invalid filename');
        }
      ), { numRuns: 100 });
    });

    it('should accept valid files with safe extensions and sizes', () => {
      const safeFiles = [
        { name: 'document.pdf', mime: 'application/pdf' },
        { name: 'image.jpg', mime: 'image/jpeg' },
        { name: 'image.png', mime: 'image/png' },
        { name: 'text.txt', mime: 'text/plain' },
        { name: 'data.json', mime: 'application/json' }
      ];

      fc.assert(fc.property(
        fc.constantFrom(...safeFiles),
        fc.integer({ min: 1, max: 10 * 1024 * 1024 }), // Valid file sizes
        (fileInfo, size) => {
          const mockFile = {
            originalname: fileInfo.name,
            mimetype: fileInfo.mime,
            size: size,
          } as Express.Multer.File;
          
          expect(() => validateFileUpload(mockFile)).not.toThrow();
          expect(validateFileUpload(mockFile)).toBe(true);
        }
      ), { numRuns: 100 });
    });
  });

  describe('SQL Injection Prevention', () => {
    it('should detect common SQL injection patterns', () => {
      const sqlInjectionPatterns = [
        "'; DROP TABLE users; --",
        "' OR '1'='1",
        "' UNION SELECT * FROM users --",
        "'; INSERT INTO users VALUES ('hacker', 'password'); --",
        "' OR 1=1 --",
        "admin'--",
        "' OR 'x'='x",
        "'; EXEC xp_cmdshell('dir'); --"
      ];

      fc.assert(fc.property(
        fc.constantFrom(...sqlInjectionPatterns),
        fc.string(),
        (sqlPattern, normalString) => {
          const maliciousInput = normalString + sqlPattern;
          
          // Test that our sanitization removes or escapes dangerous SQL patterns
          const sanitized = sanitizeString(maliciousInput);
          
          // Should not contain raw SQL keywords in dangerous contexts
          expect(sanitized).not.toMatch(/DROP\s+TABLE/i);
          expect(sanitized).not.toMatch(/UNION\s+SELECT/i);
          expect(sanitized).not.toMatch(/INSERT\s+INTO/i);
          expect(sanitized).not.toMatch(/EXEC\s+xp_/i);
          expect(sanitized).not.toMatch(/'--/);
          expect(sanitized).not.toMatch(/'\s+OR\s+'/i);
        }
      ), { numRuns: 100 });
    });
  });
});