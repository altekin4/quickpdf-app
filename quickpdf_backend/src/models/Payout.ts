import { Pool } from 'pg';

export interface Payout {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  paymentMethod?: string;
  paymentDetails?: Record<string, any>;
  requestedAt: Date;
  processedAt?: Date;
  completedAt?: Date;
}

export interface CreatePayoutData {
  userId: string;
  amount: number;
  currency?: string;
  paymentMethod?: string;
  paymentDetails?: Record<string, any>;
}

export class PayoutModel {
  constructor(private db: Pool) {}

  async create(data: CreatePayoutData): Promise<Payout> {
    const query = `
      INSERT INTO payouts (user_id, amount, currency, payment_method, payment_details)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    const values = [
      data.userId,
      data.amount,
      data.currency || 'TRY',
      data.paymentMethod,
      data.paymentDetails ? JSON.stringify(data.paymentDetails) : null
    ];

    const result = await this.db.query(query, values);
    return this.mapRowToPayout(result.rows[0]);
  }

  async findById(id: string): Promise<Payout | null> {
    const query = 'SELECT * FROM payouts WHERE id = $1';
    const result = await this.db.query(query, [id]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapRowToPayout(result.rows[0]);
  }

  async findByUserId(userId: string, limit: number = 50, offset: number = 0): Promise<Payout[]> {
    const query = `
      SELECT * FROM payouts 
      WHERE user_id = $1
      ORDER BY requested_at DESC
      LIMIT $2 OFFSET $3
    `;
    
    const result = await this.db.query(query, [userId, limit, offset]);
    return result.rows.map(row => this.mapRowToPayout(row));
  }

  async updateStatus(id: string, status: Payout['status']): Promise<Payout | null> {
    const processedAt = ['processing', 'completed', 'failed'].includes(status) ? 'NOW()' : 'processed_at';
    const completedAt = status === 'completed' ? 'NOW()' : 'completed_at';
    
    const query = `
      UPDATE payouts 
      SET status = $1,
          processed_at = CASE WHEN $1 IN ('processing', 'completed', 'failed') THEN NOW() ELSE ${processedAt} END,
          completed_at = CASE WHEN $1 = 'completed' THEN NOW() ELSE ${completedAt} END
      WHERE id = $2
      RETURNING *
    `;
    
    const result = await this.db.query(query, [status, id]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapRowToPayout(result.rows[0]);
  }

  async getPendingPayouts(): Promise<Payout[]> {
    const query = `
      SELECT * FROM payouts 
      WHERE status = 'pending'
      ORDER BY requested_at ASC
    `;
    
    const result = await this.db.query(query);
    return result.rows.map(row => this.mapRowToPayout(row));
  }

  async getUserEarningsBalance(userId: string): Promise<number> {
    const query = `
      SELECT COALESCE(balance, 0) as balance
      FROM users 
      WHERE id = $1
    `;
    
    const result = await this.db.query(query, [userId]);
    return result.rows.length > 0 ? parseFloat(result.rows[0].balance) : 0;
  }

  private mapRowToPayout(row: any): Payout {
    return {
      id: row.id,
      userId: row.user_id,
      amount: parseFloat(row.amount),
      currency: row.currency,
      status: row.status,
      paymentMethod: row.payment_method,
      paymentDetails: row.payment_details ? JSON.parse(row.payment_details) : undefined,
      requestedAt: row.requested_at,
      processedAt: row.processed_at,
      completedAt: row.completed_at
    };
  }
}