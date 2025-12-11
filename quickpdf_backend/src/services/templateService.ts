import { 
  TemplateModel, 
  Template, 
  CreateTemplateData, 
  UpdateTemplateData,
  PlaceholderConfig,
  PlaceholderType,
  TemplateStatus
} from '@/models/Template';

export interface TemplateSearchFilters {
  category?: string;
  search?: string;
  priceMin?: number;
  priceMax?: number;
  rating?: number;
  status?: TemplateStatus;
  isVerified?: boolean;
  isFeatured?: boolean;
}

export interface TemplateSearchOptions {
  page?: number;
  limit?: number;
  sort?: 'rating' | 'downloads' | 'price' | 'date';
  order?: 'asc' | 'desc';
}

export interface ProcessedTemplate {
  template: Template;
  processedBody: string;
  userData: Record<string, any>;
}

export class TemplateService {
  /**
   * Create a new template with validation
   */
  static async createTemplate(userId: string, data: CreateTemplateData): Promise<Template> {
    // Validate template structure
    const validation = TemplateModel.validateTemplateStructure(data.body, data.placeholders);
    if (!validation.isValid) {
      throw new Error(`Template validation failed: ${validation.errors.join(', ')}`);
    }

    // Validate price range (5-500 TL or free)
    if (data.price !== 0 && (data.price < 5 || data.price > 500)) {
      throw new Error('Template price must be 0 (free) or between 5 and 500 TL');
    }

    return await TemplateModel.create(userId, data);
  }

  /**
   * Update template with validation
   */
  static async updateTemplate(templateId: string, data: UpdateTemplateData): Promise<Template | null> {
    // If body or placeholders are being updated, validate the structure
    if (data.body !== undefined || data.placeholders !== undefined) {
      const existingTemplate = await TemplateModel.findById(templateId);
      if (!existingTemplate) {
        throw new Error('Template not found');
      }

      const bodyToValidate = data.body !== undefined ? data.body : existingTemplate.body;
      const placeholdersToValidate = data.placeholders !== undefined ? data.placeholders : existingTemplate.placeholders;

      const validation = TemplateModel.validateTemplateStructure(bodyToValidate, placeholdersToValidate);
      if (!validation.isValid) {
        throw new Error(`Template validation failed: ${validation.errors.join(', ')}`);
      }
    }

    // Validate price range if being updated
    if (data.price !== undefined && data.price !== 0 && (data.price < 5 || data.price > 500)) {
      throw new Error('Template price must be 0 (free) or between 5 and 500 TL');
    }

    return await TemplateModel.update(templateId, data);
  }

  /**
   * Generate dynamic form configuration from template placeholders
   */
  static generateFormConfig(template: Template): FormConfig {
    const fields: FormField[] = [];

    // Sort placeholders by order
    const sortedPlaceholders = Object.entries(template.placeholders)
      .sort(([, a], [, b]) => a.order - b.order);

    for (const [key, config] of sortedPlaceholders) {
      fields.push(this.createFormField(key, config));
    }

    return {
      templateId: template.id,
      title: template.title,
      fields
    };
  }

  /**
   * Create form field from placeholder config
   */
  private static createFormField(key: string, config: PlaceholderConfig): FormField {
    const field: FormField = {
      key,
      type: this.mapPlaceholderTypeToFormType(config.type),
      label: config.label,
      required: config.required,
      order: config.order
    };

    // Add validation rules
    if (config.validation) {
      field.validation = { ...config.validation };
    }

    // Add default value
    if (config.defaultValue !== undefined) {
      if (config.type === PlaceholderType.DATE && config.defaultValue === 'today') {
        field.defaultValue = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
      } else {
        field.defaultValue = config.defaultValue;
      }
    }

    // Add options for select/radio types
    if (config.options && (config.type === PlaceholderType.SELECT || config.type === PlaceholderType.RADIO)) {
      field.options = config.options.map((option, index) => ({
        value: option,
        label: option,
        order: index
      }));
    }

    return field;
  }

  /**
   * Map placeholder type to form field type
   */
  private static mapPlaceholderTypeToFormType(type: PlaceholderType): FormFieldType {
    switch (type) {
      case PlaceholderType.STRING:
        return FormFieldType.TEXT;
      case PlaceholderType.TEXT:
      case PlaceholderType.TEXTAREA:
        return FormFieldType.TEXTAREA;
      case PlaceholderType.DATE:
        return FormFieldType.DATE;
      case PlaceholderType.NUMBER:
        return FormFieldType.NUMBER;
      case PlaceholderType.PHONE:
        return FormFieldType.PHONE;
      case PlaceholderType.EMAIL:
        return FormFieldType.EMAIL;
      case PlaceholderType.SELECT:
        return FormFieldType.SELECT;
      case PlaceholderType.CHECKBOX:
        return FormFieldType.CHECKBOX;
      case PlaceholderType.RADIO:
        return FormFieldType.RADIO;
      default:
        return FormFieldType.TEXT;
    }
  }

  /**
   * Validate user data against template placeholders
   */
  static validateUserData(template: Template, userData: Record<string, any>): {
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
   * Process template with user data (inject data into placeholders)
   */
  static processTemplate(template: Template, userData: Record<string, any>): ProcessedTemplate {
    // Validate user data first
    const validation = this.validateUserData(template, userData);
    if (!validation.isValid) {
      throw new Error(`User data validation failed: ${validation.errors.join(', ')}`);
    }

    // Process the template body by replacing placeholders
    let processedBody = template.body;

    for (const [key, config] of Object.entries(template.placeholders)) {
      const value = userData[key];
      const formattedValue = this.formatValueForTemplate(value, config);
      
      // Replace all occurrences of the placeholder
      const placeholderRegex = new RegExp(`\\{${key}\\}`, 'g');
      processedBody = processedBody.replace(placeholderRegex, formattedValue);
    }

    return {
      template,
      processedBody,
      userData
    };
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
        return date.toLocaleDateString('tr-TR');

      case PlaceholderType.CHECKBOX:
        return value ? 'Evet' : 'Hayır';

      case PlaceholderType.NUMBER:
        return typeof value === 'number' ? value.toString() : value;

      default:
        return value.toString();
    }
  }
}

// Form configuration interfaces
export interface FormConfig {
  templateId: string;
  title: string;
  fields: FormField[];
}

export interface FormField {
  key: string;
  type: FormFieldType;
  label: string;
  required: boolean;
  order: number;
  validation?: {
    minLength?: number;
    maxLength?: number;
    minValue?: number;
    maxValue?: number;
    pattern?: string;
  };
  defaultValue?: any;
  options?: FormOption[];
}

export interface FormOption {
  value: string;
  label: string;
  order: number;
}

export enum FormFieldType {
  TEXT = 'text',
  TEXTAREA = 'textarea',
  DATE = 'date',
  NUMBER = 'number',
  PHONE = 'phone',
  EMAIL = 'email',
  SELECT = 'select',
  CHECKBOX = 'checkbox',
  RADIO = 'radio'
}