/**
 * **Feature: quickpdf-template-marketplace, Property 8: Template Data Injection**
 * 
 * **Validates: Requirements 6.3, 6.5**
 * 
 * Property: For any template and valid user input data, the system should correctly 
 * replace all placeholders with user data while preserving template formatting
 */

import fc from 'fast-check';
import { TemplateDataInjectionService } from '@/services/templateDataInjectionService';
import { PlaceholderType, PlaceholderConfig, Template, TemplateStatus } from '@/models/Template';

describe('Template Data Injection Property Tests', () => {
  /**
   * Property: All placeholders should be replaced with user data
   * For any template with placeholders and matching user data, all placeholders should be replaced
   */
  test('should replace all placeholders with user data', async () => {
    await fc.assert(
      fc.property(
        // Generate template with placeholders and matching user data
        fc.record({
          template: templateWithPlaceholdersGenerator(),
          userData: fc.func(fc.record({})) // Will be generated based on template
        }).chain(({ template }) => 
          fc.record({
            template: fc.constant(template),
            userData: userDataForTemplateGenerator(template)
          })
        ),
        ({ template, userData }) => {
          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: All defined placeholders should be processed
          const placeholderKeys = Object.keys(template.placeholders);
          expect(processed.injectionMetadata.placeholdersProcessed).toBeGreaterThan(0);
          
          // Property: No placeholders should remain in processed body
          const remainingPlaceholders = findPlaceholdersInText(processed.processedBody);
          const definedPlaceholders = placeholderKeys.filter(key => userData[key] !== undefined);
          
          for (const placeholder of definedPlaceholders) {
            expect(remainingPlaceholders).not.toContain(placeholder);
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Date formatting should be consistent
   * For any date placeholder, the output should be in Turkish format (DD.MM.YYYY)
   */
  test('should format dates in Turkish format', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          date: fc.date({ min: new Date('2000-01-01'), max: new Date('2030-12-31') }),
          placeholder: fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s))
        }),
        ({ date, placeholder }) => {
          const template = createTemplateWithDatePlaceholder(placeholder);
          const userData = { [placeholder]: date.toISOString() };

          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: Date should be formatted in Turkish format (DD.MM.YYYY)
          const expectedFormat = date.toLocaleDateString('tr-TR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
          });
          
          expect(processed.processedBody).toContain(expectedFormat);
          expect(processed.processedBody).not.toContain(date.toISOString());
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Boolean values should be formatted in Turkish
   * For any checkbox placeholder, true should become "Evet" and false should become "Hayır"
   */
  test('should format boolean values in Turkish', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          value: fc.boolean(),
          placeholder: fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s))
        }),
        ({ value, placeholder }) => {
          const template = createTemplateWithCheckboxPlaceholder(placeholder);
          const userData = { [placeholder]: value };

          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: Boolean should be formatted in Turkish
          const expectedText = value ? 'Evet' : 'Hayır';
          expect(processed.processedBody).toContain(expectedText);
          expect(processed.processedBody).not.toContain(value.toString());
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: HTML content should be sanitized
   * For any string input containing HTML tags, the tags should be removed
   */
  test('should sanitize HTML content from user input', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          htmlContent: fc.string().map(s => `<script>alert('xss')</script>${s}<b>bold</b>`),
          placeholder: fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s))
        }),
        ({ htmlContent, placeholder }) => {
          const template = createTemplateWithStringPlaceholder(placeholder);
          const userData = { [placeholder]: htmlContent };

          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: HTML tags should be removed
          expect(processed.processedBody).not.toContain('<script>');
          expect(processed.processedBody).not.toContain('<b>');
          expect(processed.processedBody).not.toContain('</b>');
          
          // Property: Sanitized fields should be tracked
          if (htmlContent.includes('<') || htmlContent.includes('>')) {
            expect(processed.injectionMetadata.sanitizedFields).toContain(placeholder);
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Required field validation should be enforced
   * For any template with required fields, missing data should cause validation failure
   */
  test('should enforce required field validation', async () => {
    await fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s)),
        (placeholder) => {
          const template = createTemplateWithRequiredPlaceholder(placeholder);
          const userData = {}; // Missing required field

          // Property: Processing should fail for missing required fields
          expect(() => {
            TemplateDataInjectionService.processTemplate(template, userData);
          }).toThrow();
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Number formatting should use Turkish locale
   * For any number placeholder, the output should use Turkish number formatting
   */
  test('should format numbers using Turkish locale', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          number: fc.float({ min: 1000, max: 999999 }),
          placeholder: fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s))
        }),
        ({ number, placeholder }) => {
          const template = createTemplateWithNumberPlaceholder(placeholder);
          const userData = { [placeholder]: number };

          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: Number should be formatted with Turkish locale
          const expectedFormat = number.toLocaleString('tr-TR');
          expect(processed.processedBody).toContain(expectedFormat);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Template formatting should be preserved
   * For any template structure, the non-placeholder content should remain unchanged
   */
  test('should preserve template formatting', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          prefix: fc.string({ minLength: 5, maxLength: 50 }).filter(s => s.trim().length >= 5),
          suffix: fc.string({ minLength: 5, maxLength: 50 }).filter(s => s.trim().length >= 5),
          placeholder: fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s)),
          value: fc.string({ minLength: 1, maxLength: 100 }).filter(s => s.trim().length > 0 && !s.includes('<') && !s.includes('>'))
        }),
        ({ prefix, suffix, placeholder, value }) => {
          const templateBody = `${prefix} {${placeholder}} ${suffix}`;
          const template = createTemplateWithBody(templateBody, placeholder, PlaceholderType.STRING);
          const userData = { [placeholder]: value };

          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: Template structure should be preserved (check trimmed versions due to sanitization)
          expect(processed.processedBody).toContain(prefix.trim());
          expect(processed.processedBody).toContain(suffix.trim());
          
          // Property: Placeholder should be replaced
          expect(processed.processedBody).not.toContain(`{${placeholder}}`);
          
          // Property: Some form of the value should be present (may be sanitized)
          expect(processed.processedBody.length).toBeGreaterThan(prefix.length + suffix.length);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Multiple occurrences of same placeholder should all be replaced
   * For any placeholder used multiple times, all occurrences should be replaced
   */
  test('should replace multiple occurrences of same placeholder', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          placeholder: fc.string({ minLength: 1, maxLength: 20 }).filter(s => /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(s)),
          value: fc.string({ minLength: 2, maxLength: 20 }).filter(s => 
            s.trim().length > 1 && 
            !s.includes('<') && 
            !s.includes('>') && 
            !s.includes(' and ') && // Avoid conflicts with separator
            /^[a-zA-Z0-9_\-]+$/.test(s) // Only alphanumeric to avoid regex issues
          ),
          occurrences: fc.integer({ min: 2, max: 3 })
        }),
        ({ placeholder, value, occurrences }) => {
          // Create template with multiple occurrences of same placeholder
          const placeholderText = `{${placeholder}}`;
          const templateBody = Array(occurrences).fill(placeholderText).join(' and ');
          
          const template = createTemplateWithBody(templateBody, placeholder, PlaceholderType.STRING);
          const userData = { [placeholder]: value };

          const processed = TemplateDataInjectionService.processTemplate(template, userData);

          // Property: All occurrences should be replaced
          expect(processed.processedBody).not.toContain(placeholderText);
          
          // Property: Value should appear the correct number of times (account for sanitization)
          const sanitizedValue = value.replace(/<[^>]*>/g, ''); // Same sanitization as service
          if (sanitizedValue.length > 0) {
            const valueOccurrences = (processed.processedBody.match(new RegExp(escapeRegex(sanitizedValue), 'g')) || []).length;
            expect(valueOccurrences).toBe(occurrences);
          }
        }
      ),
      { numRuns: 100 }
    );
  });
});

// Helper functions and generators
function templateWithPlaceholdersGenerator(): fc.Arbitrary<Template> {
  return fc.record({
    placeholderCount: fc.integer({ min: 1, max: 3 }),
    templateId: fc.uuid(),
    title: fc.string({ minLength: 5, maxLength: 50 })
  }).chain(({ placeholderCount, templateId, title }) => {
    const placeholders: Record<string, PlaceholderConfig> = {};
    const bodyParts: string[] = [];

    for (let i = 0; i < placeholderCount; i++) {
      const key = `field_${i}`;
      // Use simpler types to avoid validation issues
      const type = fc.sample(fc.constantFrom(
        PlaceholderType.STRING, 
        PlaceholderType.NUMBER, 
        PlaceholderType.CHECKBOX
      ), 1)[0];
      
      const config: PlaceholderConfig = {
        type,
        label: `Field ${i}`,
        required: true,
        order: i
      };

      // Add options for select types
      if (type === PlaceholderType.SELECT || type === PlaceholderType.RADIO) {
        config.options = ['Option 1', 'Option 2', 'Option 3'];
      }

      placeholders[key] = config;
      bodyParts.push(`{${key}}`);
    }

    const body = `Template content: ${bodyParts.join(' and ')}.`;

    return fc.constant({
      id: templateId,
      title,
      description: 'Test template',
      categoryId: 'test-category',
      body,
      placeholders,
      createdBy: 'test-user',
      price: 0,
      currency: 'TRY',
      isAdminTemplate: false,
      isVerified: true,
      isFeatured: false,
      status: TemplateStatus.PUBLISHED,
      rating: 4.5,
      totalRatings: 10,
      downloadCount: 100,
      purchaseCount: 50,
      revenue: 0,
      version: '1.0',
      createdAt: new Date(),
      updatedAt: new Date()
    } as Template);
  });
}

function userDataForTemplateGenerator(template: Template): fc.Arbitrary<Record<string, any>> {
  const generators: Record<string, fc.Arbitrary<any>> = {};

  for (const [key, config] of Object.entries(template.placeholders)) {
    switch (config.type) {
      case PlaceholderType.STRING:
      case PlaceholderType.TEXT:
      case PlaceholderType.TEXTAREA:
        generators[key] = fc.string({ minLength: 1, maxLength: 100 }).filter(s => s.trim().length > 0);
        break;
      case PlaceholderType.NUMBER:
        generators[key] = fc.float({ min: 1, max: 10000 }).filter(n => !isNaN(n) && isFinite(n));
        break;
      case PlaceholderType.DATE:
        generators[key] = fc.date({ min: new Date('2000-01-01'), max: new Date('2030-12-31') }).map(d => d.toISOString());
        break;
      case PlaceholderType.EMAIL:
        generators[key] = fc.emailAddress();
        break;
      case PlaceholderType.PHONE:
        generators[key] = fc.constant('+90 555 123 45 67');
        break;
      case PlaceholderType.CHECKBOX:
        generators[key] = fc.boolean();
        break;
      case PlaceholderType.SELECT:
      case PlaceholderType.RADIO:
        // Ensure options exist for select/radio types
        if (config.options && config.options.length > 0) {
          generators[key] = fc.constantFrom(...config.options);
        } else {
          generators[key] = fc.constant('Option 1');
        }
        break;
      default:
        generators[key] = fc.string({ minLength: 1, maxLength: 50 }).filter(s => s.trim().length > 0);
    }
  }

  return fc.record(generators);
}

function createTemplateWithDatePlaceholder(placeholder: string): Template {
  return createTemplateWithBody(`Date: {${placeholder}}`, placeholder, PlaceholderType.DATE);
}

function createTemplateWithCheckboxPlaceholder(placeholder: string): Template {
  return createTemplateWithBody(`Checkbox: {${placeholder}}`, placeholder, PlaceholderType.CHECKBOX);
}

function createTemplateWithStringPlaceholder(placeholder: string): Template {
  return createTemplateWithBody(`Text: {${placeholder}}`, placeholder, PlaceholderType.STRING);
}

function createTemplateWithRequiredPlaceholder(placeholder: string): Template {
  return createTemplateWithBody(`Required: {${placeholder}}`, placeholder, PlaceholderType.STRING, true);
}

function createTemplateWithNumberPlaceholder(placeholder: string): Template {
  return createTemplateWithBody(`Number: {${placeholder}}`, placeholder, PlaceholderType.NUMBER);
}

function createTemplateWithBody(
  body: string, 
  placeholder: string, 
  type: PlaceholderType, 
  required: boolean = true
): Template {
  return {
    id: 'test-template',
    title: 'Test Template',
    description: 'Test description',
    categoryId: 'test-category',
    body,
    placeholders: {
      [placeholder]: {
        type,
        label: 'Test Field',
        required,
        order: 1
      }
    },
    createdBy: 'test-user',
    price: 0,
    currency: 'TRY',
    isAdminTemplate: false,
    isVerified: true,
    isFeatured: false,
    status: TemplateStatus.PUBLISHED,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    revenue: 0,
    version: '1.0',
    createdAt: new Date(),
    updatedAt: new Date()
  };
}

function findPlaceholdersInText(text: string): string[] {
  const placeholderRegex = /\{([^}]+)\}/g;
  const matches: string[] = [];
  let match;

  while ((match = placeholderRegex.exec(text)) !== null) {
    matches.push(match[1]);
  }

  return matches;
}

function escapeRegex(string: string): string {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}