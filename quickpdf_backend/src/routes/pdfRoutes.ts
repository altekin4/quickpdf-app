import { Router } from 'express';
import { body, param } from 'express-validator';
import { validateRequest } from '@/middleware/validateRequest';
import { asyncHandler } from '@/middleware/errorHandler';
import { AuthenticatedRequest } from '@/middleware/authMiddleware';
import { PDFService, TextBlock, PDFGenerationOptions } from '@/services/pdfService';

const router = Router();

// Generate PDF from text
router.post('/generate',
  [
    body('text').trim().isLength({ min: 1 }).withMessage('Text content is required'),
    body('fontSize').optional().isFloat({ min: 8, max: 24 }).withMessage('Font size must be between 8 and 24'),
    body('fontFamily').optional().isString().withMessage('Font family must be a string'),
    body('alignment').optional().isIn(['left', 'center', 'right', 'justify']).withMessage('Invalid alignment'),
    body('bold').optional().isBoolean().withMessage('Bold must be a boolean'),
    body('italic').optional().isBoolean().withMessage('Italic must be a boolean'),
    body('underline').optional().isBoolean().withMessage('Underline must be a boolean'),
  ],
  validateRequest([
    body('text').trim().isLength({ min: 1 }),
    body('fontSize').optional().isFloat({ min: 8, max: 24 }),
    body('fontFamily').optional().isString(),
    body('alignment').optional().isIn(['left', 'center', 'right', 'justify']),
    body('bold').optional().isBoolean(),
    body('italic').optional().isBoolean(),
    body('underline').optional().isBoolean(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    const { 
      text, 
      fontSize = 12, 
      alignment = 'left', 
      bold = false, 
      italic = false,
      title,
      author 
    } = req.body;

    try {
      // Prepare PDF generation options
      const options: PDFGenerationOptions = {
        title: title || 'QuickPDF Document',
        author: author || req.user?.email || 'QuickPDF User',
        pageSize: 'A4'
      };

      // Create text block with formatting
      const textBlock: TextBlock = {
        text,
        style: {
          fontSize,
          textAlign: alignment as any,
          fontWeight: bold ? 'bold' : 'normal',
          fontStyle: italic ? 'italic' : 'normal'
        }
      };

      // Generate PDF
      const pdfBuffer = await PDFService.generateFromBlocks([textBlock], options);
      
      // Generate unique filename
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const filename = `document_${timestamp}.pdf`;
      
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.setHeader('Content-Length', pdfBuffer.length);
      
      res.status(200).send(pdfBuffer);
    } catch (error) {
      throw new Error(`PDF generation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  })
);

// Generate advanced PDF with multiple text blocks and headings
router.post('/generate-advanced',
  [
    body('blocks').isArray({ min: 1 }).withMessage('At least one text block is required'),
    body('blocks.*.text').trim().isLength({ min: 1 }).withMessage('Text content is required for each block'),
    body('blocks.*.isHeading').optional().isBoolean().withMessage('isHeading must be a boolean'),
    body('blocks.*.headingLevel').optional().isIn([1, 2, 3]).withMessage('Heading level must be 1, 2, or 3'),
    body('blocks.*.style.fontSize').optional().isFloat({ min: 8, max: 24 }).withMessage('Font size must be between 8 and 24'),
    body('blocks.*.style.textAlign').optional().isIn(['left', 'center', 'right', 'justify']).withMessage('Invalid text alignment'),
    body('title').optional().isString().withMessage('Title must be a string'),
    body('author').optional().isString().withMessage('Author must be a string'),
  ],
  validateRequest([
    body('blocks').isArray({ min: 1 }),
    body('blocks.*.text').trim().isLength({ min: 1 }),
    body('blocks.*.isHeading').optional().isBoolean(),
    body('blocks.*.headingLevel').optional().isIn([1, 2, 3]),
    body('blocks.*.style.fontSize').optional().isFloat({ min: 8, max: 24 }),
    body('blocks.*.style.textAlign').optional().isIn(['left', 'center', 'right', 'justify']),
    body('title').optional().isString(),
    body('author').optional().isString(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    const { blocks, title, author } = req.body;

    try {
      // Prepare PDF generation options
      const options: PDFGenerationOptions = {
        title: title || 'QuickPDF Advanced Document',
        author: author || req.user?.email || 'QuickPDF User',
        pageSize: 'A4'
      };

      // Generate PDF with multiple blocks
      const pdfBuffer = await PDFService.generateFromBlocks(blocks, options);
      
      // Generate unique filename
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const filename = `advanced_document_${timestamp}.pdf`;
      
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.setHeader('Content-Length', pdfBuffer.length);
      
      res.status(200).send(pdfBuffer);
    } catch (error) {
      throw new Error(`Advanced PDF generation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  })
);

// Generate PDF from template
router.post('/generate-from-template',
  [
    body('templateId').isUUID().withMessage('Valid template ID is required'),
    body('userData').isObject().withMessage('User data must be an object'),
  ],
  validateRequest([
    body('templateId').isUUID(),
    body('userData').isObject(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Implement PDF generation from template
    const pdfBuffer = Buffer.from('Mock PDF content from template'); // Placeholder
    
    res.status(200).json({
      success: true,
      message: 'PDF generated from template successfully',
      data: {
        documentId: 'mock_template_document_id',
        filename: 'template_document.pdf',
        size: pdfBuffer.length,
        downloadUrl: '/api/v1/pdf/download/mock_template_document_id',
        templateId: req.body.templateId,
      },
    });
  })
);

// Download PDF
router.get('/download/:documentId',
  param('documentId').isUUID().withMessage('Invalid document ID'),
  validateRequest([param('documentId').isUUID()]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Get PDF from storage and stream to client
    const mockPdfBuffer = Buffer.from('Mock PDF content for download');
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="document.pdf"');
    res.setHeader('Content-Length', mockPdfBuffer.length);
    
    res.send(mockPdfBuffer);
  })
);

// Get user documents
router.get('/documents',
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Get user's documents from database
    const mockDocuments = [
      {
        id: 'doc_1',
        filename: 'izin_dilekçesi_2025.pdf',
        templateId: 'template_1',
        size: 1024,
        createdAt: new Date().toISOString(),
        downloadUrl: '/api/v1/pdf/download/doc_1',
      },
      {
        id: 'doc_2',
        filename: 'serbest_metin.pdf',
        templateId: null,
        size: 2048,
        createdAt: new Date().toISOString(),
        downloadUrl: '/api/v1/pdf/download/doc_2',
      },
    ];

    res.status(200).json({
      success: true,
      data: {
        documents: mockDocuments,
      },
    });
  })
);

// Delete document
router.delete('/documents/:documentId',
  param('documentId').isUUID().withMessage('Invalid document ID'),
  validateRequest([param('documentId').isUUID()]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Delete document from database and storage (check ownership)
    res.status(200).json({
      success: true,
      message: 'Document deleted successfully',
    });
  })
);

// Preview template with sample data
router.post('/preview-template',
  [
    body('templateId').isUUID().withMessage('Valid template ID is required'),
    body('sampleData').optional().isObject().withMessage('Sample data must be an object'),
  ],
  validateRequest([
    body('templateId').isUUID(),
    body('sampleData').optional().isObject(),
  ]),
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    // TODO: Generate preview PDF with sample data
    res.status(200).json({
      success: true,
      message: 'Template preview generated successfully',
      data: {
        previewUrl: '/api/v1/pdf/preview/mock_preview_id',
        expiresAt: new Date(Date.now() + 3600000).toISOString(), // 1 hour
      },
    });
  })
);

// Test Turkish character support
router.get('/test-turkish',
  asyncHandler(async (req: AuthenticatedRequest, res) => {
    try {
      const pdfBuffer = await PDFService.testTurkishCharacters();
      
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="turkish_test.pdf"');
      res.setHeader('Content-Length', pdfBuffer.length);
      
      res.status(200).send(pdfBuffer);
    } catch (error) {
      throw new Error(`Turkish character test failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  })
);

export default router;