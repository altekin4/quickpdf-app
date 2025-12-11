import { Template, PlaceholderType, PlaceholderConfig } from '@/models/Template';

export interface ProcessedTemplate {
  template: Template;
  processedBody: string;
  userData: Record<string, any>;
  injectionMetadata: InjectionMetadata;
}

export interface InjectionMetadata {
  placeholdersProcessed: number;
  placeholdersSkipped: string[];
  sanitizedFields: string[];
  formattedFields: Record<string, string>;
}

export class TemplateDataInjectionService {
  /**
   * Process template with user data and inject safely
   */
  static processTemplate(template: Template, userData: Record<string, any>): ProcessedTemplate {
    const metadata: InjectionMetadata = {
      placeholdersProcessed: 0,
      placeholdersSkipped: [],
      sanitizedFields: [],
      formattedFields: {}
    };

    // Validate user data first
    const validation = this.validateUserData(template, userData);
    if (!validation.isValid) {
      throw new Error(`User data validation failed: ${validation.errors.join(', ')}`);
    }

    // Process the template body by replacing placeholders
    let processedBody = template.body;

    for (const [key, config] of Object.entries(template.placeholders)) {
      const value = userData[key];
      
      if (value === undefined || value === null) {
        if (config.required) {
          throw new Error(`Required field '${config.label}' is missing`);
        }
        metadata.placeholdersSkipped.push(key);
        continue;
      }

      // Sanitize and format the value
      const sanitizedValue = this.sanitizeValue(value, config);
      const formattedValue = this.formatValueForTemplate(sanitizedValue, config);
      
      // Track metadata
      metadata.placeholdersProcessed++;
      if (sanitizedValue !== value) {
        metadata.sanitizedFields.push(key);
      }
      metadata.formattedFields[key] = formattedValue;
      
      // Replace all occurrences of the placeholder
      const placeholderRegex = new RegExp(`\\{${this.escapeRegex(key)}\\}`, 'g');
      processedBody = processedBody.replace(placeholderRegex, formattedValue);
    }

    // Check for any remaining unprocessed placeholders
    const remainingPlaceholders = this.findRemainingPlaceholders(processedBody);
    if (remainingPlaceholders.length > 0) {
      console.warn(`Unprocessed placeholders found: ${remainingPlaceholders.join(', ')}`);
    }

    return {
      template,
      processedBody,
      userData,
      injectionMetadata: metadata
    };
  }

  /**
   * Validate user data against template placeholders
   */
  private static validateUserData(template: Template, userData: Record<string, any>): {
    isValid: boolean;
    errors: string[];
  } {
    const errors: string[] = [];

    for (const [key, config] of Object.entries(template.placeholders)) {
      const value = userData[key];

      // Check required fields
      if (config.required && (value === undefined || value === null || value === '')) {
        errors.push(`Field '${config.label}' is required`);
        continue;
      }

      // Skip validation for empty optional fields
      if (!config.required && (value === undefined || value === null || value === '')) {
        continue;
      }

      // Type-specific validation
      const typeErrors = this.validateFieldValue(key, config, value);
      errors.push(...typeErrors);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Validate individual field value
   */
  private static validateFieldValue(key: string, config: PlaceholderConfig, value: any): string[] {
    const errors: string[] = [];

    switch (config.type) {
      case PlaceholderType.STRING:
      case PlaceholderType.TEXT:
      case PlaceholderType.TEXTAREA:
        if (typeof value !== 'string') {
          errors.push(`Field '${config.label}' must be a string`);
          break;
        }
        if (config.validation?.minLength && value.length < config.validation.minLength) {
          errors.push(`Field '${config.label}' must be at least ${config.validation.minLength} characters`);
        }
        if (config.validation?.maxLength && value.length > config.validation.maxLength) {
          errors.push(`Field '${config.label}' must be at most ${config.validation.maxLength} characters`);
        }
        if (config.validation?.pattern && !new RegExp(config.validation.pattern).test(value)) {
          errors.push(`Field '${config.label}' format is invalid`);
        }
        break;

      case PlaceholderType.NUMBER:
        const numValue = typeof value === 'string' ? parseFloat(value) : value;
        if (isNaN(numValue)) {
          errors.push(`Field '${config.label}' must be a valid number`);
          break;
        }
        if (config.validation?.minValue !== undefined && numValue < config.validation.minValue) {
          errors.push(`Field '${config.label}' must be at least ${config.validation.minValue}`);
        }
        if (config.validation?.maxValue !== undefined && numValue > config.validation.maxValue) {
          errors.push(`Field '${config.label}' must be at most ${config.validation.maxValue}`);
        }
        break;

      case PlaceholderType.DATE:
        if (typeof value !== 'string' || isNaN(Date.parse(value))) {
          errors.push(`Field '${config.label}' must be a valid date`);
        }
        break;

      case PlaceholderType.EMAIL:
        if (typeof value !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
          errors.push(`Field '${config.label}' must be a valid email address`);
        }
        break;

      case PlaceholderType.PHONE:
        if (typeof value !== 'string' || !/^[\+]?[0-9\s\-\(\)]{10,}$/.test(value)) {
          errors.push(`Field '${config.label}' must be a valid phone number`);
        }
        break;

      case PlaceholderType.SELECT:
      case PlaceholderType.RADIO:
        if (config.options && !config.options.includes(value)) {
          errors.push(`Field '${config.label}' must be one of the available options`);
        }
        break;

      case PlaceholderType.CHECKBOX:
        if (typeof value !== 'boolean') {
          errors.push(`Field '${config.label}' must be true or false`);
        }
        break;
    }

    return errors;
  }

  /**
   * Sanitize value to prevent injection attacks
   */
  private static sanitizeValue(value: any, config: PlaceholderConfig): any {
    if (value === null || value === undefined) {
      return value;
    }

    // For string-based types, sanitize HTML and potentially dangerous characters
    if (config.type === PlaceholderType.STRING || 
        config.type === PlaceholderType.TEXT || 
        config.type === PlaceholderType.TEXTAREA ||
        config.type === PlaceholderType.EMAIL) {
      
      let sanitized = value.toString();
      
      // Remove HTML tags
      sanitized = sanitized.replace(/<[^>]*>/g, '');
      
      // Remove potentially dangerous characters for PDF generation
      sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
      
      // Limit length to prevent memory issues
      if (sanitized.length > 10000) {
        sanitized = sanitized.substring(0, 10000) + '...';
      }
      
      return sanitized;
    }

    return value;
  }

  /**
   * Format value for template injection
   */
  private static formatValueForTemplate(value: any, config: PlaceholderConfig): string {
    if (value === undefined || value === null) {
      return '';
    }

    switch (config.type) {
      case PlaceholderType.DATE:
        // Format date in Turkish format (DD.MM.YYYY)
        const date = new Date(value);
        if (isNaN(date.getTime())) {
          return value.toString();
        }
        return date.toLocaleDateString('tr-TR', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric'
        });

      case PlaceholderType.CHECKBOX:
        return value ? 'Evet' : 'Hayır';

      case PlaceholderType.NUMBER:
        const num = typeof value === 'number' ? value : parseFloat(value);
        if (isNaN(num)) {
          return value.toString();
        }
        // Format numbers with Turkish locale
        return num.toLocaleString('tr-TR');

      case PlaceholderType.PHONE:
        // Format phone number
        let phone = value.toString().replace(/\D/g, '');
        if (phone.startsWith('90')) {
          phone = phone.substring(2);
        }
        if (phone.length === 10) {
          return `(${phone.substring(0, 3)}) ${phone.substring(3, 6)} ${phone.substring(6, 8)} ${phone.substring(8)}`;
        }
        return value.toString();

      default:
        return value.toString();
    }
  }

  /**
   * Find remaining unprocessed placeholders in text
   */
  private static findRemainingPlaceholders(text: string): string[] {
    const placeholderRegex = /\{([^}]+)\}/g;
    const matches: string[] = [];
    let match;

    while ((match = placeholderRegex.exec(text)) !== null) {
      matches.push(match[1]);
    }

    return [...new Set(matches)]; // Remove duplicates
  }

  /**
   * Escape special regex characters
   */
  private static escapeRegex(string: string): string {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Generate preview of processed template
   */
  static generatePreview(template: Template, userData: Record<string, any>): {
    preview: string;
    warnings: string[];
  } {
    const warnings: string[] = [];
    
    try {
      const processed = this.processTemplate(template, userData);
      
      // Add warnings for skipped placeholders
      if (processed.injectionMetadata.placeholdersSkipped.length > 0) {
        warnings.push(`Boş bırakılan alanlar: ${processed.injectionMetadata.placeholdersSkipped.join(', ')}`);
      }
      
      // Add warnings for sanitized fields
      if (processed.injectionMetadata.sanitizedFields.length > 0) {
        warnings.push(`Güvenlik nedeniyle temizlenen alanlar: ${processed.injectionMetadata.sanitizedFields.join(', ')}`);
      }

      return {
        preview: processed.processedBody,
        warnings
      };
    } catch (error) {
      return {
        preview: `Önizleme oluşturulamadı: ${error instanceof Error ? error.message : 'Bilinmeyen hata'}`,
        warnings: ['Önizleme hatası']
      };
    }
  }

  /**
   * Validate template structure for data injection
   */
  static validateTemplateForInjection(template: Template): {
    isValid: boolean;
    errors: string[];
    warnings: string[];
  } {
    const errors: string[] = [];
    const warnings: string[] = [];

    // Check if template body contains placeholders
    const bodyPlaceholders = this.findRemainingPlaceholders(template.body);
    const definedPlaceholders = Object.keys(template.placeholders);

    // Check for undefined placeholders in body
    for (const placeholder of bodyPlaceholders) {
      if (!definedPlaceholders.includes(placeholder)) {
        errors.push(`Placeholder '{${placeholder}}' used in body but not defined`);
      }
    }

    // Check for unused placeholder definitions
    for (const placeholder of definedPlaceholders) {
      if (!bodyPlaceholders.includes(placeholder)) {
        warnings.push(`Placeholder '${placeholder}' defined but not used in body`);
      }
    }

    // Check for potential security issues
    if (template.body.includes('<script>') || template.body.includes('javascript:')) {
      errors.push('Template body contains potentially dangerous content');
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }
}