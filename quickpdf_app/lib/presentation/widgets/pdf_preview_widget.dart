import 'package:flutter/material.dart';


class PdfPreviewWidget extends StatefulWidget {
  final String? templateId;
  final Map<String, dynamic>? previewData;
  final String? content;

  const PdfPreviewWidget({
    super.key,
    this.templateId,
    this.previewData,
    this.content,
  });

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  String? _previewContent;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  Future<void> _generatePreview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.content != null) {
        // Direct content preview
        setState(() {
          _previewContent = widget.content;
          _isLoading = false;
        });
      } else if (widget.templateId != null && widget.previewData != null) {
        // Template-based preview
        // final pdfProvider = context.read<PDFProvider>();
        // For preview, we'll just generate mock content
        // In a real implementation, you'd get the template first
        // Mock success for preview
        setState(() {
          _previewContent = _generateMockPreview();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Önizleme için gerekli veriler eksik';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  String _generateMockPreview() {
    if (widget.previewData == null) return 'Önizleme mevcut değil';
    
    final data = widget.previewData!;
    final buffer = StringBuffer();
    
    buffer.writeln('PDF ÖNIZLEME');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    data.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    buffer.writeln();
    buffer.writeln('Bu bir önizlemedir. Gerçek PDF farklı görünebilir.');
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'PDF Önizleme',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generatePreview,
                  tooltip: 'Yenile',
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Önizleme oluşturuluyor...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generatePreview,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_previewContent == null) {
      return const Center(
        child: Text('Önizleme mevcut değil'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          _previewContent!,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}