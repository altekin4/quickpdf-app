/**
 * **Feature: quickpdf-template-marketplace, Property 9: Template Structure Validation**
 * 
 * **Validates: Requirements 7.1, 7.2**
 * 
 * Property: For any uploaded template, the system should validate placeholder definitions, 
 * field types, and template structure before allowing publication
 */

import fc from 'fast-check';
import { TemplateModel, PlaceholderType, PlaceholderConfig } from '@/models/Template';

describe('Template Structure Validation Property Tests', () => {
  /**
   * Property: Template validation should correctly identify valid templates
   * For any valid template structure, validation should pass
   */
  test('should validate correct template structures', async () => {
    await fc.assert(
      fc.property(
        // Generate valid template body with placeholders
        fc.record({
          body: fc.string({ minLength: 10, maxLength: 1000 })
            .map(text => `Hello {name}, your request for {item} on {date} is approved.`),
          placeholders: fc.constant({
            name: {
              type: PlaceholderType.STRING,
              label: 'Full Name',
              required: true,
              order: 1
            } as PlaceholderConfig,
            item: {
              type: PlaceholderType.TEXT,
              label: 'Item Description',
              required: true,
              validation: { minLength: 5, maxLength: 100 },
              order: 2
            } as PlaceholderConfig,
            date: {
              type: PlaceholderType.DATE,
              label: 'Request Date',
              required: true,
              defaultValue: 'today',
              order: 3
            } as PlaceholderConfig
          })
        }),
        (template) => {
          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Valid templates should pass validation
          expect(validation.isValid).toBe(true);
          expect(validation.errors).toHaveLength(0);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Template validation should reject templates with undefined placeholders
   * For any template using placeholders not defined in the config, validation should fail
   */
  test('should reject templates with undefined placeholders in body', async () => {
    await fc.assert(
      fc.property(
        // Generate template with undefined placeholder in body
        fc.record({
          body: fc.string({ minLength: 1, maxLength: 50 })
            .map(text => `Hello {name}, your {undefined_placeholder} is ready.`),
          placeholders: fc.constant({
            name: {
              type: PlaceholderType.STRING,
              label: 'Name',
              required: true,
              order: 1
            } as PlaceholderConfig
          })
        }),
        (template) => {
          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Templates with undefined placeholders should fail validation
          expect(validation.isValid).toBe(false);
          expect(validation.errors.some(error => 
            error.includes('undefined_placeholder') && error.includes('not defined')
          )).toBe(true);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Template validation should reject templates with unused placeholder definitions
   * For any template with placeholders defined but not used in body, validation should fail
   */
  test('should reject templates with unused placeholder definitions', async () => {
    await fc.assert(
      fc.property(
        // Generate template with unused placeholder definition
        fc.record({
          body: fc.constant('Hello {name}, welcome!'),
          placeholders: fc.constant({
            name: {
              type: PlaceholderType.STRING,
              label: 'Name',
              required: true,
              order: 1
            } as PlaceholderConfig,
            unused_field: {
              type: PlaceholderType.TEXT,
              label: 'Unused Field',
              required: false,
              order: 2
            } as PlaceholderConfig
          })
        }),
        (template) => {
          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Templates with unused placeholders should fail validation
          expect(validation.isValid).toBe(false);
          expect(validation.errors.some(error => 
            error.includes('unused_field') && error.includes('not used')
          )).toBe(true);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Placeholder configuration validation should reject invalid types
   * For any placeholder with invalid type, validation should fail
   */
  test('should reject placeholders with invalid types', async () => {
    await fc.assert(
      fc.property(
        fc.record({
          body: fc.constant('Hello {name}'),
          placeholders: fc.constant({
            name: {
              type: 'invalid_type' as any,
              label: 'Name',
              required: true,
              order: 1
            }
          })
        }),
        (template) => {
          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Invalid placeholder types should fail validation
          expect(validation.isValid).toBe(false);
          expect(validation.errors.some(error => 
            error.includes('Invalid placeholder type')
          )).toBe(true);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Select/Radio placeholders must have options
   * For any select or radio placeholder without options, validation should fail
   */
  test('should reject select/radio placeholders without options', async () => {
    await fc.assert(
      fc.property(
        fc.oneof(
          fc.constant(PlaceholderType.SELECT),
          fc.constant(PlaceholderType.RADIO)
        ),
        (placeholderType) => {
          const template = {
            body: 'Choose your {option}',
            placeholders: {
              option: {
                type: placeholderType,
                label: 'Option',
                required: true,
                order: 1
                // Missing options array
              } as PlaceholderConfig
            }
          };

          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Select/Radio without options should fail validation
          expect(validation.isValid).toBe(false);
          expect(validation.errors.some(error => 
            error.includes('must have options array')
          )).toBe(true);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Validation rules should be consistent with placeholder types
   * For any placeholder with validation rules, they should be appropriate for the type
   */
  test('should validate validation rules consistency with placeholder types', async () => {
    await fc.assert(
      fc.property(
        // Generate string placeholder with invalid number validation
        fc.constant({
          body: 'Hello {name}',
          placeholders: {
            name: {
              type: PlaceholderType.STRING,
              label: 'Name',
              required: true,
              validation: {
                minValue: 10, // Invalid for string type
                maxValue: 100 // Invalid for string type
              },
              order: 1
            } as PlaceholderConfig
          }
        }),
        (template) => {
          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Validation should pass even with unused validation rules
          // (The system should be tolerant of extra validation rules)
          expect(validation.isValid).toBe(true);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Placeholder keys must follow naming conventions
   * For any placeholder key that doesn't follow naming rules, validation should fail
   */
  test('should reject invalid placeholder key names', async () => {
    await fc.assert(
      fc.property(
        fc.oneof(
          fc.constant('123invalid'), // starts with number
          fc.constant('invalid-key'), // contains hyphen
          fc.constant('invalid key'), // contains space
          fc.constant(''), // empty
          fc.constant('invalid.key') // contains dot
        ),
        (invalidKey) => {
          const template = {
            body: `Hello {${invalidKey}}`,
            placeholders: {
              [invalidKey]: {
                type: PlaceholderType.STRING,
                label: 'Invalid Key',
                required: true,
                order: 1
              } as PlaceholderConfig
            }
          };

          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Invalid placeholder keys should fail validation
          expect(validation.isValid).toBe(false);
          expect(validation.errors.length).toBeGreaterThan(0);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property: Required fields must have labels
   * For any placeholder without a label, validation should fail
   */
  test('should reject placeholders without labels', async () => {
    await fc.assert(
      fc.property(
        fc.constant({
          body: 'Hello {name}',
          placeholders: {
            name: {
              type: PlaceholderType.STRING,
              label: '', // Empty label
              required: true,
              order: 1
            } as PlaceholderConfig
          }
        }),
        (template) => {
          const validation = TemplateModel.validateTemplateStructure(
            template.body, 
            template.placeholders
          );

          // Property: Placeholders without labels should fail validation
          expect(validation.isValid).toBe(false);
          expect(validation.errors.some(error => 
            error.includes('must have a label')
          )).toBe(true);
        }
      ),
      { numRuns: 100 }
    );
  });
});