import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Service for generating PDFs locally without network connection
class OfflinePDFService {
  static const double _defaultMargin = 40.0;

  /// Generate PDF from plain text with formatting options
  static Future<Uint8List> generateFromText({
    required String text,
    int fontSize = 12,
    String alignment = 'left',
    bool bold = false,
    bool italic = false,
    String? title,
    String? author,
  }) async {
    final pdf = pw.Document();

    // Process text to replace date placeholders
    final processedText = _processDatePlaceholders(text);

    // Create text style
    final textStyle = pw.TextStyle(
      fontSize: fontSize.toDouble(),
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
    );

    // Determine text alignment
    final textAlign = _getTextAlignment(alignment);

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(_defaultMargin),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Paragraph(
              text: processedText,
              style: textStyle,
              textAlign: textAlign,
            ),
          ];
        },
        header: title != null
            ? (pw.Context context) {
                return pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }
            : null,
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (author != null)
                  pw.Text(
                    author,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                pw.Text(
                  'Sayfa ${context.pageNumber}/${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate advanced PDF with multiple text blocks and headings
  static Future<Uint8List> generateAdvanced({
    required List<Map<String, dynamic>> blocks,
    String? title,
    String? author,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(_defaultMargin),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];

          for (final block in blocks) {
            final widget = _buildBlockWidget(block);
            if (widget != null) {
              widgets.add(widget);
              widgets.add(pw.SizedBox(height: 10)); // Add spacing between blocks
            }
          }

          return widgets;
        },
        header: title != null
            ? (pw.Context context) {
                return pw.Container(
                  alignment: pw.Alignment.centerLeft,
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }
            : null,
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (author != null)
                  pw.Text(
                    author,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                pw.Text(
                  'Sayfa ${context.pageNumber}/${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate PDF from template with user data
  static Future<Uint8List> generateFromTemplate({
    required String templateBody,
    required Map<String, dynamic> userData,
    String? title,
    String? author,
  }) async {
    // Process template by replacing placeholders with user data
    String processedContent = templateBody;
    
    // Replace user data placeholders
    userData.forEach((key, value) {
      final placeholder = '{$key}';
      processedContent = processedContent.replaceAll(placeholder, value.toString());
    });

    // Process date placeholders
    processedContent = _processDatePlaceholders(processedContent);

    return generateFromText(
      text: processedContent,
      title: title,
      author: author,
    );
  }

  /// Test Turkish character support by generating a test PDF
  static Future<Uint8List> testTurkishCharacters() async {
    const testText = '''
Türkçe Karakter Testi

Bu PDF, Türkçe karakterlerin doğru şekilde görüntülenip görüntülenmediğini test etmek için oluşturulmuştur.

Türkçe Karakterler:
• Büyük harfler: Ç Ğ I İ Ö Ş Ü
• Küçük harfler: ç ğ ı i ö ş ü

Örnek Kelimeler:
• çiçek, ağaç, ışık, öğretmen, şarkı, üzüm
• ÇALIŞKAN, AĞIR, IŞIK, ÖĞRENCI, ŞEHIR, ÜLKE

Örnek Cümle:
"Güzel çiçekler açan ağaçların altında öğrenciler şarkı söylüyor."

Test Tarihi: \${DateTime.now().toString().substring(0, 16)}
''';

    return generateFromText(
      text: testText,
      title: 'Türkçe Karakter Testi',
      author: 'QuickPDF Sistemi',
      fontSize: 12,
    );
  }

  /// Process date placeholders in text
  static String _processDatePlaceholders(String text) {
    final now = DateTime.now();
    final turkishDateFormat = DateFormat('dd.MM.yyyy');
    final turkishDate = turkishDateFormat.format(now);

    return text
        .replaceAll('{TODAY}', turkishDate)
        .replaceAll('{BUGÜN}', turkishDate)
        .replaceAll('{TARİH}', turkishDate)
        .replaceAll('{today}', turkishDate)
        .replaceAll('{bugün}', turkishDate)
        .replaceAll('{tarih}', turkishDate);
  }

  /// Get text alignment from string
  static pw.TextAlign _getTextAlignment(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      case 'justify':
        return pw.TextAlign.justify;
      case 'left':
      default:
        return pw.TextAlign.left;
    }
  }

  /// Build widget from block data
  static pw.Widget? _buildBlockWidget(Map<String, dynamic> block) {
    final text = block['text'] as String?;
    if (text == null || text.isEmpty) return null;

    final processedText = _processDatePlaceholders(text);
    final isHeading = block['isHeading'] as bool? ?? false;

    if (isHeading) {
      final headingLevel = block['headingLevel'] as int? ?? 1;
      return _buildHeading(processedText, headingLevel);
    } else {
      final style = block['style'] as Map<String, dynamic>?;
      return _buildParagraph(processedText, style);
    }
  }

  /// Build heading widget
  static pw.Widget _buildHeading(String text, int level) {
    double fontSize;
    switch (level) {
      case 1:
        fontSize = 20;
        break;
      case 2:
        fontSize = 16;
        break;
      case 3:
        fontSize = 14;
        break;
      default:
        fontSize = 12;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20, bottom: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Build paragraph widget
  static pw.Widget _buildParagraph(String text, Map<String, dynamic>? style) {
    final fontSize = (style?['fontSize'] as int?)?.toDouble() ?? 12.0;
    final textAlign = _getTextAlignment(style?['textAlign'] as String? ?? 'left');
    final fontWeight = (style?['fontWeight'] as String?) == 'bold'
        ? pw.FontWeight.bold
        : pw.FontWeight.normal;
    final fontStyle = (style?['fontStyle'] as String?) == 'italic'
        ? pw.FontStyle.italic
        : pw.FontStyle.normal;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
        ),
        textAlign: textAlign,
      ),
    );
  }
}