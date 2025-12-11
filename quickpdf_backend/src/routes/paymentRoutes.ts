import express, { Router } from 'express';
import { body, param, query } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { authMiddleware, AuthenticatedRequest } from '@/middleware/authMiddleware';
import { PaymentService } from '@/services/paymentService';
import { logger } from '@/utils/logger';
import { pool } from '@/config/database';

const router = Router();
const paymentService = new PaymentService(pool);

  // Create payment intent for template purchase
  router.post('/payment-intent',
    authMiddleware,
    [
      body('templateId').isUUID().withMessage('Valid template ID is required'),
      body('paymentMethodId').optional().isString()
    ],
    validateRequest,
    async (req, res) => {
      try {
        const { templateId, paymentMethodId } = req.body;
        const userId = req.user!.id;

        const result = await paymentService.createPaymentIntent({
          templateId,
          userId,
          paymentMethodId
        });

        if (!result.success) {
          return res.status(400).json({
            error: {
              code: 'PAYMENT_INTENT_FAILED',
              message: result.error || 'Failed to create payment intent'
            }
          });
        }

        res.json({
          success: true,
          data: {
            purchaseId: result.purchaseId,
            paymentIntent: result.paymentIntent
          }
        });
      } catch (error) {
        logger.error('Error in payment intent creation', { error, userId: req.user?.id });
        res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
          }
        });
      }
    }
  );

  // Confirm payment after successful Stripe payment
  router.post('/confirm',
    authMiddleware,
    [
      body('paymentIntentId').isString().withMessage('Payment intent ID is required')
    ],
    validateRequest,
    async (req, res) => {
      try {
        const { paymentIntentId } = req.body;

        const result = await paymentService.confirmPayment(paymentIntentId);

        if (!result.success) {
          return res.status(400).json({
            error: {
              code: 'PAYMENT_CONFIRMATION_FAILED',
              message: result.error || 'Failed to confirm payment'
            }
          });
        }

        res.json({
          success: true,
          data: {
            purchaseId: result.purchaseId
          }
        });
      } catch (error) {
        logger.error('Error in payment confirmation', { error, userId: req.user?.id });
        res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
          }
        });
      }
    }
  );

  // Stripe webhook endpoint
  router.post('/webhook',
    express.raw({ type: 'application/json' }),
    async (req, res) => {
      try {
        const signature = req.headers['stripe-signature'] as string;
        
        if (!signature) {
          return res.status(400).json({
            error: {
              code: 'MISSING_SIGNATURE',
              message: 'Stripe signature header is required'
            }
          });
        }

        await paymentService.handleWebhook(signature, req.body);
        
        res.json({ received: true });
      } catch (error) {
        logger.error('Webhook processing failed', { error });
        res.status(400).json({
          error: {
            code: 'WEBHOOK_ERROR',
            message: 'Webhook processing failed'
          }
        });
      }
    }
  );

  // Get user's purchase history
  router.get('/purchases',
    authMiddleware,
    [
      query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
      query('offset').optional().isInt({ min: 0 }).withMessage('Offset must be non-negative')
    ],
    validateRequest,
    async (req, res) => {
      try {
        const userId = req.user!.id;
        const limit = parseInt(req.query.limit as string) || 50;
        const offset = parseInt(req.query.offset as string) || 0;

        const purchases = await paymentService.getUserPurchases(userId, limit, offset);

        res.json({
          success: true,
          data: {
            purchases,
            pagination: {
              limit,
              offset,
              hasMore: purchases.length === limit
            }
          }
        });
      } catch (error) {
        logger.error('Error fetching user purchases', { error, userId: req.user?.id });
        res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
          }
        });
      }
    }
  );

  // Check if user has purchased a specific template
  router.get('/check-purchase/:templateId',
    authMiddleware,
    [
      param('templateId').isUUID().withMessage('Valid template ID is required')
    ],
    validateRequest,
    async (req, res) => {
      try {
        const { templateId } = req.params;
        const userId = req.user!.id;

        const hasPurchased = await paymentService.hasUserPurchased(userId, templateId);

        res.json({
          success: true,
          data: {
            hasPurchased
          }
        });
      } catch (error) {
        logger.error('Error checking purchase status', { error, userId: req.user?.id });
        res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
          }
        });
      }
    }
  );

  // Request payout (for creators)
  router.post('/payout',
    authMiddleware,
    [
      body('amount').isFloat({ min: 100 }).withMessage('Minimum payout amount is 100 TL')
    ],
    validateRequest,
    async (req, res) => {
      try {
        const { amount } = req.body;
        const userId = req.user!.id;

        const result = await paymentService.requestPayout(userId, amount);

        if (!result.success) {
          return res.status(400).json({
            error: {
              code: 'PAYOUT_REQUEST_FAILED',
              message: result.error || 'Failed to request payout'
            }
          });
        }

        res.json({
          success: true,
          data: {
            payoutId: result.payoutId
          }
        });
      } catch (error) {
        logger.error('Error requesting payout', { error, userId: req.user?.id });
        res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
          }
        });
      }
    }
  );

  // Get user's payout history
  router.get('/payouts',
    authMiddleware,
    [
      query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
      query('offset').optional().isInt({ min: 0 }).withMessage('Offset must be non-negative')
    ],
    validateRequest,
    async (req, res) => {
      try {
        const userId = req.user!.id;
        const limit = parseInt(req.query.limit as string) || 50;
        const offset = parseInt(req.query.offset as string) || 0;

        const payouts = await paymentService.getUserPayouts(userId, limit, offset);

        res.json({
          success: true,
          data: {
            payouts,
            pagination: {
              limit,
              offset,
              hasMore: payouts.length === limit
            }
          }
        });
      } catch (error) {
        logger.error('Error fetching user payouts', { error, userId: req.user?.id });
        res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
          }
        });
      }
    }
  );

export default router;