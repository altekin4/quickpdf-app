import { pool } from '@/config/database';
import { logger } from '@/utils/logger';

export interface RefreshToken {
  id: string;
  user_id: string;
  token: string;
  expires_at: Date;
  created_at: Date;
  revoked_at?: Date;
}

export interface CreateRefreshTokenData {
  user_id: string;
  token: string;
  expires_at: Date;
}

export class RefreshTokenModel {
  static async create(tokenData: CreateRefreshTokenData): Promise<RefreshToken> {
    const query = `
      INSERT INTO refresh_tokens (user_id, token, expires_at)
      VALUES ($1, $2, $3)
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [
        tokenData.user_id,
        tokenData.token,
        tokenData.expires_at
      ]);
      
      return result.rows[0];
    } catch (error) {
      logger.error('Error creating refresh token:', error);
      throw error;
    }
  }

  static async findByToken(token: string): Promise<RefreshToken | null> {
    const query = 'SELECT * FROM refresh_tokens WHERE token = $1';
    
    try {
      const result = await pool.query(query, [token]);
      return result.rows[0] || null;
    } catch (error) {
      logger.error('Error finding refresh token:', error);
      throw error;
    }
  }

  static async findByUserId(userId: string): Promise<RefreshToken[]> {
    const query = `
      SELECT * FROM refresh_tokens 
      WHERE user_id = $1 AND revoked_at IS NULL 
      ORDER BY created_at DESC
    `;
    
    try {
      const result = await pool.query(query, [userId]);
      return result.rows;
    } catch (error) {
      logger.error('Error finding refresh tokens by user ID:', error);
      throw error;
    }
  }

  static async revoke(token: string): Promise<boolean> {
    const query = `
      UPDATE refresh_tokens 
      SET revoked_at = NOW()
      WHERE token = $1 AND revoked_at IS NULL
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [token]);
      return (result.rowCount ?? 0) > 0;
    } catch (error) {
      logger.error('Error revoking refresh token:', error);
      throw error;
    }
  }

  static async revokeAllForUser(userId: string): Promise<number> {
    const query = `
      UPDATE refresh_tokens 
      SET revoked_at = NOW()
      WHERE user_id = $1 AND revoked_at IS NULL
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [userId]);
      return result.rowCount ?? 0;
    } catch (error) {
      logger.error('Error revoking all refresh tokens for user:', error);
      throw error;
    }
  }

  static async cleanupExpired(): Promise<number> {
    const query = `
      DELETE FROM refresh_tokens 
      WHERE expires_at < NOW() OR revoked_at < NOW() - INTERVAL '30 days'
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query);
      const count = result.rowCount ?? 0;
      logger.info(`Cleaned up ${count} expired refresh tokens`);
      return count;
    } catch (error) {
      logger.error('Error cleaning up expired refresh tokens:', error);
      throw error;
    }
  }

  static async isTokenValid(token: string): Promise<boolean> {
    const query = `
      SELECT 1 FROM refresh_tokens 
      WHERE token = $1 
        AND expires_at > NOW() 
        AND revoked_at IS NULL
    `;
    
    try {
      const result = await pool.query(query, [token]);
      return (result.rowCount ?? 0) > 0;
    } catch (error) {
      logger.error('Error checking token validity:', error);
      throw error;
    }
  }

  static async getUserTokenCount(userId: string): Promise<number> {
    const query = `
      SELECT COUNT(*) as count 
      FROM refresh_tokens 
      WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW()
    `;
    
    try {
      const result = await pool.query(query, [userId]);
      return parseInt(result.rows[0].count);
    } catch (error) {
      logger.error('Error getting user token count:', error);
      throw error;
    }
  }
}