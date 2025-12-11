/**
 * PDF Generation Service
 * Handles PDF creation with text formatting, Turkish character support, and styling options
 */

import PDFDocument from 'pdfkit';
import { Readable } from 'stream';

// Type alias for PDFDocument instance
type PDFDocumentInstance = InstanceType<typeof PDFDocument>;

export interface TextStyle {
  fontSize?: number; // 8-24pt range
  fontWeight?: 'normal' | 'bold';
  fontStyle?: 'normal' | 'italic';
  textDecoration?: 'none' | 'underline';
  textAlign?: 'left' | 'center' | 'right' | 'justify';
}

export interface HeadingStyle extends TextStyle {
  level: 1 | 2 | 3; // H1, H2, H3
}

export interface PDFGenerationOptions {
  title?: string;
  author?: string;
  subject?: string;
  keywords?: string[];
  pageSize?: 'A4' | 'Letter';
  margins?: {
    top: number;
    bottom: number;
    left: number;
    right: number;
  };
}

export interface TextBlock {
  text: string;
  style?: TextStyle;
  isHeading?: boolean;
  headingLevel?: 1 | 2 | 3;
}

export class PDFService {
  private static readonly DEFAULT_FONT_SIZE = 12;
  private static readonly MIN_FONT_SIZE = 8;
  private static readonly MAX_FONT_SIZE = 24;
  
  private static readonly HEADING_SIZES = {
    1: 20, // H1
    2: 16, // H2
    3: 14  // H3
  };

  /**
   * Generate PDF from plain text with basic formatting
   */
  public static async generateFromText(
    text: string,
    options: PDFGenerationOptions = {}
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = this.createDocument(options);
        const chunks: Buffer[] = [];

        // Collect PDF data
        doc.on('data', (chunk: Buffer) => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        // Process text and add to document
        this.addTextToDocument(doc, text);

        // Finalize the document
        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * Generate PDF from structured text blocks with advanced formatting
   */
  public static async generateFromBlocks(
    blocks: TextBlock[],
    options: PDFGenerationOptions = {}
  ): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = this.createDocument(options);
        const chunks: Buffer[] = [];

        doc.on('data', (chunk: Buffer) => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        // Process each text block
        blocks.forEach((block, index) => {
          if (index > 0) {
            doc.moveDown(0.5); // Add spacing between blocks
          }
          this.addTextBlockToDocument(doc, block);
        });

        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * Create a new PDF document with specified options
   */
  private static createDocument(options: PDFGenerationOptions): PDFDocumentInstance {
    const doc = new PDFDocument({
      size: options.pageSize || 'A4',
      margins: options.margins || {
        top: 50,
        bottom: 50,
        left: 50,
        right: 50
      },
      info: {
        Title: options.title || 'QuickPDF Document',
        Author: options.author || 'QuickPDF',
        Subject: options.subject || 'Generated PDF Document',
        Keywords: options.keywords?.join(', ') || 'PDF, Document'
      }
    });

    // Register fonts for Turkish character support
    this.registerFonts(doc);

    return doc;
  }

  /**
   * Register fonts that support Turkish characters
   */
  private static registerFonts(doc: PDFDocumentInstance): void {
    // PDFKit's built-in fonts support Turkish characters
    // We'll use Helvetica family which has good Turkish support
    doc.registerFont('Helvetica-Turkish', 'Helvetica');
    doc.registerFont('Helvetica-Bold-Turkish', 'Helvetica-Bold');
    doc.registerFont('Helvetica-Oblique-Turkish', 'Helvetica-Oblique');
    doc.registerFont('Helvetica-BoldOblique-Turkish', 'Helvetica-BoldOblique');
  }

  /**
   * Add plain text to document with automatic date insertion
   */
  private static addTextToDocument(doc: PDFDocumentInstance, text: string): void {
    // Process text for automatic date insertion
    const processedText = this.processTextForDates(text);
    
    // Set default font and size
    doc.font('Helvetica-Turkish')
       .fontSize(this.DEFAULT_FONT_SIZE);

    // Add text with proper line breaks
    doc.text(processedText, {
      align: 'left',
      lineGap: 2
    });
  }

  /**
   * Add formatted text block to document
   */
  private static addTextBlockToDocument(doc: PDFDocumentInstance, block: TextBlock): void {
    const processedText = this.processTextForDates(block.text);
    
    // Apply heading styles if it's a heading
    if (block.isHeading && block.headingLevel) {
      this.applyHeadingStyle(doc, block.headingLevel);
    } else if (block.style) {
      this.applyTextStyle(doc, block.style);
    } else {
      // Default style
      doc.font('Helvetica-Turkish').fontSize(this.DEFAULT_FONT_SIZE);
    }

    // Add text with alignment
    const align = block.style?.textAlign || 'left';
    doc.text(processedText, {
      align: align as any,
      lineGap: 2
    });
  }

  /**
   * Apply heading style to document
   */
  private static applyHeadingStyle(doc: PDFDocumentInstance, level: 1 | 2 | 3): void {
    const fontSize = this.HEADING_SIZES[level];
    doc.font('Helvetica-Bold-Turkish').fontSize(fontSize);
  }

  /**
   * Apply text style to document
   */
  private static applyTextStyle(doc: PDFDocumentInstance, style: TextStyle): void {
    // Validate and set font size
    const fontSize = this.validateFontSize(style.fontSize || this.DEFAULT_FONT_SIZE);
    
    // Determine font based on weight and style
    let fontName = 'Helvetica-Turkish';
    
    if (style.fontWeight === 'bold' && style.fontStyle === 'italic') {
      fontName = 'Helvetica-BoldOblique-Turkish';
    } else if (style.fontWeight === 'bold') {
      fontName = 'Helvetica-Bold-Turkish';
    } else if (style.fontStyle === 'italic') {
      fontName = 'Helvetica-Oblique-Turkish';
    }

    doc.font(fontName).fontSize(fontSize);

    // Note: PDFKit doesn't directly support underline in font selection
    // Underline would need to be applied separately using doc.underline()
    // This would require more complex text positioning
  }

  /**
   * Validate font size within allowed range
   */
  private static validateFontSize(size: number): number {
    return Math.max(this.MIN_FONT_SIZE, Math.min(this.MAX_FONT_SIZE, size));
  }

  /**
   * Process text for automatic date insertion in Turkish format
   */
  private static processTextForDates(text: string): string {
    const today = new Date();
    const turkishDate = this.formatTurkishDate(today);
    
    // Replace common date placeholders
    return text
      .replace(/\{TODAY\}/g, turkishDate)
      .replace(/\{BUGÜN\}/g, turkishDate)
      .replace(/\{TARİH\}/g, turkishDate)
      .replace(/\{DATE\}/g, turkishDate);
  }

  /**
   * Format date in Turkish format (DD.MM.YYYY)
   */
  private static formatTurkishDate(date: Date): string {
    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const year = date.getFullYear();
    
    return `${day}.${month}.${year}`;
  }

  /**
   * Test Turkish character rendering
   */
  public static async testTurkishCharacters(): Promise<Buffer> {
    const turkishText = `
Turkish Character Test / Türkçe Karakter Testi

Lowercase: çğıöşü
Uppercase: ÇĞIÖŞÜ

Sample text: Şu çılgın türkçe ğöğüs iğnesi.
Sample text: Bu güzel ülkede yaşıyoruz.

Date test: Bugün {TODAY} tarihindeyiz.
`;

    return this.generateFromText(turkishText, {
      title: 'Turkish Character Test',
      author: 'QuickPDF Test'
    });
  }
}