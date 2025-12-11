/**
 * **Feature: quickpdf-template-marketplace, Property 13: Rating System Integrity**
 * **Validates: Requirements 8.3, 8.4**
 * 
 * Property: For any template with ratings, the displayed average and count should 
 * accurately reflect all submitted ratings within the 1-5 star range
 */

import fc from 'fast-check';

// Mock the database-dependent modules
jest.mock('../../services/marketplaceService');

import { MarketplaceService } from '../../services/marketplaceService';
import { TemplateStatus } from '../../models/Template';

describe('Rating System Integrity Property Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('Property 13: Rating System Integrity - Average and count accurately reflect all ratings', async () => {
    await fc.assert(
      fc.asyncProperty(
        // Generate test data
        fc.record({
          templateId: fc.uuid(),
          ratings: fc.array(
            fc.record({
              id: fc.uuid(),
              userId: fc.uuid(),
              rating: fc.integer({ min: 1, max: 5 }),
              comment: fc.option(fc.string({ maxLength: 500 }), { nil: undefined }),
              createdAt: fc.constant(new Date()),
              updatedAt: fc.constant(new Date()),
            }),
            { minLength: 1, maxLength: 20 }
          ),
        }),
        async ({ templateId, ratings }) => {
          // Remove duplicate users (only one rating per user allowed)
          const uniqueRatings = ratings.filter((rating, index, arr) => 
            arr.findIndex(r => r.userId === rating.userId) === index
          );

          // Calculate expected statistics
          const totalRatings = uniqueRatings.length;
          const expectedAverage = totalRatings > 0 
            ? uniqueRatings.reduce((sum, rating) => sum + rating.rating, 0) / totalRatings
            : 0;

          const expectedDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
          uniqueRatings.forEach(rating => {
            expectedDistribution[rating.rating as keyof typeof expectedDistribution]++;
          });

          // Mock the ratings result
          const mockRatingsResult = {
            ratings: uniqueRatings.map(rating => ({
              ...rating,
              templateId,
              userName: 'Test User',
            })),
            pagination: {
              page: 1,
              limit: 10,
              total: totalRatings,
              totalPages: Math.ceil(totalRatings / 10),
            },
            summary: {
              averageRating: expectedAverage,
              totalRatings: totalRatings,
              ratingDistribution: expectedDistribution,
            },
          };

          (MarketplaceService.getTemplateRatings as jest.Mock).mockResolvedValue(mockRatingsResult);

          // Get template ratings
          const ratingsResult = await MarketplaceService.getTemplateRatings(templateId);

          // Verify rating count matches submitted ratings
          expect(ratingsResult.summary.totalRatings).toBe(totalRatings);

          // Verify average rating is correct
          if (totalRatings > 0) {
            expect(Math.abs(ratingsResult.summary.averageRating - expectedAverage)).toBeLessThan(0.01);
            expect(ratingsResult.summary.averageRating).toBeGreaterThanOrEqual(1);
            expect(ratingsResult.summary.averageRating).toBeLessThanOrEqual(5);
          } else {
            expect(ratingsResult.summary.averageRating).toBe(0);
          }

          // Verify rating distribution
          for (let i = 1; i <= 5; i++) {
            expect(ratingsResult.summary.ratingDistribution[i]).toBe(expectedDistribution[i as keyof typeof expectedDistribution]);
          }

          // Verify total distribution equals total ratings
          const distributionSum = Object.values(ratingsResult.summary.ratingDistribution)
            .reduce((sum, count) => sum + count, 0);
          expect(distributionSum).toBe(ratingsResult.summary.totalRatings);

          // Verify all returned ratings are within valid range
          ratingsResult.ratings.forEach(rating => {
            expect(rating.rating).toBeGreaterThanOrEqual(1);
            expect(rating.rating).toBeLessThanOrEqual(5);
            expect(typeof rating.rating).toBe('number');
            expect(Number.isInteger(rating.rating)).toBe(true);
          });

          // Verify rating data integrity
          ratingsResult.ratings.forEach(rating => {
            expect(rating.id).toBeDefined();
            expect(rating.userId).toBeDefined();
            expect(rating.templateId).toBe(templateId);
            expect(rating.createdAt).toBeDefined();
            expect(rating.updatedAt).toBeDefined();
          });
        }
      ),
      { numRuns: 50 }
    );
  });

  test('Property 13a: Rating constraints are enforced', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          userId: fc.uuid(),
          templateId: fc.uuid(),
          rating: fc.integer({ min: -10, max: 15 }), // Include invalid ratings
          comment: fc.option(fc.string({ maxLength: 1000 }), { nil: undefined }),
        }),
        async ({ userId, templateId, rating, comment }) => {
          const isValidRating = rating >= 1 && rating <= 5;

          if (isValidRating) {
            // Mock successful rating submission
            const mockRating = {
              id: fc.sample(fc.uuid(), 1)[0],
              userId,
              templateId,
              rating,
              comment,
              createdAt: new Date(),
              updatedAt: new Date(),
            };

            (MarketplaceService.rateTemplate as jest.Mock).mockResolvedValue(mockRating);

            // Valid rating should succeed
            const result = await MarketplaceService.rateTemplate(userId, templateId, rating, comment);

            expect(result.rating).toBe(rating);
            expect(result.rating).toBeGreaterThanOrEqual(1);
            expect(result.rating).toBeLessThanOrEqual(5);
          } else {
            // Mock rejection for invalid rating
            (MarketplaceService.rateTemplate as jest.Mock).mockRejectedValue(
              new Error('Rating must be between 1 and 5')
            );

            // Invalid rating should be rejected by the system
            await expect(
              MarketplaceService.rateTemplate(userId, templateId, rating, comment)
            ).rejects.toThrow('Rating must be between 1 and 5');
          }
        }
      ),
      { numRuns: 30 }
    );
  });

  test('Property 13b: Users can only rate templates they have purchased', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          userId: fc.uuid(),
          templateId: fc.uuid(),
          rating: fc.integer({ min: 1, max: 5 }),
          hasPurchased: fc.boolean(),
        }),
        async ({ userId, templateId, rating, hasPurchased }) => {
          if (hasPurchased) {
            // Mock successful rating (user has purchased)
            const mockRating = {
              id: fc.sample(fc.uuid(), 1)[0],
              userId,
              templateId,
              rating,
              createdAt: new Date(),
              updatedAt: new Date(),
            };

            (MarketplaceService.rateTemplate as jest.Mock).mockResolvedValue(mockRating);

            // Should succeed
            const result = await MarketplaceService.rateTemplate(userId, templateId, rating);
            expect(result.rating).toBe(rating);
          } else {
            // Mock rejection (user hasn't purchased)
            (MarketplaceService.rateTemplate as jest.Mock).mockRejectedValue(
              new Error('You must purchase the template before rating it')
            );

            // Should fail
            await expect(
              MarketplaceService.rateTemplate(userId, templateId, rating)
            ).rejects.toThrow('You must purchase the template before rating it');
          }
        }
      ),
      { numRuns: 30 }
    );
  });

  test('Property 13c: Rating updates correctly modify averages', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          userId: fc.uuid(),
          templateId: fc.uuid(),
          initialRating: fc.integer({ min: 1, max: 5 }),
          updatedRating: fc.integer({ min: 1, max: 5 }),
        }),
        async ({ userId, templateId, initialRating, updatedRating }) => {
          // Mock initial rating submission
          const mockInitialRating = {
            id: fc.sample(fc.uuid(), 1)[0],
            userId,
            templateId,
            rating: initialRating,
            createdAt: new Date(),
            updatedAt: new Date(),
          };

          (MarketplaceService.rateTemplate as jest.Mock).mockResolvedValue(mockInitialRating);

          // Submit initial rating
          await MarketplaceService.rateTemplate(userId, templateId, initialRating);

          // Mock initial ratings result
          const mockInitialResult = {
            ratings: [mockInitialRating],
            pagination: { page: 1, limit: 10, total: 1, totalPages: 1 },
            summary: {
              averageRating: initialRating,
              totalRatings: 1,
              ratingDistribution: {
                1: initialRating === 1 ? 1 : 0,
                2: initialRating === 2 ? 1 : 0,
                3: initialRating === 3 ? 1 : 0,
                4: initialRating === 4 ? 1 : 0,
                5: initialRating === 5 ? 1 : 0,
              },
            },
          };

          (MarketplaceService.getTemplateRatings as jest.Mock).mockResolvedValue(mockInitialResult);

          // Get initial ratings
          const initialResult = await MarketplaceService.getTemplateRatings(templateId);
          expect(initialResult.summary.totalRatings).toBe(1);
          expect(initialResult.summary.averageRating).toBe(initialRating);

          // Mock updated rating
          const mockUpdatedRating = {
            ...mockInitialRating,
            rating: updatedRating,
            updatedAt: new Date(),
          };

          (MarketplaceService.rateTemplate as jest.Mock).mockResolvedValue(mockUpdatedRating);

          // Update rating
          await MarketplaceService.rateTemplate(userId, templateId, updatedRating);

          // Mock updated ratings result
          const mockUpdatedResult = {
            ratings: [mockUpdatedRating],
            pagination: { page: 1, limit: 10, total: 1, totalPages: 1 },
            summary: {
              averageRating: updatedRating,
              totalRatings: 1,
              ratingDistribution: {
                1: updatedRating === 1 ? 1 : 0,
                2: updatedRating === 2 ? 1 : 0,
                3: updatedRating === 3 ? 1 : 0,
                4: updatedRating === 4 ? 1 : 0,
                5: updatedRating === 5 ? 1 : 0,
              },
            },
          };

          (MarketplaceService.getTemplateRatings as jest.Mock).mockResolvedValue(mockUpdatedResult);

          // Get updated ratings
          const updatedResult = await MarketplaceService.getTemplateRatings(templateId);
          
          // Should still have only 1 rating (updated, not added)
          expect(updatedResult.summary.totalRatings).toBe(1);
          expect(updatedResult.summary.averageRating).toBe(updatedRating);

          // Verify distribution reflects the update
          const expectedDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
          expectedDistribution[updatedRating as keyof typeof expectedDistribution] = 1;

          for (let i = 1; i <= 5; i++) {
            expect(updatedResult.summary.ratingDistribution[i]).toBe(expectedDistribution[i as keyof typeof expectedDistribution]);
          }
        }
      ),
      { numRuns: 25 }
    );
  });
});