import 'package:flutter_test/flutter_test.dart';
import 'package:quickpdf_app/core/services/offline_pdf_service.dart';

void main() {
  group('Offline PDF Service Tests', () {
    test('should generate PDF from plain text', () async {
      // Arrange
      const testText = 'Bu bir test metnidir. Türkçe karakterler: çğıöşü';
      
      // Act
      final pdfBytes = await OfflinePDFService.generateFromText(
        text: testText,
        fontSize: 12,
        alignment: 'left',
        title: 'Test PDF',
        author: 'Test User',
      );
      
      // Assert
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });

    test('should generate PDF with Turkish characters', () async {
      // Act
      final pdfBytes = await OfflinePDFService.testTurkishCharacters();
      
      // Assert
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });

    test('should process date placeholders', () async {
      // Arrange
      const testText = 'Bugünün tarihi: {TODAY}';
      
      // Act
      final pdfBytes = await OfflinePDFService.generateFromText(
        text: testText,
        fontSize: 12,
      );
      
      // Assert
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });

    test('should generate advanced PDF with blocks', () async {
      // Arrange
      final blocks = [
        {
          'text': 'Başlık 1',
          'isHeading': true,
          'headingLevel': 1,
        },
        {
          'text': 'Bu bir paragraftır.',
          'isHeading': false,
          'style': {
            'fontSize': 12,
            'textAlign': 'left',
          },
        },
      ];
      
      // Act
      final pdfBytes = await OfflinePDFService.generateAdvanced(
        blocks: blocks,
        title: 'Advanced Test PDF',
      );
      
      // Assert
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });

    test('should generate PDF from template', () async {
      // Arrange
      const templateBody = 'Merhaba {name}, bugün {TODAY} tarihinde mektup yazıyorum.';
      final userData = {
        'name': 'Ahmet',
      };
      
      // Act
      final pdfBytes = await OfflinePDFService.generateFromTemplate(
        templateBody: templateBody,
        userData: userData,
      );
      
      // Assert
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });
  });
}