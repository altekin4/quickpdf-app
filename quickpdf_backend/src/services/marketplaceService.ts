import { Pool } from 'pg';
import pool from '@/config/database';
import { Template, TemplateModel, TemplateStatus } from '@/models/Template';

export interface TemplateSearchFilters {
  search?: string;
  categoryId?: string;
  priceMin?: number;
  priceMax?: number;
  rating?: number;
  isFeatured?: boolean;
  isVerified?: boolean;
  status?: TemplateStatus;
  tags?: string[];
}

export interface TemplateSearchOptions {
  page?: number;
  limit?: number;
  sortBy?: 'rating' | 'downloads' | 'price' | 'date' | 'popularity';
  sortOrder?: 'asc' | 'desc';
}

export interface TemplateSearchResult {
  templates: Template[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
  filters: TemplateSearchFilters;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  parentId?: string;
  description?: string;
  icon?: string;
  orderIndex: number;
  isActive: boolean;
  templateCount: number;
  subcategories?: Category[];
  createdAt: Date;
  updatedAt: Date;
}

export interface Rating {
  id: string;
  userId: string;
  userName: string;
  templateId: string;
  rating: number;
  comment?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface RatingSummary {
  averageRating: number;
  totalRatings: number;
  ratingDistribution: Record<number, number>;
}

export interface Purchase {
  id: string;
  userId: string;
  templateId: string;
  amount: number;
  currency: string;
  paymentMethod: string;
  transactionId: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  purchasedAt: Date;
  completedAt?: Date;
}

export class MarketplaceService {
  private static pool: Pool = pool;

  /**
   * Search templates with filters and pagination
   */
  static async searchTemplates(
    filters: TemplateSearchFilters = {},
    options: TemplateSearchOptions = {}
  ): Promise<TemplateSearchResult> {
    const page = options.page || 1;
    const limit = Math.min(options.limit || 20, 100);
    const offset = (page - 1) * limit;
    const sortBy = options.sortBy || 'date';
    const sortOrder = options.sortOrder || 'desc';

    // Build WHERE clause
    const conditions: string[] = ['t.status = $1'];
    const values: any[] = ['published'];
    let paramCount = 1;

    if (filters.search) {
      paramCount++;
      conditions.push(`(
        to_tsvector('turkish', t.title || ' ' || t.description) @@ plainto_tsquery('turkish', $${paramCount})
        OR t.title ILIKE $${paramCount + 1}
        OR t.description ILIKE $${paramCount + 1}
      )`);
      values.push(filters.search, `%${filters.search}%`);
      paramCount++;
    }

    if (filters.categoryId) {
      paramCount++;
      conditions.push(`(t.category_id = $${paramCount} OR t.sub_category_id = $${paramCount})`);
      values.push(filters.categoryId);
    }

    if (filters.priceMin !== undefined) {
      paramCount++;
      conditions.push(`t.price >= $${paramCount}`);
      values.push(filters.priceMin);
    }

    if (filters.priceMax !== undefined) {
      paramCount++;
      conditions.push(`t.price <= $${paramCount}`);
      values.push(filters.priceMax);
    }

    if (filters.rating !== undefined) {
      paramCount++;
      conditions.push(`t.rating >= $${paramCount}`);
      values.push(filters.rating);
    }

    if (filters.isFeatured !== undefined) {
      paramCount++;
      conditions.push(`t.is_featured = $${paramCount}`);
      values.push(filters.isFeatured);
    }

    if (filters.isVerified !== undefined) {
      paramCount++;
      conditions.push(`t.is_verified = $${paramCount}`);
      values.push(filters.isVerified);
    }

    // Handle tags filter
    if (filters.tags && filters.tags.length > 0) {
      paramCount++;
      conditions.push(`t.id IN (
        SELECT tt.template_id 
        FROM template_tags tt 
        JOIN tags tg ON tt.tag_id = tg.id 
        WHERE tg.slug = ANY($${paramCount})
      )`);
      values.push(filters.tags);
    }

    // Build ORDER BY clause
    let orderBy = 't.created_at DESC';
    switch (sortBy) {
      case 'rating':
        orderBy = `t.rating ${sortOrder.toUpperCase()}, t.total_ratings ${sortOrder.toUpperCase()}`;
        break;
      case 'downloads':
        orderBy = `t.download_count ${sortOrder.toUpperCase()}`;
        break;
      case 'price':
        orderBy = `t.price ${sortOrder.toUpperCase()}`;
        break;
      case 'popularity':
        orderBy = `(t.download_count * 0.7 + t.total_ratings * 0.3) ${sortOrder.toUpperCase()}`;
        break;
      case 'date':
        orderBy = `t.created_at ${sortOrder.toUpperCase()}`;
        break;
    }

    // Main query
    const query = `
      SELECT 
        t.*,
        u.full_name as creator_name,
        c.name as category_name,
        sc.name as sub_category_name
      FROM templates t
      LEFT JOIN users u ON t.created_by = u.id
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN categories sc ON t.sub_category_id = sc.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY ${orderBy}
      LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}
    `;

    values.push(limit, offset);

    // Count query
    const countQuery = `
      SELECT COUNT(*) as total
      FROM templates t
      WHERE ${conditions.join(' AND ')}
    `;

    try {
      const [templatesResult, countResult] = await Promise.all([
        this.pool.query(query, values),
        this.pool.query(countQuery, values.slice(0, -2)) // Remove limit and offset for count
      ]);

      const templates = templatesResult.rows.map(row => TemplateModel.mapRowToTemplate(row));
      const total = parseInt(countResult.rows[0].total);
      const totalPages = Math.ceil(total / limit);

      return {
        templates,
        pagination: {
          page,
          limit,
          total,
          totalPages
        },
        filters
      };
    } catch (error) {
      throw new Error(`Failed to search templates: ${error}`);
    }
  }

  /**
   * Get featured templates
   */
  static async getFeaturedTemplates(limit: number = 10): Promise<Template[]> {
    const query = `
      SELECT t.*, u.full_name as creator_name
      FROM templates t
      LEFT JOIN users u ON t.created_by = u.id
      WHERE t.status = 'published' AND t.is_featured = true
      ORDER BY t.rating DESC, t.download_count DESC
      LIMIT $1
    `;

    try {
      const result = await this.pool.query(query, [limit]);
      return result.rows.map(row => TemplateModel.mapRowToTemplate(row));
    } catch (error) {
      throw new Error(`Failed to get featured templates: ${error}`);
    }
  }

  /**
   * Get popular templates by period
   */
  static async getPopularTemplates(
    period: '7d' | '30d' | '90d' | 'all' = '30d',
    limit: number = 10
  ): Promise<Template[]> {
    let dateFilter = '';
    if (period !== 'all') {
      const days = period === '7d' ? 7 : period === '30d' ? 30 : 90;
      dateFilter = `AND t.created_at >= NOW() - INTERVAL '${days} days'`;
    }

    const query = `
      SELECT t.*, u.full_name as creator_name
      FROM templates t
      LEFT JOIN users u ON t.created_by = u.id
      WHERE t.status = 'published' ${dateFilter}
      ORDER BY (t.download_count * 0.7 + t.total_ratings * 0.3) DESC
      LIMIT $1
    `;

    try {
      const result = await this.pool.query(query, [limit]);
      return result.rows.map(row => TemplateModel.mapRowToTemplate(row));
    } catch (error) {
      throw new Error(`Failed to get popular templates: ${error}`);
    }
  }

  /**
   * Get all categories with subcategories
   */
  static async getCategories(): Promise<Category[]> {
    const query = `
      SELECT 
        c.*,
        COUNT(t.id) as template_count
      FROM categories c
      LEFT JOIN templates t ON (c.id = t.category_id OR c.id = t.sub_category_id) 
        AND t.status = 'published'
      WHERE c.is_active = true
      GROUP BY c.id
      ORDER BY c.parent_id NULLS FIRST, c.order_index ASC, c.name ASC
    `;

    try {
      const result = await this.pool.query(query);
      const categories = result.rows.map(row => this.mapRowToCategory(row));
      
      // Organize into parent-child structure
      const categoryMap = new Map<string, Category>();
      const rootCategories: Category[] = [];

      // First pass: create all categories
      categories.forEach(category => {
        categoryMap.set(category.id, { ...category, subcategories: [] });
      });

      // Second pass: organize hierarchy
      categories.forEach(category => {
        if (category.parentId) {
          const parent = categoryMap.get(category.parentId);
          if (parent) {
            parent.subcategories!.push(categoryMap.get(category.id)!);
          }
        } else {
          rootCategories.push(categoryMap.get(category.id)!);
        }
      });

      return rootCategories;
    } catch (error) {
      throw new Error(`Failed to get categories: ${error}`);
    }
  }

  /**
   * Create a new category
   */
  static async createCategory(data: {
    name: string;
    slug: string;
    parentId?: string;
    description?: string;
    icon?: string;
    orderIndex?: number;
  }): Promise<Category> {
    const query = `
      INSERT INTO categories (name, slug, parent_id, description, icon, order_index)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;

    const values = [
      data.name,
      data.slug,
      data.parentId || null,
      data.description || null,
      data.icon || null,
      data.orderIndex || 0
    ];

    try {
      const result = await this.pool.query(query, values);
      return this.mapRowToCategory(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to create category: ${error}`);
    }
  }

  /**
   * Rate a template (user must have purchased it)
   */
  static async rateTemplate(
    userId: string,
    templateId: string,
    rating: number,
    comment?: string
  ): Promise<Rating> {
    // Check if user has purchased the template
    const purchaseCheck = await this.pool.query(
      'SELECT id FROM purchases WHERE user_id = $1 AND template_id = $2 AND status = $3',
      [userId, templateId, 'completed']
    );

    if (purchaseCheck.rows.length === 0) {
      throw new Error('You must purchase the template before rating it');
    }

    // Insert or update rating
    const query = `
      INSERT INTO ratings (user_id, template_id, rating, comment)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (user_id, template_id)
      DO UPDATE SET rating = $3, comment = $4, updated_at = NOW()
      RETURNING *
    `;

    try {
      const result = await this.pool.query(query, [userId, templateId, rating, comment]);
      
      // Update template rating statistics
      await this.updateTemplateRatingStats(templateId);
      
      return this.mapRowToRating(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to rate template: ${error}`);
    }
  }

  /**
   * Get template ratings with pagination
   */
  static async getTemplateRatings(
    templateId: string,
    page: number = 1,
    limit: number = 10
  ): Promise<{ ratings: Rating[]; pagination: any; summary: RatingSummary }> {
    const offset = (page - 1) * limit;

    const ratingsQuery = `
      SELECT r.*, u.full_name as user_name
      FROM ratings r
      LEFT JOIN users u ON r.user_id = u.id
      WHERE r.template_id = $1
      ORDER BY r.created_at DESC
      LIMIT $2 OFFSET $3
    `;

    const countQuery = `
      SELECT COUNT(*) as total
      FROM ratings
      WHERE template_id = $1
    `;

    const summaryQuery = `
      SELECT 
        AVG(rating)::DECIMAL(3,2) as average_rating,
        COUNT(*) as total_ratings,
        COUNT(CASE WHEN rating = 5 THEN 1 END) as rating_5,
        COUNT(CASE WHEN rating = 4 THEN 1 END) as rating_4,
        COUNT(CASE WHEN rating = 3 THEN 1 END) as rating_3,
        COUNT(CASE WHEN rating = 2 THEN 1 END) as rating_2,
        COUNT(CASE WHEN rating = 1 THEN 1 END) as rating_1
      FROM ratings
      WHERE template_id = $1
    `;

    try {
      const [ratingsResult, countResult, summaryResult] = await Promise.all([
        this.pool.query(ratingsQuery, [templateId, limit, offset]),
        this.pool.query(countQuery, [templateId]),
        this.pool.query(summaryQuery, [templateId])
      ]);

      const ratings = ratingsResult.rows.map(row => this.mapRowToRating(row));
      const total = parseInt(countResult.rows[0].total);
      const summary = summaryResult.rows[0];

      return {
        ratings,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        },
        summary: {
          averageRating: parseFloat(summary.average_rating) || 0,
          totalRatings: parseInt(summary.total_ratings),
          ratingDistribution: {
            5: parseInt(summary.rating_5),
            4: parseInt(summary.rating_4),
            3: parseInt(summary.rating_3),
            2: parseInt(summary.rating_2),
            1: parseInt(summary.rating_1)
          }
        }
      };
    } catch (error) {
      throw new Error(`Failed to get template ratings: ${error}`);
    }
  }

  /**
   * Update template rating statistics
   */
  private static async updateTemplateRatingStats(templateId: string): Promise<void> {
    const query = `
      UPDATE templates 
      SET 
        rating = (
          SELECT AVG(rating)::DECIMAL(3,2) 
          FROM ratings 
          WHERE template_id = $1
        ),
        total_ratings = (
          SELECT COUNT(*) 
          FROM ratings 
          WHERE template_id = $1
        )
      WHERE id = $1
    `;

    await this.pool.query(query, [templateId]);
  }

  /**
   * Generate template preview with sample data
   */
  static async generateTemplatePreview(templateId: string): Promise<{
    template: Template;
    sampleData: Record<string, any>;
    previewText: string;
  }> {
    const template = await TemplateModel.findById(templateId);
    if (!template) {
      throw new Error('Template not found');
    }

    // Generate sample data for placeholders
    const sampleData: Record<string, any> = {};
    
    for (const [key, config] of Object.entries(template.placeholders)) {
      sampleData[key] = this.generateSampleValue(config);
    }

    // Process template with sample data
    let previewText = template.body;
    for (const [key, value] of Object.entries(sampleData)) {
      const regex = new RegExp(`\\{${key}\\}`, 'g');
      previewText = previewText.replace(regex, value.toString());
    }

    return {
      template,
      sampleData,
      previewText
    };
  }

  /**
   * Generate sample value for placeholder
   */
  private static generateSampleValue(config: any): any {
    switch (config.type) {
      case 'string':
        return config.label.includes('Ad') ? 'Ahmet Yılmaz' : 'Örnek Metin';
      case 'text':
      case 'textarea':
        return 'Bu bir örnek metin alanıdır. Gerçek kullanımda buraya kullanıcı verisi gelecektir.';
      case 'date':
        return new Date().toLocaleDateString('tr-TR');
      case 'number':
        return config.validation?.minValue || 100;
      case 'email':
        return 'ornek@email.com';
      case 'phone':
        return '+90 555 123 45 67';
      case 'select':
      case 'radio':
        return config.options?.[0] || 'Seçenek 1';
      case 'checkbox':
        return true;
      default:
        return 'Örnek Değer';
    }
  }

  /**
   * Map database row to Category object
   */
  private static mapRowToCategory(row: any): Category {
    return {
      id: row.id,
      name: row.name,
      slug: row.slug,
      parentId: row.parent_id,
      description: row.description,
      icon: row.icon,
      orderIndex: row.order_index,
      isActive: row.is_active,
      templateCount: parseInt(row.template_count) || 0,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    };
  }

  /**
   * Map database row to Rating object
   */
  private static mapRowToRating(row: any): Rating {
    return {
      id: row.id,
      userId: row.user_id,
      userName: row.user_name || 'Anonim Kullanıcı',
      templateId: row.template_id,
      rating: row.rating,
      comment: row.comment,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    };
  }
}