import { Pool } from 'pg';
import { logger } from '@/utils/logger';
import { createError } from '@/middleware/errorHandler';

interface NotificationData {
  userId: string;
  type: 'template_approved' | 'template_rejected' | 'payout_processed' | 'system_announcement';
  title: string;
  message: string;
  data?: Record<string, any>;
}

export class NotificationService {
  constructor(private db: Pool) {}

  /**
   * Send notification to user
   */
  async sendNotification(notification: NotificationData): Promise<void> {
    try {
      const query = `
        INSERT INTO notifications (user_id, type, title, message, data)
        VALUES ($1, $2, $3, $4, $5)
      `;

      await this.db.query(query, [
        notification.userId,
        notification.type,
        notification.title,
        notification.message,
        JSON.stringify(notification.data || {}),
      ]);

      logger.info(`Notification sent to user ${notification.userId}: ${notification.type}`);
    } catch (error) {
      logger.error('Error sending notification:', error);
      // Don't throw error for notifications to avoid breaking main flow
    }
  }

  /**
   * Notify creator about template approval
   */
  async notifyTemplateApproved(
    creatorId: string,
    templateId: string,
    templateTitle: string,
    isVerified: boolean,
    isFeatured: boolean
  ): Promise<void> {
    let message = `Your template "${templateTitle}" has been approved and is now live in the marketplace.`;
    
    if (isVerified) {
      message += ' It has been marked as verified.';
    }
    
    if (isFeatured) {
      message += ' It has been featured on the homepage.';
    }

    await this.sendNotification({
      userId: creatorId,
      type: 'template_approved',
      title: 'Template Approved',
      message,
      data: {
        templateId,
        templateTitle,
        isVerified,
        isFeatured,
      },
    });
  }

  /**
   * Notify creator about template rejection
   */
  async notifyTemplateRejected(
    creatorId: string,
    templateId: string,
    templateTitle: string,
    reason: string
  ): Promise<void> {
    const message = `Your template "${templateTitle}" has been rejected. Reason: ${reason}. You can edit and resubmit your template.`;

    await this.sendNotification({
      userId: creatorId,
      type: 'template_rejected',
      title: 'Template Rejected',
      message,
      data: {
        templateId,
        templateTitle,
        reason,
      },
    });
  }

  /**
   * Notify user about payout processing
   */
  async notifyPayoutProcessed(
    userId: string,
    payoutId: string,
    amount: number,
    status: 'completed' | 'failed'
  ): Promise<void> {
    const title = status === 'completed' ? 'Payout Completed' : 'Payout Failed';
    const message = status === 'completed' 
      ? `Your payout of ${amount} TL has been processed successfully.`
      : `Your payout of ${amount} TL could not be processed. Please check your payment details.`;

    await this.sendNotification({
      userId,
      type: 'payout_processed',
      title,
      message,
      data: {
        payoutId,
        amount,
        status,
      },
    });
  }
}