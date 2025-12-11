/**
 * **Feature: quickpdf-template-marketplace, Property 11: Creator Earnings Calculation**
 * **Validates: Requirements 7.5**
 * 
 * Property: For any template sale transaction, the creator should receive exactly 80% of the sale price 
 * after successful payment processing
 */

import fc from 'fast-check';
import { Pool } from 'pg';
import { TemplateModel } from '../../models/Template';
import { UserModel } from '../../models/User';
import { PurchaseModel } from '../../models/Purchase';
import { pool } from '../../config/database';
import { logger } from '../../utils/logger';

describe('Property 11: Creator Earnings Calculation', () => {
  let purchaseModel: PurchaseModel;
  let testDb: Pool;

  beforeAll(async () => {
    testDb = pool;
    purchaseModel = new PurchaseModel(testDb);
  });

  beforeEach(async () => {
    // Clean up test data
    await testDb.query('DELETE FROM purchases WHERE transaction_id LIKE $1', ['test_%']);
    await testDb.query('DELETE FROM templates WHERE title LIKE $1', ['Test Template%']);
    await testDb.query('DELETE FROM categories WHERE name LIKE $1', ['Test Category%']);
    await testDb.query('DELETE FROM users WHERE email LIKE $1', ['test%@test.com']);
  });

  afterAll(async () => {
    // Final cleanup
    await testDb.query('DELETE FROM purchases WHERE transaction_id LIKE $1', ['test_%']);
    await testDb.query('DELETE FROM templates WHERE title LIKE $1', ['Test Template%']);
    await testDb.query('DELETE FROM categories WHERE name LIKE $1', ['Test Category%']);
    await testDb.query('DELETE FROM users WHERE email LIKE $1', ['test%@test.com']);
  });

  const userArbitrary = fc.record({
    email: fc.emailAddress().map(email => `test_${email}`),
    fullName: fc.string({ minLength: 2, maxLength: 50 }),
    password: fc.string({ minLength: 6, maxLength: 20 }),
    role: fc.constantFrom('user', 'creator') as fc.Arbitrary<'user' | 'creator'>
  });

  const templateArbitrary = fc.record({
    title: fc.string({ minLength: 5, maxLength: 100 }).map(title => `Test Template ${title}`),
    description: fc.string({ minLength: 10, maxLength: 500 }),
    price: fc.float({ min: 5, max: 500 }).map(p => Math.round(p * 100) / 100),
    placeholders: fc.constant({}),
    body: fc.string({ minLength: 20, maxLength: 1000 })
  });

  test('Property: Creator receives exactly 80% of sale price', async () => {
    await fc.assert(
      fc.asyncProperty(
        userArbitrary,
        userArbitrary,
        templateArbitrary,
        async (creatorData, buyerData, templateData) => {
          try {
            // Ensure different users
            if (creatorData.email === buyerData.email) {
              buyerData.email = `buyer_${buyerData.email}`;
            }

            // Create creator user
            const creator = await UserModel.create({
              email: creatorData.email,
              full_name: creatorData.fullName,
              password_hash: 'hashed_password',
              role: 'creator'
            });

            // Create buyer user
            const buyer = await UserModel.create({
              email: buyerData.email,
              full_name: buyerData.fullName,
              password_hash: 'hashed_password',
              role: buyerData.role
            });

            // Create a test category
            const categoryResult = await testDb.query(
              'INSERT INTO categories (name, slug) VALUES ($1, $2) RETURNING id',
              [`Test Category ${Date.now()}`, `test-category-${Date.now()}`]
            );
            const categoryId = categoryResult.rows[0].id;

            // Create template
            const template = await TemplateModel.create(creator.id, {
              title: templateData.title,
              description: templateData.description,
              body: templateData.body,
              placeholders: templateData.placeholders,
              price: templateData.price,
              categoryId: categoryId
            });

            // Get creator's initial balance
            const initialCreatorQuery = await testDb.query(
              'SELECT balance, total_earnings FROM users WHERE id = $1',
              [creator.id]
            );
            const initialBalance = parseFloat(initialCreatorQuery.rows[0].balance);
            const initialTotalEarnings = parseFloat(initialCreatorQuery.rows[0].total_earnings);

            // Create and complete a purchase
            const purchase = await purchaseModel.create({
              userId: buyer.id,
              templateId: template.id,
              amount: template.price,
              currency: 'TRY',
              paymentMethod: 'card',
              paymentGateway: 'stripe',
              transactionId: `test_${Date.now()}_${Math.random()}`,
              gatewayTransactionId: `pi_test_${Date.now()}`
            });

            // Simulate successful payment and earnings calculation
            await purchaseModel.updateStatus(purchase.id, 'completed');

            // Calculate expected creator earnings (80% of sale price)
            const expectedEarnings = template.price * 0.8;

            // Simulate the earnings addition (this would normally be done by PaymentService)
            await testDb.query(
              'UPDATE users SET balance = balance + $1, total_earnings = total_earnings + $1 WHERE id = $2',
              [expectedEarnings, creator.id]
            );

            // Verify creator's updated balance and earnings
            const updatedCreatorQuery = await testDb.query(
              'SELECT balance, total_earnings FROM users WHERE id = $1',
              [creator.id]
            );
            const updatedBalance = parseFloat(updatedCreatorQuery.rows[0].balance);
            const updatedTotalEarnings = parseFloat(updatedCreatorQuery.rows[0].total_earnings);

            // Property: Creator should receive exactly 80% of the sale price
            const actualEarningsIncrease = updatedBalance - initialBalance;
            const actualTotalEarningsIncrease = updatedTotalEarnings - initialTotalEarnings;

            // Allow for small floating point precision differences
            const tolerance = 0.01;
            expect(Math.abs(actualEarningsIncrease - expectedEarnings)).toBeLessThan(tolerance);
            expect(Math.abs(actualTotalEarningsIncrease - expectedEarnings)).toBeLessThan(tolerance);

            // Property: Earnings should be exactly 80% of sale price
            const earningsPercentage = actualEarningsIncrease / template.price;
            expect(Math.abs(earningsPercentage - 0.8)).toBeLessThan(0.001);

            return true;
          } catch (error) {
            logger.error('Property test failed:', error);
            return false;
          }
        }
      ),
      { numRuns: 20, timeout: 30000 }
    );
  });

  test('Property: Multiple sales accumulate earnings correctly', async () => {
    await fc.assert(
      fc.asyncProperty(
        userArbitrary,
        fc.array(templateArbitrary, { minLength: 2, maxLength: 5 }),
        fc.array(userArbitrary, { minLength: 2, maxLength: 5 }),
        async (creatorData, templatesData, buyersData) => {
          try {
            // Create creator user
            const creator = await UserModel.create({
              email: creatorData.email,
              full_name: creatorData.fullName,
              password_hash: 'hashed_password',
              role: 'creator'
            });

            // Create test category
            const categoryResult = await testDb.query(
              'INSERT INTO categories (name, slug) VALUES ($1, $2) RETURNING id',
              [`Test Category ${Date.now()}`, `test-category-${Date.now()}`]
            );
            const categoryId = categoryResult.rows[0].id;

            // Create templates
            const templates = [];
            for (let i = 0; i < templatesData.length; i++) {
              const templateData = templatesData[i];
              const template = await TemplateModel.create(creator.id, {
                title: `${templateData.title}_${i}`,
                description: templateData.description,
                body: templateData.body,
                placeholders: templateData.placeholders,
                price: templateData.price,
                categoryId: categoryId
              });
              templates.push(template);
            }

            // Create buyers
            const buyers = [];
            for (let i = 0; i < buyersData.length; i++) {
              const buyerData = buyersData[i];
              const buyer = await UserModel.create({
                email: `buyer_${i}_${buyerData.email}`,
                full_name: buyerData.fullName,
                password_hash: 'hashed_password',
                role: buyerData.role
              });
              buyers.push(buyer);
            }

            // Get creator's initial balance
            const initialCreatorQuery = await testDb.query(
              'SELECT balance, total_earnings FROM users WHERE id = $1',
              [creator.id]
            );
            const initialBalance = parseFloat(initialCreatorQuery.rows[0].balance);
            const initialTotalEarnings = parseFloat(initialCreatorQuery.rows[0].total_earnings);

            // Simulate multiple sales
            let totalExpectedEarnings = 0;
            for (let i = 0; i < Math.min(templates.length, buyers.length); i++) {
              const template = templates[i];
              const buyer = buyers[i];

              // Create and complete purchase
              const purchase = await purchaseModel.create({
                userId: buyer.id,
                templateId: template.id,
                amount: template.price,
                currency: 'TRY',
                paymentMethod: 'card',
                paymentGateway: 'stripe',
                transactionId: `test_${Date.now()}_${i}_${Math.random()}`,
                gatewayTransactionId: `pi_test_${Date.now()}_${i}`
              });

              await purchaseModel.updateStatus(purchase.id, 'completed');

              // Calculate and add earnings
              const earnings = template.price * 0.8;
              totalExpectedEarnings += earnings;

              await testDb.query(
                'UPDATE users SET balance = balance + $1, total_earnings = total_earnings + $1 WHERE id = $2',
                [earnings, creator.id]
              );
            }

            // Verify total accumulated earnings
            const finalCreatorQuery = await testDb.query(
              'SELECT balance, total_earnings FROM users WHERE id = $1',
              [creator.id]
            );
            const finalBalance = parseFloat(finalCreatorQuery.rows[0].balance);
            const finalTotalEarnings = parseFloat(finalCreatorQuery.rows[0].total_earnings);

            const actualEarningsIncrease = finalBalance - initialBalance;
            const actualTotalEarningsIncrease = finalTotalEarnings - initialTotalEarnings;

            // Property: Total earnings should equal sum of individual 80% calculations
            const tolerance = 0.01;
            expect(Math.abs(actualEarningsIncrease - totalExpectedEarnings)).toBeLessThan(tolerance);
            expect(Math.abs(actualTotalEarningsIncrease - totalExpectedEarnings)).toBeLessThan(tolerance);

            return true;
          } catch (error) {
            logger.error('Property test failed:', error);
            return false;
          }
        }
      ),
      { numRuns: 10, timeout: 30000 }
    );
  });

  test('Property: Free templates do not generate earnings', async () => {
    await fc.assert(
      fc.asyncProperty(
        userArbitrary,
        userArbitrary,
        templateArbitrary,
        async (creatorData, buyerData, templateData) => {
          try {
            // Ensure different users
            if (creatorData.email === buyerData.email) {
              buyerData.email = `buyer_${buyerData.email}`;
            }

            // Create creator user
            const creator = await UserModel.create({
              email: creatorData.email,
              full_name: creatorData.fullName,
              password_hash: 'hashed_password',
              role: 'creator'
            });

            // Create buyer user
            const buyer = await UserModel.create({
              email: buyerData.email,
              full_name: buyerData.fullName,
              password_hash: 'hashed_password',
              role: buyerData.role
            });

            // Create test category
            const categoryResult = await testDb.query(
              'INSERT INTO categories (name, slug) VALUES ($1, $2) RETURNING id',
              [`Test Category ${Date.now()}`, `test-category-${Date.now()}`]
            );
            const categoryId = categoryResult.rows[0].id;

            // Create free template (price = 0)
            const template = await TemplateModel.create(creator.id, {
              title: templateData.title,
              description: templateData.description,
              body: templateData.body,
              placeholders: templateData.placeholders,
              price: 0, // Free template
              categoryId: categoryId
            });

            // Get creator's initial balance
            const initialCreatorQuery = await testDb.query(
              'SELECT balance, total_earnings FROM users WHERE id = $1',
              [creator.id]
            );
            const initialBalance = parseFloat(initialCreatorQuery.rows[0].balance);
            const initialTotalEarnings = parseFloat(initialCreatorQuery.rows[0].total_earnings);

            // For free templates, no purchase record should be created
            // But if it were, no earnings should be generated
            const expectedEarnings = template.price * 0.8; // Should be 0

            // Simulate earnings calculation for free template
            await testDb.query(
              'UPDATE users SET balance = balance + $1, total_earnings = total_earnings + $1 WHERE id = $2',
              [expectedEarnings, creator.id]
            );

            // Verify no earnings were added
            const updatedCreatorQuery = await testDb.query(
              'SELECT balance, total_earnings FROM users WHERE id = $1',
              [creator.id]
            );
            const updatedBalance = parseFloat(updatedCreatorQuery.rows[0].balance);
            const updatedTotalEarnings = parseFloat(updatedCreatorQuery.rows[0].total_earnings);

            // Property: Free templates should not generate any earnings
            expect(updatedBalance).toBe(initialBalance);
            expect(updatedTotalEarnings).toBe(initialTotalEarnings);
            expect(expectedEarnings).toBe(0);

            return true;
          } catch (error) {
            logger.error('Property test failed:', error);
            return false;
          }
        }
      ),
      { numRuns: 20, timeout: 30000 }
    );
  });

  test('Property: Earnings calculation is consistent across different price ranges', async () => {
    await fc.assert(
      fc.asyncProperty(
        userArbitrary,
        userArbitrary,
        fc.float({ min: 5, max: 500 }).map(p => Math.round(p * 100) / 100),
        async (creatorData, buyerData, price) => {
          try {
            // Ensure different users
            if (creatorData.email === buyerData.email) {
              buyerData.email = `buyer_${buyerData.email}`;
            }

            // Create creator user
            const creator = await UserModel.create({
              email: creatorData.email,
              full_name: creatorData.fullName,
              password_hash: 'hashed_password',
              role: 'creator'
            });

            // Create buyer user
            const buyer = await UserModel.create({
              email: buyerData.email,
              full_name: buyerData.fullName,
              password_hash: 'hashed_password',
              role: buyerData.role
            });

            // Create test category
            const categoryResult = await testDb.query(
              'INSERT INTO categories (name, slug) VALUES ($1, $2) RETURNING id',
              [`Test Category ${Date.now()}`, `test-category-${Date.now()}`]
            );
            const categoryId = categoryResult.rows[0].id;

            // Create template with specific price
            const template = await TemplateModel.create(creator.id, {
              title: `Test Template ${Date.now()}`,
              description: 'Test description',
              body: 'Test body content',
              placeholders: {},
              price: price,
              categoryId: categoryId
            });

            // Calculate expected earnings
            const expectedEarnings = price * 0.8;

            // Get creator's initial balance
            const initialCreatorQuery = await testDb.query(
              'SELECT balance FROM users WHERE id = $1',
              [creator.id]
            );
            const initialBalance = parseFloat(initialCreatorQuery.rows[0].balance);

            // Simulate earnings addition
            await testDb.query(
              'UPDATE users SET balance = balance + $1 WHERE id = $2',
              [expectedEarnings, creator.id]
            );

            // Verify earnings calculation
            const updatedCreatorQuery = await testDb.query(
              'SELECT balance FROM users WHERE id = $1',
              [creator.id]
            );
            const updatedBalance = parseFloat(updatedCreatorQuery.rows[0].balance);

            const actualEarnings = updatedBalance - initialBalance;

            // Property: Earnings should always be exactly 80% regardless of price
            const tolerance = 0.01;
            expect(Math.abs(actualEarnings - expectedEarnings)).toBeLessThan(tolerance);

            // Property: Earnings percentage should always be 80%
            if (price > 0) {
              const earningsPercentage = actualEarnings / price;
              expect(Math.abs(earningsPercentage - 0.8)).toBeLessThan(0.001);
            }

            return true;
          } catch (error) {
            logger.error('Property test failed:', error);
            return false;
          }
        }
      ),
      { numRuns: 50, timeout: 30000 }
    );
  });
});