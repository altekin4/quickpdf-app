import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const QuickPDFDemo());
}

class QuickPDFDemo extends StatelessWidget {
  const QuickPDFDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickPDF Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const DemoHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  String _status = 'PDF oluşturmaya hazır';

  @override
  void initState() {
    super.initState();
    _textController.text = '''Merhaba QuickPDF!

Bu bir demo uygulamasıdır. Türkçe karakterleri test edebilirsiniz:
çÇ, ğĞ, ıI, İi, öÖ, şŞ, üÜ

Özellikler:
• Türkçe karakter desteği
• Çevrimdışı PDF oluşturma
• Basit metin formatlaması
• Mobil cihaz uyumluluğu

Tarih: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Bu metin kutusunu düzenleyebilir ve PDF oluşturabilirsiniz.''';
  }

  Future<void> _generatePDF() async {
    if (_textController.text.trim().isEmpty) {
      _showMessage('Lütfen metin girin!');
      return;
    }

    setState(() {
      _isGenerating = true;
      _status = 'PDF oluşturuluyor...';
    });

    try {
      // PDF oluştur
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'QuickPDF Demo',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Paragraph(
                text: _textController.text,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Sayfa ${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          },
        ),
      );

      // PDF'i kaydet
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/quickpdf_demo_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _status = 'PDF başarıyla oluşturuldu: ${file.path}';
      });

      _showMessage('PDF oluşturuldu!\n${file.path}');
      
      // PDF'i paylaş
      await _sharePDF(file.path);

    } catch (e) {
      setState(() {
        _status = 'Hata: $e';
      });
      _showMessage('PDF oluşturulurken hata: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _sharePDF(String filePath) async {
    try {
      // Android'de dosyayı paylaş
      await _showShareDialog(filePath);
    } catch (e) {
      _showMessage('Paylaşım hatası: $e');
    }
  }

  Future<void> _showShareDialog(String filePath) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Oluşturuldu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF başarıyla oluşturuldu!'),
            const SizedBox(height: 10),
            Text(
              'Konum: $filePath',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text('PDF dosyasını dosya yöneticisinde bulabilirsiniz.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _copyPathToClipboard(filePath);
            },
            child: const Text('Yolu Kopyala'),
          ),
        ],
      ),
    );
  }

  void _copyPathToClipboard(String path) {
    Clipboard.setData(ClipboardData(text: path));
    _showMessage('Dosya yolu panoya kopyalandı');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _testTurkishCharacters() {
    _textController.text = '''Türkçe Karakter Testi

Bu test Türkçe karakterlerin PDF'te doğru görüntülenip görüntülenmediğini kontrol eder.

Türkçe Karakterler:
• Büyük harfler: Ç Ğ I İ Ö Ş Ü
• Küçük harfler: ç ğ ı i ö ş ü

Örnek Kelimeler:
çiçek, ağaç, ışık, öğretmen, şarkı, üzüm
ÇALIŞKAN, AĞIR, IŞIK, ÖĞRENCI, ŞEHIR, ÜLKE

Örnek Cümle:
"Güzel çiçekler açan ağaçların altında öğrenciler şarkı söylüyor."

Test Tarihi: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
Test Saati: ${DateTime.now().hour}:${DateTime.now().minute}

Bu test başarılı olursa, Türkçe karakterler PDF'te düzgün görünecektir.''';
    
    setState(() {
      _status = 'Türkçe karakter testi hazırlandı';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickPDF Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _testTurkishCharacters,
            tooltip: 'Türkçe Karakter Testi',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Durum göstergesi
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isGenerating ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isGenerating ? Colors.orange : Colors.green,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGenerating ? Icons.hourglass_empty : Icons.check_circle,
                    color: _isGenerating ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: _isGenerating ? Colors.orange.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Metin girişi
            const Text(
              'PDF İçeriği:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'PDF içeriğinizi buraya yazın...',
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generatePDF,
                    icon: _isGenerating 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(_isGenerating ? 'Oluşturuluyor...' : 'PDF Oluştur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _textController.clear();
                    setState(() {
                      _status = 'Metin temizlendi';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  child: const Icon(Icons.clear),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Bilgi metni
            const Text(
              'Not: PDF dosyası cihazınızın Documents klasörüne kaydedilecektir.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}