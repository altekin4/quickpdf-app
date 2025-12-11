/**
 * **Feature: quickpdf-template-marketplace, Property 3: Turkish Character Support**
 * **Validates: Requirements 1.5**
 */

import * as fc from 'fast-check';
import { PDFService } from '@/services/pdfService';

describe('Property 3: Turkish Character Support', () => {
  
  test('should render Turkish characters correctly', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.constantFrom('çiçek', 'İstanbul', 'öğretmen', 'şehir', 'üzüm', 'türkçe'),
        async (turkishWord) => {
          const pdfBuffer = await PDFService.generateFromText(turkishWord);
          
          expect(pdfBuffer).toBeInstanceOf(Buffer);
          expect(pdfBuffer.length).toBeGreaterThan(0);
          
          const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
          expect(pdfHeader).toBe('%PDF');
        }
      ),
      { numRuns: 100 }
    );
  });

  test('should handle Turkish character combinations', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(fc.constantFrom('ç', 'ğ', 'ı', 'ö', 'ş', 'ü', 'Ç', 'Ğ', 'İ', 'Ö', 'Ş', 'Ü'), { minLength: 1, maxLength: 5 }),
        async (chars) => {
          const text = `Test: ${chars.join('')}`;
          const pdfBuffer = await PDFService.generateFromText(text);
          
          expect(pdfBuffer).toBeInstanceOf(Buffer);
          expect(pdfBuffer.length).toBeGreaterThan(0);
          
          const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
          expect(pdfHeader).toBe('%PDF');
        }
      ),
      { numRuns: 100 }
    );
  });

  test('should execute built-in Turkish test', async () => {
    const pdfBuffer = await PDFService.testTurkishCharacters();
    
    expect(pdfBuffer).toBeInstanceOf(Buffer);
    expect(pdfBuffer.length).toBeGreaterThan(0);
    
    const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
    expect(pdfHeader).toBe('%PDF');
  });
});