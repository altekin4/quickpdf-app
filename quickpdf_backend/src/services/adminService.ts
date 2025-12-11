import { Pool } from 'pg';
import { logger } from '@/utils/logger';
import { createError } from '@/middleware/errorHandler';
import { NotificationService } from './notificationService';

interface DashboardStats {
  totalUsers: number;
  totalTemplates: number;
  totalDocuments: number;
  totalRevenue: number;
  activeUsers: number;
  pendingTemplates: number;
  thisMonthUsers: number;
  thisMonthRevenue: number;
}

interface UserGrowthData {
  date: string;
  users: number;
}

interface RevenueFlowData {
  date: string;
  revenue: number;
}

interface DashboardData {
  stats: DashboardStats;
  charts: {
    userGrowth: UserGrowthData[];
    revenueFlow: RevenueFlowData[];
  };
}

interface PendingTemplate {
  id: string;
  title: string;
  description: string;
  createdBy: string;
  creatorName: string;
  categoryId: string;
  categoryName: string;
  price: number;
  submittedAt: string;
  placeholderCount: number;
}

interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  role: string;
  isVerified: boolean;
  isActive: boolean;
  templateCount: number;
  totalEarnings: number;
  createdAt: string;
  lastLogin: string | null;
}

interface PaymentStats {
  totalRevenue: number;
  totalTransactions: number;
  averageTransactionValue: number;
  platformCommission: number;
  creatorPayouts: number;
  pendingPayouts: number;
}

interface PaymentBreakdown {
  date: string;
  revenue: number;
  transactions: number;
  commission: number;
}

interface AdminCategory {
  id: string;
  name: string;
  slug: string;
  parentId: string | null;
  parentName: string | null;
  description: string | null;
  icon: string | null;
  orderIndex: number;
  isActive: boolean;
  templateCount: number;
  createdAt: string;
  updatedAt: string;
}

interface TemplateReviewDetails {
  id: string;
  title: string;
  description: string;
  body: string;
  placeholders: Record<string, any>;
  createdBy: string;
  creatorName: string;
  creatorEmail: string;
  categoryId: string;
  categoryName: string;
  price: number;
  submittedAt: string;
  version: string;
  previewImageUrl: string | null;
}

export class AdminService {
  private notificationService: NotificationService;

  constructor(private db: Pool) {
    this.notificationService = new NotificationService(db);
  }

  /**
   * Get dashboard statistics and analytics data
   */
  async getDashboardData(): Promise<DashboardData> {
    try {
      // Get basic statistics
      const statsQuery = `
        SELECT 
          (SELECT COUNT(*) FROM users WHERE role != 'admin') as total_users,
          (SELECT COUNT(*) FROM templates WHERE status = 'published') as total_templates,
          (SELECT COUNT(*) FROM documents) as total_documents,
          (SELECT COALESCE(SUM(amount), 0) FROM purchases WHERE status = 'completed') as total_revenue,
          (SELECT COUNT(DISTINCT user_id) FROM documents WHERE created_at >= NOW() - INTERVAL '30 days') as active_users,
          (SELECT COUNT(*) FROM templates WHERE status = 'pending') as pending_templates,
          (SELECT COUNT(*) FROM users WHERE created_at >= DATE_TRUNC('month', NOW()) AND role != 'admin') as this_month_users,
          (SELECT COALESCE(SUM(amount), 0) FROM purchases WHERE status = 'completed' AND purchased_at >= DATE_TRUNC('month', NOW())) as this_month_revenue
      `;

      const statsResult = await this.db.query(statsQuery);
      const stats = statsResult.rows[0];

      // Get user growth data (last 30 days)
      const userGrowthQuery = `
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as users
        FROM users 
        WHERE created_at >= NOW() - INTERVAL '30 days' AND role != 'admin'
        GROUP BY DATE(created_at)
        ORDER BY date
      `;

      const userGrowthResult = await this.db.query(userGrowthQuery);
      
      // Get revenue flow data (last 30 days)
      const revenueFlowQuery = `
        SELECT 
          DATE(purchased_at) as date,
          COALESCE(SUM(amount), 0) as revenue
        FROM purchases 
        WHERE purchased_at >= NOW() - INTERVAL '30 days' AND status = 'completed'
        GROUP BY DATE(purchased_at)
        ORDER BY date
      `;

      const revenueFlowResult = await this.db.query(revenueFlowQuery);

      return {
        stats: {
          totalUsers: parseInt(stats.total_users) || 0,
          totalTemplates: parseInt(stats.total_templates) || 0,
          totalDocuments: parseInt(stats.total_documents) || 0,
          totalRevenue: parseFloat(stats.total_revenue) || 0,
          activeUsers: parseInt(stats.active_users) || 0,
          pendingTemplates: parseInt(stats.pending_templates) || 0,
          thisMonthUsers: parseInt(stats.this_month_users) || 0,
          thisMonthRevenue: parseFloat(stats.this_month_revenue) || 0,
        },
        charts: {
          userGrowth: userGrowthResult.rows.map(row => ({
            date: row.date,
            users: parseInt(row.users),
          })),
          revenueFlow: revenueFlowResult.rows.map(row => ({
            date: row.date,
            revenue: parseFloat(row.revenue),
          })),
        },
      };
    } catch (error) {
      logger.error('Error getting dashboard data:', error);
      throw createError('Failed to fetch dashboard data', 500);
    }
  }

  /**
   * Get pending templates for review
   */
  async getPendingTemplates(page: number = 1, limit: number = 20): Promise<{
    templates: PendingTemplate[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      const offset = (page - 1) * limit;

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as total
        FROM templates t
        WHERE t.status = 'pending'
      `;

      const countResult = await this.db.query(countQuery);
      const total = parseInt(countResult.rows[0].total);

      // Get pending templates with creator and category info
      const templatesQuery = `
        SELECT 
          t.id,
          t.title,
          t.description,
          t.created_by,
          u.full_name as creator_name,
          t.category_id,
          c.name as category_name,
          t.price,
          t.created_at as submitted_at,
          jsonb_object_keys(t.placeholders) as placeholder_keys
        FROM templates t
        LEFT JOIN users u ON t.created_by = u.id
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.status = 'pending'
        ORDER BY t.created_at ASC
        LIMIT $1 OFFSET $2
      `;

      const templatesResult = await this.db.query(templatesQuery, [limit, offset]);

      // Count placeholders for each template
      const templates: PendingTemplate[] = [];
      for (const row of templatesResult.rows) {
        const placeholderCountQuery = `
          SELECT jsonb_object_keys(placeholders) as keys
          FROM templates 
          WHERE id = $1
        `;
        const placeholderResult = await this.db.query(placeholderCountQuery, [row.id]);
        
        templates.push({
          id: row.id,
          title: row.title,
          description: row.description,
          createdBy: row.created_by,
          creatorName: row.creator_name || 'Unknown Creator',
          categoryId: row.category_id,
          categoryName: row.category_name || 'Uncategorized',
          price: parseFloat(row.price) || 0,
          submittedAt: row.submitted_at,
          placeholderCount: placeholderResult.rows.length,
        });
      }

      return {
        templates,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      logger.error('Error getting pending templates:', error);
      throw createError('Failed to fetch pending templates', 500);
    }
  }

  /**
   * Get template details for review
   */
  async getTemplateForReview(templateId: string): Promise<TemplateReviewDetails> {
    try {
      const query = `
        SELECT 
          t.id,
          t.title,
          t.description,
          t.body,
          t.placeholders,
          t.created_by,
          u.full_name as creator_name,
          u.email as creator_email,
          t.category_id,
          c.name as category_name,
          t.price,
          t.created_at as submitted_at,
          t.version,
          t.preview_image_url
        FROM templates t
        LEFT JOIN users u ON t.created_by = u.id
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.id = $1 AND t.status = 'pending'
      `;

      const result = await this.db.query(query, [templateId]);

      if (result.rows.length === 0) {
        throw createError('Template not found or not pending review', 404);
      }

      const row = result.rows[0];

      return {
        id: row.id,
        title: row.title,
        description: row.description,
        body: row.body,
        placeholders: row.placeholders || {},
        createdBy: row.created_by,
        creatorName: row.creator_name || 'Unknown Creator',
        creatorEmail: row.creator_email || '',
        categoryId: row.category_id,
        categoryName: row.category_name || 'Uncategorized',
        price: parseFloat(row.price) || 0,
        submittedAt: row.submitted_at,
        version: row.version || '1.0',
        previewImageUrl: row.preview_image_url,
      };
    } catch (error) {
      logger.error('Error getting template for review:', error);
      throw error;
    }
  }

  /**
   * Validate template quality (automated checks)
   */
  async validateTemplateQuality(templateId: string): Promise<{
    isValid: boolean;
    issues: string[];
    warnings: string[];
  }> {
    try {
      const template = await this.getTemplateForReview(templateId);
      const issues: string[] = [];
      const warnings: string[] = [];

      // Check title length and content
      if (template.title.length < 5) {
        issues.push('Template title is too short (minimum 5 characters)');
      }
      if (template.title.length > 100) {
        issues.push('Template title is too long (maximum 100 characters)');
      }

      // Check description
      if (template.description.length < 20) {
        issues.push('Template description is too short (minimum 20 characters)');
      }
      if (template.description.length > 1000) {
        warnings.push('Template description is very long (over 1000 characters)');
      }

      // Check body content
      if (template.body.length < 50) {
        issues.push('Template body is too short (minimum 50 characters)');
      }

      // Check placeholders
      const placeholderKeys = Object.keys(template.placeholders);
      if (placeholderKeys.length === 0) {
        warnings.push('Template has no placeholders - consider if this is intentional');
      }

      // Validate placeholder definitions
      for (const [key, config] of Object.entries(template.placeholders)) {
        if (!config || typeof config !== 'object') {
          issues.push(`Invalid placeholder configuration for "${key}"`);
          continue;
        }

        const placeholderConfig = config as any;
        
        if (!placeholderConfig.type) {
          issues.push(`Placeholder "${key}" is missing type definition`);
        }

        if (!placeholderConfig.label) {
          issues.push(`Placeholder "${key}" is missing label`);
        }

        // Check if placeholder is used in body
        if (!template.body.includes(`{${key}}`)) {
          warnings.push(`Placeholder "${key}" is defined but not used in template body`);
        }
      }

      // Check for placeholders in body that aren't defined
      const bodyPlaceholders = template.body.match(/\{([^}]+)\}/g) || [];
      for (const placeholder of bodyPlaceholders) {
        const key = placeholder.slice(1, -1); // Remove { and }
        if (!template.placeholders[key]) {
          issues.push(`Placeholder "${key}" is used in body but not defined in placeholders`);
        }
      }

      // Check price
      if (template.price < 0) {
        issues.push('Template price cannot be negative');
      }
      if (template.price > 500) {
        issues.push('Template price exceeds maximum allowed (500 TL)');
      }
      if (template.price > 0 && template.price < 5) {
        issues.push('Paid templates must be at least 5 TL');
      }

      // Check category
      if (!template.categoryId) {
        issues.push('Template must have a category assigned');
      }

      return {
        isValid: issues.length === 0,
        issues,
        warnings,
      };
    } catch (error) {
      logger.error('Error validating template quality:', error);
      throw createError('Failed to validate template quality', 500);
    }
  }

  /**
   * Approve a template
   */
  async approveTemplate(
    templateId: string,
    adminId: string,
    isVerified: boolean = false,
    isFeatured: boolean = false
  ): Promise<void> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      // Get template info for notification
      const templateQuery = `
        SELECT title, created_by 
        FROM templates 
        WHERE id = $1 AND status = 'pending'
      `;
      const templateResult = await client.query(templateQuery, [templateId]);
      
      if (templateResult.rows.length === 0) {
        throw createError('Template not found or already processed', 404);
      }

      const template = templateResult.rows[0];

      // Update template status
      const updateQuery = `
        UPDATE templates 
        SET 
          status = 'published',
          is_verified = $2,
          is_featured = $3,
          updated_at = NOW()
        WHERE id = $1 AND status = 'pending'
      `;

      const result = await client.query(updateQuery, [templateId, isVerified, isFeatured]);

      if (result.rowCount === 0) {
        throw createError('Template not found or already processed', 404);
      }

      // Log admin action
      await client.query(
        `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
         VALUES ($1, 'approve_template', 'template', $2, $3)`,
        [
          adminId,
          templateId,
          JSON.stringify({ isVerified, isFeatured }),
        ]
      );

      await client.query('COMMIT');

      // Send notification to creator
      await this.notificationService.notifyTemplateApproved(
        template.created_by,
        templateId,
        template.title,
        isVerified,
        isFeatured
      );

      logger.info(`Template ${templateId} approved by admin ${adminId}`);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error approving template:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Reject a template
   */
  async rejectTemplate(
    templateId: string,
    adminId: string,
    reason: string
  ): Promise<void> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      // Get template info for notification
      const templateQuery = `
        SELECT title, created_by 
        FROM templates 
        WHERE id = $1 AND status = 'pending'
      `;
      const templateResult = await client.query(templateQuery, [templateId]);
      
      if (templateResult.rows.length === 0) {
        throw createError('Template not found or already processed', 404);
      }

      const template = templateResult.rows[0];

      // Update template status
      const updateQuery = `
        UPDATE templates 
        SET 
          status = 'rejected',
          rejection_reason = $2,
          updated_at = NOW()
        WHERE id = $1 AND status = 'pending'
      `;

      const result = await client.query(updateQuery, [templateId, reason]);

      if (result.rowCount === 0) {
        throw createError('Template not found or already processed', 404);
      }

      // Log admin action
      await client.query(
        `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
         VALUES ($1, 'reject_template', 'template', $2, $3)`,
        [
          adminId,
          templateId,
          JSON.stringify({ reason }),
        ]
      );

      await client.query('COMMIT');

      // Send notification to creator
      await this.notificationService.notifyTemplateRejected(
        template.created_by,
        templateId,
        template.title,
        reason
      );

      logger.info(`Template ${templateId} rejected by admin ${adminId}`);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error rejecting template:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get users with filtering and pagination
   */
  async getUsers(
    page: number = 1,
    limit: number = 20,
    filters: {
      role?: string;
      status?: string;
      search?: string;
    } = {}
  ): Promise<{
    users: AdminUser[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    try {
      const offset = (page - 1) * limit;
      let whereConditions = ['u.role != \'admin\''];
      const queryParams: any[] = [];
      let paramIndex = 1;

      // Add filters
      if (filters.role) {
        whereConditions.push(`u.role = $${paramIndex}`);
        queryParams.push(filters.role);
        paramIndex++;
      }

      if (filters.status) {
        if (filters.status === 'active') {
          whereConditions.push('u.is_active = true');
        } else if (filters.status === 'banned') {
          whereConditions.push('u.is_active = false');
        } else if (filters.status === 'pending') {
          whereConditions.push('u.is_verified = false');
        }
      }

      if (filters.search) {
        whereConditions.push(`(u.full_name ILIKE $${paramIndex} OR u.email ILIKE $${paramIndex})`);
        queryParams.push(`%${filters.search}%`);
        paramIndex++;
      }

      const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as total
        FROM users u
        ${whereClause}
      `;

      const countResult = await this.db.query(countQuery, queryParams);
      const total = parseInt(countResult.rows[0].total);

      // Get users with template count and earnings
      const usersQuery = `
        SELECT 
          u.id,
          u.email,
          u.full_name,
          u.role,
          u.is_verified,
          u.is_active,
          u.total_earnings,
          u.created_at,
          u.last_login,
          COALESCE(t.template_count, 0) as template_count
        FROM users u
        LEFT JOIN (
          SELECT created_by, COUNT(*) as template_count
          FROM templates
          WHERE status = 'published'
          GROUP BY created_by
        ) t ON u.id = t.created_by
        ${whereClause}
        ORDER BY u.created_at DESC
        LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
      `;

      queryParams.push(limit, offset);
      const usersResult = await this.db.query(usersQuery, queryParams);

      const users: AdminUser[] = usersResult.rows.map(row => ({
        id: row.id,
        email: row.email,
        fullName: row.full_name,
        role: row.role,
        isVerified: row.is_verified,
        isActive: row.is_active,
        templateCount: parseInt(row.template_count) || 0,
        totalEarnings: parseFloat(row.total_earnings) || 0,
        createdAt: row.created_at,
        lastLogin: row.last_login,
      }));

      return {
        users,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      logger.error('Error getting users:', error);
      throw createError('Failed to fetch users', 500);
    }
  }

  /**
   * Ban or unban a user
   */
  async banUser(
    userId: string,
    adminId: string,
    banned: boolean,
    reason?: string
  ): Promise<void> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      // Update user status
      const updateQuery = `
        UPDATE users 
        SET 
          is_active = $2,
          updated_at = NOW()
        WHERE id = $1 AND role != 'admin'
      `;

      const result = await client.query(updateQuery, [userId, !banned]);

      if (result.rowCount === 0) {
        throw createError('User not found or is an admin', 404);
      }

      // Log admin action
      await client.query(
        `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
         VALUES ($1, $2, 'user', $3, $4)`,
        [
          adminId,
          banned ? 'ban_user' : 'unban_user',
          userId,
          JSON.stringify({ reason }),
        ]
      );

      await client.query('COMMIT');
      logger.info(`User ${userId} ${banned ? 'banned' : 'unbanned'} by admin ${adminId}`);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error banning/unbanning user:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get payment statistics
   */
  async getPaymentStats(
    startDate?: string,
    endDate?: string,
    groupBy: 'day' | 'week' | 'month' = 'day'
  ): Promise<{
    payments: PaymentStats;
    breakdown: PaymentBreakdown[];
  }> {
    try {
      let dateFilter = '';
      const queryParams: any[] = [];
      let paramIndex = 1;

      if (startDate && endDate) {
        dateFilter = `WHERE purchased_at >= $${paramIndex} AND purchased_at <= $${paramIndex + 1}`;
        queryParams.push(startDate, endDate);
        paramIndex += 2;
      }

      // Get overall payment statistics
      const statsQuery = `
        SELECT 
          COALESCE(SUM(amount), 0) as total_revenue,
          COUNT(*) as total_transactions,
          COALESCE(AVG(amount), 0) as average_transaction_value,
          COALESCE(SUM(amount * 0.2), 0) as platform_commission,
          COALESCE(SUM(amount * 0.8), 0) as creator_payouts
        FROM purchases 
        ${dateFilter} AND status = 'completed'
      `;

      const statsResult = await this.db.query(statsQuery, queryParams);
      const stats = statsResult.rows[0];

      // Get pending payouts
      const pendingPayoutsQuery = `
        SELECT COALESCE(SUM(amount), 0) as pending_payouts
        FROM payouts 
        WHERE status IN ('pending', 'processing')
      `;

      const pendingResult = await this.db.query(pendingPayoutsQuery);

      // Get breakdown by time period
      let dateGrouping = 'DATE(purchased_at)';
      if (groupBy === 'week') {
        dateGrouping = 'DATE_TRUNC(\'week\', purchased_at)';
      } else if (groupBy === 'month') {
        dateGrouping = 'DATE_TRUNC(\'month\', purchased_at)';
      }

      const breakdownQuery = `
        SELECT 
          ${dateGrouping} as date,
          COALESCE(SUM(amount), 0) as revenue,
          COUNT(*) as transactions,
          COALESCE(SUM(amount * 0.2), 0) as commission
        FROM purchases 
        ${dateFilter} AND status = 'completed'
        GROUP BY ${dateGrouping}
        ORDER BY date
      `;

      const breakdownResult = await this.db.query(breakdownQuery, queryParams);

      return {
        payments: {
          totalRevenue: parseFloat(stats.total_revenue) || 0,
          totalTransactions: parseInt(stats.total_transactions) || 0,
          averageTransactionValue: parseFloat(stats.average_transaction_value) || 0,
          platformCommission: parseFloat(stats.platform_commission) || 0,
          creatorPayouts: parseFloat(stats.creator_payouts) || 0,
          pendingPayouts: parseFloat(pendingResult.rows[0].pending_payouts) || 0,
        },
        breakdown: breakdownResult.rows.map(row => ({
          date: row.date,
          revenue: parseFloat(row.revenue),
          transactions: parseInt(row.transactions),
          commission: parseFloat(row.commission),
        })),
      };
    } catch (error) {
      logger.error('Error getting payment statistics:', error);
      throw createError('Failed to fetch payment statistics', 500);
    }
  }

  /**
   * Get all categories with admin details
   */
  async getCategories(): Promise<AdminCategory[]> {
    try {
      const query = `
        SELECT 
          c.id,
          c.name,
          c.slug,
          c.parent_id,
          p.name as parent_name,
          c.description,
          c.icon,
          c.order_index,
          c.is_active,
          c.template_count,
          c.created_at,
          c.updated_at
        FROM categories c
        LEFT JOIN categories p ON c.parent_id = p.id
        ORDER BY c.order_index, c.name
      `;

      const result = await this.db.query(query);

      return result.rows.map(row => ({
        id: row.id,
        name: row.name,
        slug: row.slug,
        parentId: row.parent_id,
        parentName: row.parent_name,
        description: row.description,
        icon: row.icon,
        orderIndex: row.order_index || 0,
        isActive: row.is_active,
        templateCount: row.template_count || 0,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      }));
    } catch (error) {
      logger.error('Error getting categories:', error);
      throw createError('Failed to fetch categories', 500);
    }
  }

  /**
   * Create a new category
   */
  async createCategory(
    adminId: string,
    data: {
      name: string;
      description?: string;
      parentId?: string;
      icon?: string;
    }
  ): Promise<AdminCategory> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      // Generate slug from name
      const slug = data.name.toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim('-');

      // Check if slug already exists
      const slugCheck = await client.query(
        'SELECT id FROM categories WHERE slug = $1',
        [slug]
      );

      if (slugCheck.rows.length > 0) {
        throw createError('Category with this name already exists', 400);
      }

      // Get next order index
      const orderQuery = await client.query(
        'SELECT COALESCE(MAX(order_index), 0) + 1 as next_order FROM categories WHERE parent_id = $1',
        [data.parentId || null]
      );
      const orderIndex = orderQuery.rows[0].next_order;

      // Insert category
      const insertQuery = `
        INSERT INTO categories (name, slug, parent_id, description, icon, order_index)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `;

      const result = await client.query(insertQuery, [
        data.name,
        slug,
        data.parentId || null,
        data.description || null,
        data.icon || null,
        orderIndex,
      ]);

      const category = result.rows[0];

      // Log admin action
      await client.query(
        `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
         VALUES ($1, 'create_category', 'category', $2, $3)`,
        [
          adminId,
          category.id,
          JSON.stringify(data),
        ]
      );

      await client.query('COMMIT');

      // Get parent name if exists
      let parentName = null;
      if (category.parent_id) {
        const parentQuery = await this.db.query(
          'SELECT name FROM categories WHERE id = $1',
          [category.parent_id]
        );
        parentName = parentQuery.rows[0]?.name || null;
      }

      return {
        id: category.id,
        name: category.name,
        slug: category.slug,
        parentId: category.parent_id,
        parentName,
        description: category.description,
        icon: category.icon,
        orderIndex: category.order_index,
        isActive: category.is_active,
        templateCount: 0,
        createdAt: category.created_at,
        updatedAt: category.updated_at,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error creating category:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Update a category
   */
  async updateCategory(
    categoryId: string,
    adminId: string,
    data: {
      name?: string;
      description?: string;
      parentId?: string;
      icon?: string;
      orderIndex?: number;
      isActive?: boolean;
    }
  ): Promise<void> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      const updateFields: string[] = [];
      const updateValues: any[] = [];
      let paramIndex = 1;

      if (data.name !== undefined) {
        const slug = data.name.toLowerCase()
          .replace(/[^a-z0-9\s-]/g, '')
          .replace(/\s+/g, '-')
          .replace(/-+/g, '-')
          .trim('-');

        // Check if slug already exists (excluding current category)
        const slugCheck = await client.query(
          'SELECT id FROM categories WHERE slug = $1 AND id != $2',
          [slug, categoryId]
        );

        if (slugCheck.rows.length > 0) {
          throw createError('Category with this name already exists', 400);
        }

        updateFields.push(`name = $${paramIndex}`, `slug = $${paramIndex + 1}`);
        updateValues.push(data.name, slug);
        paramIndex += 2;
      }

      if (data.description !== undefined) {
        updateFields.push(`description = $${paramIndex}`);
        updateValues.push(data.description);
        paramIndex++;
      }

      if (data.parentId !== undefined) {
        updateFields.push(`parent_id = $${paramIndex}`);
        updateValues.push(data.parentId || null);
        paramIndex++;
      }

      if (data.icon !== undefined) {
        updateFields.push(`icon = $${paramIndex}`);
        updateValues.push(data.icon);
        paramIndex++;
      }

      if (data.orderIndex !== undefined) {
        updateFields.push(`order_index = $${paramIndex}`);
        updateValues.push(data.orderIndex);
        paramIndex++;
      }

      if (data.isActive !== undefined) {
        updateFields.push(`is_active = $${paramIndex}`);
        updateValues.push(data.isActive);
        paramIndex++;
      }

      if (updateFields.length === 0) {
        throw createError('No fields to update', 400);
      }

      updateFields.push('updated_at = NOW()');
      updateValues.push(categoryId);

      const updateQuery = `
        UPDATE categories 
        SET ${updateFields.join(', ')}
        WHERE id = $${paramIndex}
      `;

      const result = await client.query(updateQuery, updateValues);

      if (result.rowCount === 0) {
        throw createError('Category not found', 404);
      }

      // Log admin action
      await client.query(
        `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
         VALUES ($1, 'update_category', 'category', $2, $3)`,
        [
          adminId,
          categoryId,
          JSON.stringify(data),
        ]
      );

      await client.query('COMMIT');
      logger.info(`Category ${categoryId} updated by admin ${adminId}`);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error updating category:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Delete a category
   */
  async deleteCategory(categoryId: string, adminId: string): Promise<void> {
    const client = await this.db.connect();
    
    try {
      await client.query('BEGIN');

      // Check if category has templates
      const templateCheck = await client.query(
        'SELECT COUNT(*) as count FROM templates WHERE category_id = $1',
        [categoryId]
      );

      if (parseInt(templateCheck.rows[0].count) > 0) {
        throw createError('Cannot delete category with existing templates', 400);
      }

      // Check if category has subcategories
      const subcategoryCheck = await client.query(
        'SELECT COUNT(*) as count FROM categories WHERE parent_id = $1',
        [categoryId]
      );

      if (parseInt(subcategoryCheck.rows[0].count) > 0) {
        throw createError('Cannot delete category with subcategories', 400);
      }

      // Delete category
      const deleteQuery = 'DELETE FROM categories WHERE id = $1';
      const result = await client.query(deleteQuery, [categoryId]);

      if (result.rowCount === 0) {
        throw createError('Category not found', 404);
      }

      // Log admin action
      await client.query(
        `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
         VALUES ($1, 'delete_category', 'category', $2, $3)`,
        [
          adminId,
          categoryId,
          JSON.stringify({}),
        ]
      );

      await client.query('COMMIT');
      logger.info(`Category ${categoryId} deleted by admin ${adminId}`);
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error deleting category:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Bulk ban/unban users
   */
  async bulkBanUsers(
    userIds: string[],
    adminId: string,
    banned: boolean,
    reason?: string
  ): Promise<{ success: number; failed: number; errors: string[] }> {
    const client = await this.db.connect();
    let success = 0;
    let failed = 0;
    const errors: string[] = [];
    
    try {
      await client.query('BEGIN');

      for (const userId of userIds) {
        try {
          // Update user status
          const updateQuery = `
            UPDATE users 
            SET 
              is_active = $2,
              updated_at = NOW()
            WHERE id = $1 AND role != 'admin'
          `;

          const result = await client.query(updateQuery, [userId, !banned]);

          if (result.rowCount === 0) {
            errors.push(`User ${userId} not found or is an admin`);
            failed++;
            continue;
          }

          // Log admin action
          await client.query(
            `INSERT INTO admin_actions (admin_id, action_type, target_type, target_id, details)
             VALUES ($1, $2, 'user', $3, $4)`,
            [
              adminId,
              banned ? 'bulk_ban_user' : 'bulk_unban_user',
              userId,
              JSON.stringify({ reason, bulkOperation: true }),
            ]
          );

          success++;
        } catch (error) {
          errors.push(`Failed to ${banned ? 'ban' : 'unban'} user ${userId}: ${error}`);
          failed++;
        }
      }

      await client.query('COMMIT');
      logger.info(`Bulk ${banned ? 'ban' : 'unban'} operation completed by admin ${adminId}: ${success} success, ${failed} failed`);

      return { success, failed, errors };
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('Error in bulk ban operation:', error);
      throw createError('Failed to perform bulk ban operation', 500);
    } finally {
      client.release();
    }
  }

  /**
   * Get user activity monitoring data
   */
  async getUserActivityMonitoring(
    userId?: string,
    startDate?: string,
    endDate?: string,
    limit: number = 100
  ): Promise<{
    activities: Array<{
      id: string;
      userId: string;
      userName: string;
      activityType: string;
      details: Record<string, any>;
      timestamp: string;
    }>;
    summary: {
      totalActivities: number;
      uniqueUsers: number;
      activityTypes: Record<string, number>;
    };
  }> {
    try {
      let whereConditions = ['1=1'];
      const queryParams: any[] = [];
      let paramIndex = 1;

      if (userId) {
        whereConditions.push(`aa.admin_id = $${paramIndex} OR aa.target_id = $${paramIndex}`);
        queryParams.push(userId);
        paramIndex++;
      }

      if (startDate) {
        whereConditions.push(`aa.created_at >= $${paramIndex}`);
        queryParams.push(startDate);
        paramIndex++;
      }

      if (endDate) {
        whereConditions.push(`aa.created_at <= $${paramIndex}`);
        queryParams.push(endDate);
        paramIndex++;
      }

      const whereClause = whereConditions.join(' AND ');

      // Get activities
      const activitiesQuery = `
        SELECT 
          aa.id,
          aa.admin_id as user_id,
          u.full_name as user_name,
          aa.action_type as activity_type,
          aa.details,
          aa.created_at as timestamp
        FROM admin_actions aa
        LEFT JOIN users u ON aa.admin_id = u.id
        WHERE ${whereClause}
        ORDER BY aa.created_at DESC
        LIMIT $${paramIndex}
      `;

      queryParams.push(limit);
      const activitiesResult = await this.db.query(activitiesQuery, queryParams);

      // Get summary statistics
      const summaryQuery = `
        SELECT 
          COUNT(*) as total_activities,
          COUNT(DISTINCT aa.admin_id) as unique_users,
          aa.action_type,
          COUNT(*) as type_count
        FROM admin_actions aa
        WHERE ${whereClause}
        GROUP BY aa.action_type
      `;

      const summaryResult = await this.db.query(summaryQuery, queryParams.slice(0, -1)); // Remove limit param

      const activities = activitiesResult.rows.map(row => ({
        id: row.id,
        userId: row.user_id,
        userName: row.user_name || 'Unknown User',
        activityType: row.activity_type,
        details: row.details || {},
        timestamp: row.timestamp,
      }));

      const activityTypes: Record<string, number> = {};
      let totalActivities = 0;
      let uniqueUsers = 0;

      for (const row of summaryResult.rows) {
        activityTypes[row.action_type] = parseInt(row.type_count);
        totalActivities += parseInt(row.type_count);
        if (uniqueUsers === 0) {
          uniqueUsers = parseInt(row.unique_users);
        }
      }

      return {
        activities,
        summary: {
          totalActivities,
          uniqueUsers,
          activityTypes,
        },
      };
    } catch (error) {
      logger.error('Error getting user activity monitoring:', error);
      throw createError('Failed to fetch user activity data', 500);
    }
  }

  /**
   * Get system health metrics
   */
  async getSystemHealthMetrics(): Promise<{
    database: {
      status: 'healthy' | 'degraded' | 'unhealthy';
      connectionCount: number;
      avgResponseTime: number;
    };
    storage: {
      totalTemplates: number;
      totalUsers: number;
      totalDocuments: number;
      storageUsed: number; // in MB
    };
    performance: {
      avgTemplateProcessingTime: number;
      avgPdfGenerationTime: number;
      errorRate: number;
    };
  }> {
    try {
      // Database health check
      const dbStartTime = Date.now();
      await this.db.query('SELECT 1');
      const dbResponseTime = Date.now() - dbStartTime;

      // Get connection count (approximate)
      const connectionQuery = `
        SELECT count(*) as connection_count 
        FROM pg_stat_activity 
        WHERE state = 'active'
      `;
      const connectionResult = await this.db.query(connectionQuery);
      const connectionCount = parseInt(connectionResult.rows[0].connection_count) || 0;

      // Storage metrics
      const storageQuery = `
        SELECT 
          (SELECT COUNT(*) FROM templates) as total_templates,
          (SELECT COUNT(*) FROM users) as total_users,
          (SELECT COUNT(*) FROM documents) as total_documents
      `;
      const storageResult = await this.db.query(storageQuery);
      const storage = storageResult.rows[0];

      // Determine database status
      let dbStatus: 'healthy' | 'degraded' | 'unhealthy' = 'healthy';
      if (dbResponseTime > 1000) {
        dbStatus = 'unhealthy';
      } else if (dbResponseTime > 500) {
        dbStatus = 'degraded';
      }

      return {
        database: {
          status: dbStatus,
          connectionCount,
          avgResponseTime: dbResponseTime,
        },
        storage: {
          totalTemplates: parseInt(storage.total_templates) || 0,
          totalUsers: parseInt(storage.total_users) || 0,
          totalDocuments: parseInt(storage.total_documents) || 0,
          storageUsed: 0, // Would need file system integration to calculate actual storage
        },
        performance: {
          avgTemplateProcessingTime: 150, // Mock data - would need actual metrics
          avgPdfGenerationTime: 800, // Mock data - would need actual metrics
          errorRate: 0.02, // Mock data - would need error tracking
        },
      };
    } catch (error) {
      logger.error('Error getting system health metrics:', error);
      throw createError('Failed to fetch system health metrics', 500);
    }
  }
}