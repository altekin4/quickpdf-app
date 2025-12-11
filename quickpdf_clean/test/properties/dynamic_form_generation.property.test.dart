/// **Feature: quickpdf-template-marketplace, Property 7: Dynamic Form Generation**
/// 
/// **Validates: Requirements 6.1, 6.2**
/// 
/// Property: For any template with defined placeholders, the system should generate 
/// a form with fields matching the placeholder types and validation rules
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:quickpdf_app/domain/entities/template.dart';
import 'package:quickpdf_app/presentation/providers/template_provider.dart';
import 'dart:math';

void main() {
  group('Dynamic Form Generation Property Tests', () {
    late TemplateProvider templateProvider;

    setUp(() {
      templateProvider = TemplateProvider();
    });

    /**
     * Property: Form configuration should include all template placeholders
     * For any template with placeholders, generated form should have fields for each placeholder
     */
    test('should generate form fields for all template placeholders', () {
      // Run property test with multiple random templates
      for (int i = 0; i < 100; i++) {
        final template = generateRandomTemplate();
        final formConfig = templateProvider.generateFormConfig(template);
        final fields = formConfig['fields'] as List<Map<String, dynamic>>;

        // Property: Form should have same number of fields as placeholders
        expect(fields.length, equals(template.placeholders.length));

        // Property: Each placeholder should have corresponding form field
        for (final placeholderKey in template.placeholders.keys) {
          final hasField = fields.any((field) => field['key'] == placeholderKey);
          expect(hasField, isTrue, reason: 'Missing form field for placeholder: $placeholderKey');
        }

        // Property: Form fields should maintain placeholder order
        final sortedPlaceholders = template.placeholders.entries.toList()
          ..sort((a, b) => a.value.order.compareTo(b.value.order));
        
        for (int j = 0; j < fields.length; j++) {
          expect(fields[j]['key'], equals(sortedPlaceholders[j].key));
          expect(fields[j]['order'], equals(sortedPlaceholders[j].value.order));
        }
      }
    });

    /**
     * Property: Form field types should match placeholder types
     * For any placeholder type, the generated form field should have the correct type
     */
    test('should generate correct field types for placeholder types', () {
      // Test each placeholder type
      for (final placeholderType in PlaceholderType.values) {
        final template = createTemplateWithPlaceholder('test_field', placeholderType);
        final formConfig = templateProvider.generateFormConfig(template);
        final fields = formConfig['fields'] as List<Map<String, dynamic>>;

        expect(fields.length, equals(1));
        
        final field = fields.first;
        
        // Property: Field type should match placeholder type
        expect(field['type'], equals(placeholderType.name));
        expect(field['key'], equals('test_field'));
      }
    });

    /**
     * Property: Required field validation should be preserved
     * For any placeholder marked as required, the form field should also be required
     */
    test('should preserve required field validation', () {
      // Test both required and optional fields
      for (final isRequired in [true, false]) {
        final template = createTemplateWithRequiredField('test_field', isRequired);
        final formConfig = templateProvider.generateFormConfig(template);
        final fields = formConfig['fields'] as List<Map<String, dynamic>>;

        expect(fields.length, equals(1));
        
        final field = fields.first;
        
        // Property: Form field required status should match placeholder
        expect(field['required'], equals(isRequired));
      }
    });

    /**
     * Property: Validation rules should be transferred to form fields
     * For any placeholder with validation rules, form field should include those rules
     */
    test('should transfer validation rules to form fields', () {
      // Test with various validation rules
      final validationRules = [
        null,
        const ValidationRules(minLength: 5, maxLength: 100),
        const ValidationRules(minValue: 0, maxValue: 1000),
        const ValidationRules(pattern: r'^[A-Za-z]+$'),
        const ValidationRules(minLength: 10, maxLength: 50, pattern: r'^[A-Za-z\s]+$'),
      ];

      for (final validation in validationRules) {
        final template = createTemplateWithValidation('test_field', validation);
        final formConfig = templateProvider.generateFormConfig(template);
        final fields = formConfig['fields'] as List<Map<String, dynamic>>;

        expect(fields.length, equals(1));
        
        final field = fields.first;
        final fieldValidation = field['validation'] as Map<String, dynamic>?;

        if (validation != null) {
          expect(fieldValidation, isNotNull);
          
          // Property: All validation rules should be preserved
          if (validation.minLength != null) {
            expect(fieldValidation!['minLength'], equals(validation.minLength));
          }
          if (validation.maxLength != null) {
            expect(fieldValidation!['maxLength'], equals(validation.maxLength));
          }
          if (validation.minValue != null) {
            expect(fieldValidation!['minValue'], equals(validation.minValue));
          }
          if (validation.maxValue != null) {
            expect(fieldValidation!['maxValue'], equals(validation.maxValue));
          }
          if (validation.pattern != null) {
            expect(fieldValidation!['pattern'], equals(validation.pattern));
          }
        }
      }
    });

    /**
     * Property: Select and radio fields should include options
     * For any select or radio placeholder with options, form field should include those options
     */
    test('should include options for select and radio fields', () {
      final optionsList = [
        ['Option 1', 'Option 2'],
        ['Yes', 'No', 'Maybe'],
        ['Small', 'Medium', 'Large', 'Extra Large'],
      ];

      for (final options in optionsList) {
        for (final type in [PlaceholderType.select, PlaceholderType.radio]) {
          final template = createTemplateWithOptions('test_field', type, options);
          final formConfig = templateProvider.generateFormConfig(template);
          final fields = formConfig['fields'] as List<Map<String, dynamic>>;

          expect(fields.length, equals(1));
          
          final field = fields.first;
          final fieldOptions = field['options'] as List<String>?;

          // Property: Form field should include all placeholder options
          expect(fieldOptions, isNotNull);
          expect(fieldOptions!.length, equals(options.length));
          
          for (final option in options) {
            expect(fieldOptions.contains(option), isTrue);
          }
        }
      }
    });

    /**
     * Property: Default values should be preserved in form fields
     * For any placeholder with default value, form field should include that default
     */
    test('should preserve default values in form fields', () {
      final defaultValues = [
        'default_string',
        42,
        true,
        'today',
        null,
      ];

      for (final defaultValue in defaultValues) {
        final template = createTemplateWithDefault('test_field', defaultValue);
        final formConfig = templateProvider.generateFormConfig(template);
        final fields = formConfig['fields'] as List<Map<String, dynamic>>;

        expect(fields.length, equals(1));
        
        final field = fields.first;
        
        // Property: Form field should preserve default value
        expect(field['defaultValue'], equals(defaultValue));
      }
    });

    /**
     * Property: Form configuration should include template metadata
     * For any template, form config should include template ID and title
     */
    test('should include template metadata in form config', () {
      // Test with multiple random templates
      for (int i = 0; i < 50; i++) {
        final template = generateRandomTemplate();
        final formConfig = templateProvider.generateFormConfig(template);

        // Property: Form config should include template metadata
        expect(formConfig['templateId'], equals(template.id));
        expect(formConfig['title'], equals(template.title));
        expect(formConfig['fields'], isA<List>());
      }
    });
  });
}

// Test data generators
Template generateRandomTemplate() {
  final random = Random();
  final placeholderCount = random.nextInt(5) + 1; // 1-5 placeholders
  final placeholders = <String, PlaceholderConfig>{};

  for (int i = 0; i < placeholderCount; i++) {
    final key = 'field_$i';
    placeholders[key] = PlaceholderConfig(
      type: PlaceholderType.values[random.nextInt(PlaceholderType.values.length)],
      label: 'Field $i',
      required: random.nextBool(),
      order: i,
    );
  }

  return Template(
    id: 'test_template_${random.nextInt(1000)}',
    title: 'Test Template ${random.nextInt(100)}',
    description: 'Test template description',
    categoryId: 'test_category',
    body: 'Test body with placeholders',
    placeholders: placeholders,
    createdBy: 'test_user',
    price: 0.0,
    status: TemplateStatus.published,
    isVerified: true,
    isFeatured: false,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    version: '1.0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

// Helper functions
Template createTemplateWithPlaceholder(String key, PlaceholderType type) {
  return Template(
    id: 'test_template',
    title: 'Test Template',
    description: 'Test description',
    categoryId: 'test_category',
    body: 'Test body with {$key}',
    placeholders: {
      key: PlaceholderConfig(
        type: type,
        label: 'Test Field',
        required: true,
        order: 1,
      ),
    },
    createdBy: 'test_user',
    price: 0.0,
    status: TemplateStatus.published,
    isVerified: true,
    isFeatured: false,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    version: '1.0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Template createTemplateWithRequiredField(String key, bool isRequired) {
  return Template(
    id: 'test_template',
    title: 'Test Template',
    description: 'Test description',
    categoryId: 'test_category',
    body: 'Test body with {$key}',
    placeholders: {
      key: PlaceholderConfig(
        type: PlaceholderType.string,
        label: 'Test Field',
        required: isRequired,
        order: 1,
      ),
    },
    createdBy: 'test_user',
    price: 0.0,
    status: TemplateStatus.published,
    isVerified: true,
    isFeatured: false,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    version: '1.0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Template createTemplateWithValidation(String key, ValidationRules? validation) {
  return Template(
    id: 'test_template',
    title: 'Test Template',
    description: 'Test description',
    categoryId: 'test_category',
    body: 'Test body with {$key}',
    placeholders: {
      key: PlaceholderConfig(
        type: PlaceholderType.string,
        label: 'Test Field',
        required: true,
        validation: validation,
        order: 1,
      ),
    },
    createdBy: 'test_user',
    price: 0.0,
    status: TemplateStatus.published,
    isVerified: true,
    isFeatured: false,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    version: '1.0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Template createTemplateWithOptions(String key, PlaceholderType type, List<String> options) {
  return Template(
    id: 'test_template',
    title: 'Test Template',
    description: 'Test description',
    categoryId: 'test_category',
    body: 'Test body with {$key}',
    placeholders: {
      key: PlaceholderConfig(
        type: type,
        label: 'Test Field',
        required: true,
        options: options,
        order: 1,
      ),
    },
    createdBy: 'test_user',
    price: 0.0,
    status: TemplateStatus.published,
    isVerified: true,
    isFeatured: false,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    version: '1.0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Template createTemplateWithDefault(String key, dynamic defaultValue) {
  return Template(
    id: 'test_template',
    title: 'Test Template',
    description: 'Test description',
    categoryId: 'test_category',
    body: 'Test body with {$key}',
    placeholders: {
      key: PlaceholderConfig(
        type: PlaceholderType.string,
        label: 'Test Field',
        required: true,
        defaultValue: defaultValue,
        order: 1,
      ),
    },
    createdBy: 'test_user',
    price: 0.0,
    status: TemplateStatus.published,
    isVerified: true,
    isFeatured: false,
    rating: 4.5,
    totalRatings: 10,
    downloadCount: 100,
    purchaseCount: 50,
    version: '1.0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}