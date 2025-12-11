import Stripe from 'stripe';
import { Pool } from 'pg';
import { PurchaseModel, CreatePurchaseData } from '../models/Purchase';
import { PayoutModel } from '../models/Payout';
import { TemplateModel } from '../models/Template';
import { UserModel } from '../models/User';
import { logger } from '../utils/logger';

export interface PaymentIntent {
  id: string;
  clientSecret: string;
  amount: number;
  currency: string;
  status: string;
}

export interface PaymentResult {
  success: boolean;
  purchaseId?: string;
  error?: string;
  paymentIntent?: PaymentIntent;
}

export interface CreatePaymentIntentData {
  templateId: string;
  userId: string;
  paymentMethodId?: string;
}

export class PaymentService {
  private stripe: Stripe;
  private purchaseModel: PurchaseModel;
  private payoutModel: PayoutModel;

  constructor(private db: Pool) {
    if (!process.env.STRIPE_SECRET_KEY) {
      throw new Error('STRIPE_SECRET_KEY environment variable is required');
    }

    this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
      apiVersion: '2023-10-16'
    });

    this.purchaseModel = new PurchaseModel(db);
    this.payoutModel = new PayoutModel(db);
  }

  async createPaymentIntent(data: CreatePaymentIntentData): Promise<PaymentResult> {
    try {
      // Get template details
      const template = await TemplateModel.findById(data.templateId);
      if (!template) {
        return { success: false, error: 'Template not found' };
      }

      if (template.price === 0) {
        return { success: false, error: 'Cannot create payment for free template' };
      }

      // Check if user already purchased this template
      const alreadyPurchased = await this.purchaseModel.hasUserPurchased(data.userId, data.templateId);
      if (alreadyPurchased) {
        return { success: false, error: 'Template already purchased' };
      }

      // Get user details
      const user = await UserModel.findById(data.userId);
      if (!user) {
        return { success: false, error: 'User not found' };
      }

      // Convert TRY to kuruş (smallest currency unit for Stripe)
      const amountInKurus = Math.round(template.price * 100);

      // Create Stripe payment intent
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: amountInKurus,
        currency: 'try',
        payment_method_types: ['card'],
        metadata: {
          templateId: data.templateId,
          userId: data.userId,
          templateTitle: template.title
        },
        description: `Purchase of template: ${template.title}`,
        receipt_email: user.email
      });

      // Create pending purchase record
      const purchaseData: CreatePurchaseData = {
        userId: data.userId,
        templateId: data.templateId,
        amount: template.price,
        currency: 'TRY',
        paymentMethod: 'card',
        paymentGateway: 'stripe',
        transactionId: paymentIntent.id,
        gatewayTransactionId: paymentIntent.id
      };

      const purchase = await this.purchaseModel.create(purchaseData);

      logger.info('Payment intent created', {
        paymentIntentId: paymentIntent.id,
        purchaseId: purchase.id,
        templateId: data.templateId,
        userId: data.userId,
        amount: template.price
      });

      return {
        success: true,
        purchaseId: purchase.id,
        paymentIntent: {
          id: paymentIntent.id,
          clientSecret: paymentIntent.client_secret!,
          amount: template.price,
          currency: 'TRY',
          status: paymentIntent.status
        }
      };
    } catch (error) {
      logger.error('Error creating payment intent', { error, data });
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Payment processing failed' 
      };
    }
  }

  async confirmPayment(paymentIntentId: string): Promise<PaymentResult> {
    try {
      // Retrieve payment intent from Stripe
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status !== 'succeeded') {
        return { success: false, error: 'Payment not completed' };
      }

      // Find purchase by transaction ID
      const purchase = await this.purchaseModel.findByTransactionId(paymentIntentId);
      if (!purchase) {
        return { success: false, error: 'Purchase record not found' };
      }

      if (purchase.status === 'completed') {
        return { success: true, purchaseId: purchase.id };
      }

      // Update purchase status to completed
      const updatedPurchase = await this.purchaseModel.updateStatus(
        purchase.id, 
        'completed', 
        paymentIntent.id
      );

      if (!updatedPurchase) {
        return { success: false, error: 'Failed to update purchase status' };
      }

      // Update template purchase count and revenue
      await this.updateTemplateStats(purchase.templateId, purchase.amount);

      // Calculate and add creator earnings (80% of sale price)
      await this.addCreatorEarnings(purchase.templateId, purchase.amount);

      logger.info('Payment confirmed successfully', {
        paymentIntentId,
        purchaseId: purchase.id,
        templateId: purchase.templateId,
        amount: purchase.amount
      });

      return { success: true, purchaseId: purchase.id };
    } catch (error) {
      logger.error('Error confirming payment', { error, paymentIntentId });
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Payment confirmation failed' 
      };
    }
  }

  async handleWebhook(signature: string, payload: string): Promise<void> {
    try {
      if (!process.env.STRIPE_WEBHOOK_SECRET) {
        throw new Error('STRIPE_WEBHOOK_SECRET not configured');
      }

      const event = this.stripe.webhooks.constructEvent(
        payload,
        signature,
        process.env.STRIPE_WEBHOOK_SECRET
      );

      logger.info('Stripe webhook received', { type: event.type, id: event.id });

      switch (event.type) {
        case 'payment_intent.succeeded':
          await this.handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
          break;
        case 'payment_intent.payment_failed':
          await this.handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
          break;
        default:
          logger.info('Unhandled webhook event type', { type: event.type });
      }
    } catch (error) {
      logger.error('Webhook handling failed', { error, signature });
      throw error;
    }
  }

  private async handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent): Promise<void> {
    const result = await this.confirmPayment(paymentIntent.id);
    if (!result.success) {
      logger.error('Failed to process successful payment', {
        paymentIntentId: paymentIntent.id,
        error: result.error
      });
    }
  }

  private async handlePaymentFailed(paymentIntent: Stripe.PaymentIntent): Promise<void> {
    try {
      const purchase = await this.purchaseModel.findByTransactionId(paymentIntent.id);
      if (purchase && purchase.status === 'pending') {
        await this.purchaseModel.updateStatus(purchase.id, 'failed');
        logger.info('Purchase marked as failed', {
          purchaseId: purchase.id,
          paymentIntentId: paymentIntent.id
        });
      }
    } catch (error) {
      logger.error('Error handling failed payment', { error, paymentIntentId: paymentIntent.id });
    }
  }

  private async updateTemplateStats(templateId: string, amount: number): Promise<void> {
    const query = `
      UPDATE templates 
      SET purchase_count = purchase_count + 1,
          revenue = revenue + $1
      WHERE id = $2
    `;
    await this.db.query(query, [amount, templateId]);
  }

  private async addCreatorEarnings(templateId: string, saleAmount: number): Promise<void> {
    const creatorEarnings = saleAmount * 0.8; // 80% to creator

    // Get template creator
    const template = await TemplateModel.findById(templateId);
    if (!template || !template.createdBy) {
      logger.error('Template or creator not found for earnings calculation', { templateId });
      return;
    }

    // Update creator balance
    const query = `
      UPDATE users 
      SET balance = balance + $1,
          total_earnings = total_earnings + $1
      WHERE id = $2
    `;
    
    await this.db.query(query, [creatorEarnings, template.createdBy]);

    logger.info('Creator earnings added', {
      templateId,
      creatorId: template.createdBy,
      saleAmount,
      creatorEarnings
    });
  }

  async requestPayout(userId: string, amount: number): Promise<{ success: boolean; payoutId?: string; error?: string }> {
    try {
      // Check minimum payout threshold (100 TL)
      if (amount < 100) {
        return { success: false, error: 'Minimum payout amount is 100 TL' };
      }

      // Check user balance
      const userBalance = await this.payoutModel.getUserEarningsBalance(userId);
      if (userBalance < amount) {
        return { success: false, error: 'Insufficient balance' };
      }

      // Create payout request
      const payout = await this.payoutModel.create({
        userId,
        amount,
        currency: 'TRY'
      });

      // Deduct amount from user balance
      const query = 'UPDATE users SET balance = balance - $1 WHERE id = $2';
      await this.db.query(query, [amount, userId]);

      logger.info('Payout requested', {
        payoutId: payout.id,
        userId,
        amount
      });

      return { success: true, payoutId: payout.id };
    } catch (error) {
      logger.error('Error requesting payout', { error, userId, amount });
      return { 
        success: false, 
        error: error instanceof Error ? error.message : 'Payout request failed' 
      };
    }
  }

  async getUserPurchases(userId: string, limit: number = 50, offset: number = 0) {
    return this.purchaseModel.findByUserId(userId, limit, offset);
  }

  async getUserPayouts(userId: string, limit: number = 50, offset: number = 0) {
    return this.payoutModel.findByUserId(userId, limit, offset);
  }

  async hasUserPurchased(userId: string, templateId: string): Promise<boolean> {
    return this.purchaseModel.hasUserPurchased(userId, templateId);
  }
}