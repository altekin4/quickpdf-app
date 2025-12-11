import { pool } from '@/config/database';
import { logger } from '@/utils/logger';

export interface User {
  id: string;
  email: string;
  password_hash: string;
  full_name: string;
  phone?: string;
  role: 'user' | 'creator' | 'admin';
  is_verified: boolean;
  is_active: boolean;
  balance: number;
  total_earnings: number;
  profile_picture_url?: string;
  email_verification_token?: string;
  password_reset_token?: string;
  password_reset_expires?: Date;
  created_at: Date;
  updated_at: Date;
  last_login?: Date;
}

export interface CreateUserData {
  email: string;
  password_hash: string;
  full_name: string;
  phone?: string;
  role?: 'user' | 'creator' | 'admin';
}

export interface UpdateUserData {
  full_name?: string;
  phone?: string;
  profile_picture_url?: string;
  is_verified?: boolean;
  is_active?: boolean;
  balance?: number;
  total_earnings?: number;
  last_login?: Date;
  password_hash?: string;
  email_verification_token?: string | null;
  password_reset_token?: string | null;
  password_reset_expires?: Date | null;
}

export class UserModel {
  static async create(userData: CreateUserData): Promise<User> {
    const query = `
      INSERT INTO users (email, password_hash, full_name, phone, role)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [
        userData.email,
        userData.password_hash,
        userData.full_name,
        userData.phone,
        userData.role || 'user'
      ]);
      
      return result.rows[0];
    } catch (error) {
      logger.error('Error creating user:', error);
      throw error;
    }
  }

  static async findById(id: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE id = $1';
    
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error finding user by ID:', error);
      throw error;
    }
  }

  static async findByEmail(email: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE email = $1';
    
    try {
      const result = await pool.query(query, [email]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error finding user by email:', error);
      throw error;
    }
  }

  static async update(id: string, updateData: UpdateUserData): Promise<User | null> {
    const fields = Object.keys(updateData);
    const values = Object.values(updateData);
    
    if (fields.length === 0) {
      throw new Error('No fields to update');
    }
    
    const setClause = fields.map((field, index) => `${field} = $${index + 2}`).join(', ');
    const query = `
      UPDATE users 
      SET ${setClause}, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [id, ...values]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error updating user:', error);
      throw error;
    }
  }

  static async delete(id: string): Promise<boolean> {
    const query = 'DELETE FROM users WHERE id = $1';
    
    try {
      const result = await pool.query(query, [id]);
      return (result.rowCount ?? 0) > 0;
    } catch (error) {
      logger.error('Error deleting user:', error);
      throw error;
    }
  }

  static async findAll(
    page: number = 1,
    limit: number = 20,
    filters: {
      role?: string;
      is_active?: boolean;
      search?: string;
    } = {}
  ): Promise<{ users: User[]; total: number }> {
    let whereClause = 'WHERE 1=1';
    const queryParams: any[] = [];
    let paramIndex = 1;

    if (filters.role) {
      whereClause += ` AND role = $${paramIndex}`;
      queryParams.push(filters.role);
      paramIndex++;
    }

    if (filters.is_active !== undefined) {
      whereClause += ` AND is_active = $${paramIndex}`;
      queryParams.push(filters.is_active);
      paramIndex++;
    }

    if (filters.search) {
      whereClause += ` AND (full_name ILIKE $${paramIndex} OR email ILIKE $${paramIndex})`;
      queryParams.push(`%${filters.search}%`);
      paramIndex++;
    }

    const offset = (page - 1) * limit;
    
    const countQuery = `SELECT COUNT(*) FROM users ${whereClause}`;
    const dataQuery = `
      SELECT * FROM users 
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `;

    try {
      const [countResult, dataResult] = await Promise.all([
        pool.query(countQuery, queryParams),
        pool.query(dataQuery, [...queryParams, limit, offset])
      ]);

      return {
        users: dataResult.rows,
        total: parseInt(countResult.rows[0].count)
      };
    } catch (error) {
      logger.error('Error finding users:', error);
      throw error;
    }
  }

  static async updateBalance(id: string, amount: number): Promise<User | null> {
    const query = `
      UPDATE users 
      SET balance = balance + $2, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [id, amount]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error updating user balance:', error);
      throw error;
    }
  }

  static async updateEarnings(id: string, amount: number): Promise<User | null> {
    const query = `
      UPDATE users 
      SET total_earnings = total_earnings + $2, balance = balance + $2, updated_at = NOW()
      WHERE id = $1
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [id, amount]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error updating user earnings:', error);
      throw error;
    }
  }

  static async findByResetToken(token: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE password_reset_token = $1';
    
    try {
      const result = await pool.query(query, [token]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error finding user by reset token:', error);
      throw error;
    }
  }

  static async findByVerificationToken(token: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE email_verification_token = $1';
    
    try {
      const result = await pool.query(query, [token]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error finding user by verification token:', error);
      throw error;
    }
  }

  static async getUserStats(id: string): Promise<{
    totalDocuments: number;
    totalTemplates: number;
    totalPurchases: number;
    documentsThisMonth: number;
    templatesThisMonth: number;
  }> {
    const query = `
      SELECT 
        (SELECT COUNT(*) FROM documents WHERE user_id = $1) as total_documents,
        (SELECT COUNT(*) FROM templates WHERE created_by = $1) as total_templates,
        (SELECT COUNT(*) FROM purchases WHERE user_id = $1 AND status = 'completed') as total_purchases,
        (SELECT COUNT(*) FROM documents WHERE user_id = $1 AND created_at >= date_trunc('month', CURRENT_DATE)) as documents_this_month,
        (SELECT COUNT(*) FROM templates WHERE created_by = $1 AND created_at >= date_trunc('month', CURRENT_DATE)) as templates_this_month
    `;
    
    try {
      const result = await pool.query(query, [id]);
      const row = result.rows[0];
      
      return {
        totalDocuments: parseInt(row.total_documents),
        totalTemplates: parseInt(row.total_templates),
        totalPurchases: parseInt(row.total_purchases),
        documentsThisMonth: parseInt(row.documents_this_month),
        templatesThisMonth: parseInt(row.templates_this_month)
      };
    } catch (error) {
      logger.error('Error getting user stats:', error);
      throw error;
    }
  }
}