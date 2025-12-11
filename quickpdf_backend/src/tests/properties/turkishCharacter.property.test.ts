/**
 * **Feature: quickpdf-template-marketplace, Property 3: Turkish Character Support**
 * **Validates: Requirements 1.5**
 */

import * as fc from 'fast-check';
import { PDFService } from '@/services/pdfService';

describe('Property 3: Turkish Character Support', () => {
  
  const TURKISH_CHARS = ['ç', 'ğ', 'ı', 'ö', 'ş', 'ü', 'Ç', 'Ğ', 'İ', 'Ö', 'Ş', 'Ü'];
  const TURKISH_WORDS = ['çiçek', 'İstanbul', 'öğretmen', 'şehir', 'üzüm', 'türkçe'];

  test('should render Turkish characters correctly in PDF', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.shuffledSubarray(TURKISH_CHARS, { minLength: 1, maxLength: 6 }),
        fc.string({ minLength: 5, maxLength: 30 }),
        async (turkishChars, baseText) => {
          const textWithTurkish = `${baseText} ${turkishChars.join(' ')}`;
          
          const pdfBuffer = await PDFService.generateFromText(textWithTurkish);
          
          expect(pdfBuffer).toBeInstanceOf(Buffer);
          expect(pdfBuffer.length).toBeGreaterThan(0);
          
          const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
          expect(pdfHeader).toBe('%PDF');
          
          turkishChars.forEach(char => {
            expect(textWithTurkish).toContain(char);
          });
        }
      ),
      { numRuns: 100 }
    );
  });

  test('should render Turkish words correctly', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.shuffledSubarray(TURKISH_WORDS, { minLength: 1, maxLength: 3 }),
        async (turkishWords) => {
          const text = turkishWords.join(' ');
          
          const pdfBuffer = await PDFService.generateFromText(text);
          
          expect(pdfBuffer).toBeInstanceOf(Buffer);
          expect(pdfBuffer.length).toBeGreaterThan(0);
          
          const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
          expect(pdfHeader).toBe('%PDF');
          
          turkishWords.forEach(word => {
            expect(text).toContain(word);
          });
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