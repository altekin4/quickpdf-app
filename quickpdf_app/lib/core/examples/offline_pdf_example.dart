import 'dart:typed_data';
import '../services/offline_pdf_service.dart';

/// Example usage of offline PDF generation
class OfflinePDFExample {
  /// Generate a simple text PDF
  static Future<Uint8List> generateSimpleTextPDF() async {
    const text = '''
Merhaba Dünya!

Bu PDF çevrimdışı modda oluşturulmuştur.

Türkçe karakterler test:
• çiçek, ağaç, ışık
• öğretmen, şarkı, üzüm
• ÇALIŞKAN, AĞIR, IŞIK

Bugünün tarihi: {TODAY}

Bu örnek, QuickPDF uygulamasının internet bağlantısı olmadan da 
PDF oluşturabileceğini göstermektedir.
''';

    return await OfflinePDFService.generateFromText(
      text: text,
      fontSize: 12,
      alignment: 'left',
      title: 'Çevrimdışı PDF Örneği',
      author: 'QuickPDF Sistemi',
    );
  }

  /// Generate an advanced PDF with multiple blocks
  static Future<Uint8List> generateAdvancedPDF() async {
    final blocks = [
      {
        'text': 'Çevrimdışı PDF Oluşturma',
        'isHeading': true,
        'headingLevel': 1,
      },
      {
        'text': 'Giriş',
        'isHeading': true,
        'headingLevel': 2,
      },
      {
        'text': 'QuickPDF uygulaması, internet bağlantısı olmadan da PDF oluşturabilir. Bu özellik sayesinde kullanıcılar her zaman belgelerini oluşturabilir.',
        'isHeading': false,
        'style': {
          'fontSize': 12,
          'textAlign': 'justify',
        },
      },
      {
        'text': 'Özellikler',
        'isHeading': true,
        'headingLevel': 2,
      },
      {
        'text': '• Türkçe karakter desteği\n• Otomatik tarih ekleme\n• Çeşitli yazı stilleri\n• Farklı hizalama seçenekleri',
        'isHeading': false,
        'style': {
          'fontSize': 11,
          'textAlign': 'left',
        },
      },
      {
        'text': 'Sonuç',
        'isHeading': true,
        'headingLevel': 2,
      },
      {
        'text': 'Çevrimdışı PDF oluşturma özelliği, kullanıcı deneyimini önemli ölçüde iyileştirir ve uygulamanın her koşulda kullanılabilir olmasını sağlar.',
        'isHeading': false,
        'style': {
          'fontSize': 12,
          'textAlign': 'justify',
          'fontStyle': 'italic',
        },
      },
    ];

    return await OfflinePDFService.generateAdvanced(
      blocks: blocks,
      title: 'Gelişmiş Çevrimdışı PDF',
      author: 'QuickPDF Geliştirici Ekibi',
    );
  }

  /// Generate PDF from template
  static Future<Uint8List> generateTemplatePDF() async {
    const templateBody = '''
Sayın {recipient},

{TODAY} tarihinde {subject} konusunda size yazıyorum.

{content}

Saygılarımla,
{sender}
{title}
''';

    final userData = {
      'recipient': 'Müdür Bey',
      'subject': 'İzin Talebi',
      'content': 'Yıllık izin talebimde bulunmak istiyorum. 15-30 Haziran tarihleri arasında izin kullanmayı planlıyorum.',
      'sender': 'Ahmet Yılmaz',
      'title': 'Yazılım Geliştirici',
    };

    return await OfflinePDFService.generateFromTemplate(
      templateBody: templateBody,
      userData: userData,
      title: 'İzin Talebi',
      author: 'Ahmet Yılmaz',
    );
  }
}