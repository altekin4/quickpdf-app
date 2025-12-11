import { Pool } from 'pg';

export interface Purchase {
  id: string;
  userId: string;
  templateId: string;
  amount: number;
  currency: string;
  paymentMethod: string;
  paymentGateway: string;
  transactionId: string;
  gatewayTransactionId?: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  purchasedAt: Date;
  completedAt?: Date;
  refundedAt?: Date;
}

export interface CreatePurchaseData {
  userId: string;
  templateId: string;
  amount: number;
  currency?: string;
  paymentMethod: string;
  paymentGateway: string;
  transactionId: string;
  gatewayTransactionId?: string;
}

export class PurchaseModel {
  constructor(private db: Pool) {}

  async create(data: CreatePurchaseData): Promise<Purchase> {
    const query = `
      INSERT INTO purchases (
        user_id, template_id, amount, currency, payment_method, 
        payment_gateway, transaction_id, gateway_transaction_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `;
    
    const values = [
      data.userId,
      data.templateId,
      data.amount,
      data.currency || 'TRY',
      data.paymentMethod,
      data.paymentGateway,
      data.transactionId,
      data.gatewayTransactionId
    ];

    const result = await this.db.query(query, values);
    return this.mapRowToPurchase(result.rows[0]);
  }

  async findById(id: string): Promise<Purchase | null> {
    const query = 'SELECT * FROM purchases WHERE id = $1';
    const result = await this.db.query(query, [id]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapRowToPurchase(result.rows[0]);
  }

  async findByTransactionId(transactionId: string): Promise<Purchase | null> {
    const query = 'SELECT * FROM purchases WHERE transaction_id = $1';
    const result = await this.db.query(query, [transactionId]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapRowToPurchase(result.rows[0]);
  }

  async findByUserId(userId: string, limit: number = 50, offset: number = 0): Promise<Purchase[]> {
    const query = `
      SELECT p.*, t.title as template_title, t.description as template_description
      FROM purchases p
      LEFT JOIN templates t ON p.template_id = t.id
      WHERE p.user_id = $1
      ORDER BY p.purchased_at DESC
      LIMIT $2 OFFSET $3
    `;
    
    const result = await this.db.query(query, [userId, limit, offset]);
    return result.rows.map(row => this.mapRowToPurchase(row));
  }

  async updateStatus(id: string, status: Purchase['status'], gatewayTransactionId?: string): Promise<Purchase | null> {
    const completedAt = status === 'completed' ? 'NOW()' : 'completed_at';
    const refundedAt = status === 'refunded' ? 'NOW()' : 'refunded_at';
    
    const query = `
      UPDATE purchases 
      SET status = $1, 
          gateway_transaction_id = COALESCE($2, gateway_transaction_id),
          completed_at = CASE WHEN $1 = 'completed' THEN NOW() ELSE ${completedAt} END,
          refunded_at = CASE WHEN $1 = 'refunded' THEN NOW() ELSE ${refundedAt} END
      WHERE id = $3
      RETURNING *
    `;
    
    const result = await this.db.query(query, [status, gatewayTransactionId, id]);
    
    if (result.rows.length === 0) {
      return null;
    }
    
    return this.mapRowToPurchase(result.rows[0]);
  }

  async hasUserPurchased(userId: string, templateId: string): Promise<boolean> {
    const query = `
      SELECT 1 FROM purchases 
      WHERE user_id = $1 AND template_id = $2 AND status = 'completed'
      LIMIT 1
    `;
    
    const result = await this.db.query(query, [userId, templateId]);
    return result.rows.length > 0;
  }

  private mapRowToPurchase(row: any): Purchase {
    return {
      id: row.id,
      userId: row.user_id,
      templateId: row.template_id,
      amount: parseFloat(row.amount),
      currency: row.currency,
      paymentMethod: row.payment_method,
      paymentGateway: row.payment_gateway,
      transactionId: row.transaction_id,
      gatewayTransactionId: row.gateway_transaction_id,
      status: row.status,
      purchasedAt: row.purchased_at,
      completedAt: row.completed_at,
      refundedAt: row.refunded_at
    };
  }
}