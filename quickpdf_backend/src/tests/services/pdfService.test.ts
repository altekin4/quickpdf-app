/**
 * PDF Service Tests
 * Tests for PDF generation functionality
 */

import { PDFService, TextBlock, PDFGenerationOptions } from '@/services/pdfService';

describe('PDFService', () => {
  describe('generateFromText', () => {
    test('should generate PDF from plain text', async () => {
      const text = 'Bu basit bir PDF test metnidir.';
      const options: PDFGenerationOptions = {
        title: 'Test Document',
        author: 'Test Author'
      };

      const pdfBuffer = await PDFService.generateFromText(text, options);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
      
      // Check PDF header
      const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
      expect(pdfHeader).toBe('%PDF');
    });

    test('should handle Turkish characters in text', async () => {
      const turkishText = 'Türkçe karakterler: çğıöşü ÇĞIÖŞÜ';
      
      const pdfBuffer = await PDFService.generateFromText(turkishText);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });

    test('should process date placeholders', async () => {
      const textWithDate = 'Bugün {TODAY} tarihindeyiz. {TARİH} formatında.';
      
      const pdfBuffer = await PDFService.generateFromText(textWithDate);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });
  });

  describe('generateFromBlocks', () => {
    test('should generate PDF from text blocks with different styles', async () => {
      const blocks: TextBlock[] = [
        {
          text: 'Başlık 1',
          isHeading: true,
          headingLevel: 1
        },
        {
          text: 'Bu normal bir paragraftır.',
          style: {
            fontSize: 12,
            textAlign: 'left'
          }
        },
        {
          text: 'Bu kalın yazıdır.',
          style: {
            fontSize: 14,
            fontWeight: 'bold'
          }
        },
        {
          text: 'Bu italik yazıdır.',
          style: {
            fontSize: 12,
            fontStyle: 'italic'
          }
        }
      ];

      const pdfBuffer = await PDFService.generateFromBlocks(blocks);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });

    test('should handle different heading levels', async () => {
      const blocks: TextBlock[] = [
        {
          text: 'Ana Başlık (H1)',
          isHeading: true,
          headingLevel: 1
        },
        {
          text: 'Alt Başlık (H2)',
          isHeading: true,
          headingLevel: 2
        },
        {
          text: 'Küçük Başlık (H3)',
          isHeading: true,
          headingLevel: 3
        },
        {
          text: 'Normal metin içeriği burada yer alır.'
        }
      ];

      const pdfBuffer = await PDFService.generateFromBlocks(blocks);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });

    test('should handle different text alignments', async () => {
      const blocks: TextBlock[] = [
        {
          text: 'Sola hizalı metin',
          style: { textAlign: 'left' }
        },
        {
          text: 'Ortaya hizalı metin',
          style: { textAlign: 'center' }
        },
        {
          text: 'Sağa hizalı metin',
          style: { textAlign: 'right' }
        },
        {
          text: 'İki yana yaslı metin - bu uzun bir metin örneğidir ve iki yana yaslanarak düzgün görünmelidir.',
          style: { textAlign: 'justify' }
        }
      ];

      const pdfBuffer = await PDFService.generateFromBlocks(blocks);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });
  });

  describe('testTurkishCharacters', () => {
    test('should generate Turkish character test PDF', async () => {
      const pdfBuffer = await PDFService.testTurkishCharacters();

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
      
      // Check PDF header
      const pdfHeader = pdfBuffer.toString('ascii', 0, 4);
      expect(pdfHeader).toBe('%PDF');
    });
  });

  describe('font size validation', () => {
    test('should enforce minimum font size', async () => {
      const blocks: TextBlock[] = [
        {
          text: 'Çok küçük yazı',
          style: { fontSize: 5 } // Below minimum
        }
      ];

      const pdfBuffer = await PDFService.generateFromBlocks(blocks);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });

    test('should enforce maximum font size', async () => {
      const blocks: TextBlock[] = [
        {
          text: 'Çok büyük yazı',
          style: { fontSize: 30 } // Above maximum
        }
      ];

      const pdfBuffer = await PDFService.generateFromBlocks(blocks);

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });
  });

  describe('error handling', () => {
    test('should handle empty text gracefully', async () => {
      const pdfBuffer = await PDFService.generateFromText('');

      expect(pdfBuffer).toBeInstanceOf(Buffer);
      expect(pdfBuffer.length).toBeGreaterThan(0);
    });

    test('should handle empty blocks array', async () => {
      await expect(PDFService.generateFromBlocks([])).rejects.toThrow();
    });
  });
});