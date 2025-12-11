import { Pool } from 'pg';
import pool from '@/config/database';

export interface PlaceholderConfig {
  type: PlaceholderType;
  label: string;
  required: boolean;
  validation?: ValidationRules;
  defaultValue?: any;
  options?: string[]; // for select type
  order: number;
}

export interface ValidationRules {
  minLength?: number;
  maxLength?: number;
  minValue?: number;
  maxValue?: number;
  pattern?: string;
}

export enum PlaceholderType {
  STRING = 'string',
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

export enum TemplateStatus {
  PENDING = 'pending',
  PUBLISHED = 'published',
  REJECTED = 'rejected'
}

export interface Template {
  id: string;
  title: string;
  description: string;
  categoryId: string;
  subCategoryId?: string;
  body: string;
  placeholders: Record<string, PlaceholderConfig>;
  createdBy: string;
  price: number;
  currency: string;
  isAdminTemplate: boolean;
  isVerified: boolean;
  isFeatured: boolean;
  status: TemplateStatus;
  rejectionReason?: string;
  rating: number;
  totalRatings: number;
  downloadCount: number;
  purchaseCount: number;
  revenue: number;
  version: string;
  previewImageUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateTemplateData {
  title: string;
  description: string;
  categoryId: string;
  subCategoryId?: string;
  body: string;
  placeholders: Record<string, PlaceholderConfig>;
  price: number;
  currency?: string;
}

export interface UpdateTemplateData {
  title?: string;
  description?: string;
  categoryId?: string;
  subCategoryId?: string;
  body?: string;
  placeholders?: Record<string, PlaceholderConfig>;
  price?: number;
  previewImageUrl?: string;
}

export class TemplateModel {
  private static pool: Pool = pool;

  /**
   * Create a new template
   */
  static async create(userId: string, data: CreateTemplateData): Promise<Template> {
    const query = `
      INSERT INTO templates (
        title, description, category_id, sub_category_id, body, 
        placeholders, created_by, price, currency
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `;

    const values = [
      data.title,
      data.description,
      data.categoryId,
      data.subCategoryId || null,
      data.body,
      JSON.stringify(data.placeholders),
      userId,
      data.price,
      data.currency || 'TRY'
    ];

    try {
      const result = await this.pool.query(query, values);
      return this.mapRowToTemplate(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to create template: ${error}`);
    }
  }

  /**
   * Get template by ID
   */
  static async findById(id: string): Promise<Template | null> {
    const query = `
      SELECT t.*, u.full_name as creator_name
      FROM templates t
      LEFT JOIN users u ON t.created_by = u.id
      WHERE t.id = $1
    `;

    try {
      const result = await this.pool.query(query, [id]);
      return result.rows.length > 0 ? this.mapRowToTemplate(result.rows[0]) : null;
    } catch (error) {
      throw new Error(`Failed to get template: ${error}`);
    }
  }

  /**
   * Update template
   */
  static async update(id: string, data: UpdateTemplateData): Promise<Template | null> {
    const fields = [];
    const values = [];
    let paramCount = 1;

    if (data.title !== undefined) {
      fields.push(`title = $${paramCount++}`);
      values.push(data.title);
    }
    if (data.description !== undefined) {
      fields.push(`description = $${paramCount++}`);
      values.push(data.description);
    }
    if (data.categoryId !== undefined) {
      fields.push(`category_id = $${paramCount++}`);
      values.push(data.categoryId);
    }
    if (data.subCategoryId !== undefined) {
      fields.push(`sub_category_id = $${paramCount++}`);
      values.push(data.subCategoryId);
    }
    if (data.body !== undefined) {
      fields.push(`body = $${paramCount++}`);
      values.push(data.body);
    }
    if (data.placeholders !== undefined) {
      fields.push(`placeholders = $${paramCount++}`);
      values.push(JSON.stringify(data.placeholders));
    }
    if (data.price !== undefined) {
      fields.push(`price = $${paramCount++}`);
      values.push(data.price);
    }
    if (data.previewImageUrl !== undefined) {
      fields.push(`preview_image_url = $${paramCount++}`);
      values.push(data.previewImageUrl);
    }

    if (fields.length === 0) {
      throw new Error('No fields to update');
    }

    fields.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE templates 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    try {
      const result = await this.pool.query(query, values);
      return result.rows.length > 0 ? this.mapRowToTemplate(result.rows[0]) : null;
    } catch (error) {
      throw new Error(`Failed to update template: ${error}`);
    }
  }

  /**
   * Validate template structure and placeholders
   */
  static validateTemplateStructure(body: string, placeholders: Record<string, PlaceholderConfig>): {
    isValid: boolean;
    errors: string[];
  } {
    const errors: string[] = [];

    // Extract placeholders from body using regex
    const bodyPlaceholders = new Set<string>();
    const placeholderRegex = /\{([^}]+)\}/g;
    let match;
    
    while ((match = placeholderRegex.exec(body)) !== null) {
      bodyPlaceholders.add(match[1]);
    }

    // Check if all placeholders in body are defined
    for (const placeholder of bodyPlaceholders) {
      if (!placeholders[placeholder]) {
        errors.push(`Placeholder '{${placeholder}}' used in body but not defined in placeholders`);
      }
    }

    // Check if all defined placeholders are used in body
    for (const placeholderKey of Object.keys(placeholders)) {
      if (!bodyPlaceholders.has(placeholderKey)) {
        errors.push(`Placeholder '${placeholderKey}' defined but not used in body`);
      }
    }

    // Validate placeholder configurations
    for (const [key, config] of Object.entries(placeholders)) {
      const placeholderErrors = this.validatePlaceholderConfig(key, config);
      errors.push(...placeholderErrors);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Validate individual placeholder configuration
   */
  private static validatePlaceholderConfig(key: string, config: PlaceholderConfig): string[] {
    const errors: string[] = [];

    // Validate placeholder key
    if (!key || key.trim().length === 0) {
      errors.push('Placeholder key cannot be empty');
    }

    if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(key)) {
      errors.push(`Placeholder key '${key}' must start with letter or underscore and contain only letters, numbers, and underscores`);
    }

    // Validate type
    if (!Object.values(PlaceholderType).includes(config.type)) {
      errors.push(`Invalid placeholder type '${config.type}' for '${key}'`);
    }

    // Validate label
    if (!config.label || config.label.trim().length === 0) {
      errors.push(`Placeholder '${key}' must have a label`);
    }

    // Validate order
    if (typeof config.order !== 'number' || config.order < 0) {
      errors.push(`Placeholder '${key}' must have a valid order (non-negative number)`);
    }

    // Validate select type options
    if (config.type === PlaceholderType.SELECT || config.type === PlaceholderType.RADIO) {
      if (!config.options || !Array.isArray(config.options) || config.options.length === 0) {
        errors.push(`Placeholder '${key}' of type '${config.type}' must have options array`);
      }
    }

    // Validate validation rules
    if (config.validation) {
      const validationErrors = this.validateValidationRules(key, config.validation, config.type);
      errors.push(...validationErrors);
    }

    return errors;
  }

  /**
   * Validate validation rules for a placeholder
   */
  private static validateValidationRules(key: string, rules: ValidationRules, type: PlaceholderType): string[] {
    const errors: string[] = [];

    // String/text length validation
    if (type === PlaceholderType.STRING || type === PlaceholderType.TEXT || type === PlaceholderType.TEXTAREA) {
      if (rules.minLength !== undefined && (typeof rules.minLength !== 'number' || rules.minLength < 0)) {
        errors.push(`Placeholder '${key}' minLength must be a non-negative number`);
      }
      if (rules.maxLength !== undefined && (typeof rules.maxLength !== 'number' || rules.maxLength < 1)) {
        errors.push(`Placeholder '${key}' maxLength must be a positive number`);
      }
      if (rules.minLength !== undefined && rules.maxLength !== undefined && rules.minLength > rules.maxLength) {
        errors.push(`Placeholder '${key}' minLength cannot be greater than maxLength`);
      }
    }

    // Number validation
    if (type === PlaceholderType.NUMBER) {
      if (rules.minValue !== undefined && typeof rules.minValue !== 'number') {
        errors.push(`Placeholder '${key}' minValue must be a number`);
      }
      if (rules.maxValue !== undefined && typeof rules.maxValue !== 'number') {
        errors.push(`Placeholder '${key}' maxValue must be a number`);
      }
      if (rules.minValue !== undefined && rules.maxValue !== undefined && rules.minValue > rules.maxValue) {
        errors.push(`Placeholder '${key}' minValue cannot be greater than maxValue`);
      }
    }

    // Pattern validation
    if (rules.pattern !== undefined) {
      try {
        new RegExp(rules.pattern);
      } catch (e) {
        errors.push(`Placeholder '${key}' has invalid regex pattern: ${rules.pattern}`);
      }
    }

    return errors;
  }

  /**
   * Map database row to Template object
   */
  static mapRowToTemplate(row: any): Template {
    return {
      id: row.id,
      title: row.title,
      description: row.description,
      categoryId: row.category_id,
      subCategoryId: row.sub_category_id,
      body: row.body,
      placeholders: typeof row.placeholders === 'string' ? JSON.parse(row.placeholders) : row.placeholders,
      createdBy: row.created_by,
      price: parseFloat(row.price),
      currency: row.currency,
      isAdminTemplate: row.is_admin_template,
      isVerified: row.is_verified,
      isFeatured: row.is_featured,
      status: row.status as TemplateStatus,
      rejectionReason: row.rejection_reason,
      rating: parseFloat(row.rating),
      totalRatings: parseInt(row.total_ratings),
      downloadCount: parseInt(row.download_count),
      purchaseCount: parseInt(row.purchase_count),
      revenue: parseFloat(row.revenue),
      version: row.version,
      previewImageUrl: row.preview_image_url,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    };
  }
}