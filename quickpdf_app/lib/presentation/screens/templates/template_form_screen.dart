import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/template.dart';
import '../../widgets/dynamic_form.dart';
import '../../providers/pdf_provider.dart';

class TemplateFormScreen extends StatefulWidget {
  final Template template;

  const TemplateFormScreen({
    super.key,
    required this.template,
  });

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  bool _isFormValid = false;
  bool _showValidationErrors = false;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _isFormValid ? _showPreview : null,
            tooltip: 'Önizleme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DynamicForm(
              key: _formKey,
              template: widget.template,
              onDataChanged: _onFormDataChanged,
              showValidationErrors: _showValidationErrors,
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  void _onFormDataChanged(Map<String, dynamic> data, bool isValid) {
    setState(() {
      _formData = data;
      _isFormValid = isValid;
    });
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            child: const Text('Temizle'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _isFormValid ? _showPreview : null,
            child: const Text('Önizleme'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generatePDF,
            child: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('PDF Oluştur'),
          ),
        ),
      ],
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _showValidationErrors = false;
      _formData.clear();
    });
  }

  void _showPreview() {
    if (!_isFormValid) {
      setState(() {
        _showValidationErrors = true;
      });
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _PreviewDialog(
        template: widget.template,
        formData: _formData,
      ),
    );
  }

  Future<void> _generatePDF() async {
    // Validate form first
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() {
        _showValidationErrors = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm zorunlu alanları doldurunuz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final pdfProvider = Provider.of<PDFProvider>(context, listen: false);
      
      // Generate PDF from template
      final pdfFile = await pdfProvider.generatePdf(
        template: widget.template,
        userData: _formData,
      );

      if (pdfFile == null) {
        throw Exception(pdfProvider.error ?? 'PDF oluşturulamadı');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back or to document list
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }


}

class _PreviewDialog extends StatelessWidget {
  final Template template;
  final Map<String, dynamic> formData;

  const _PreviewDialog({
    required this.template,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    final processedContent = _processContent();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Önizleme',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    processedContent,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _processContent() {
    String processedContent = template.body;
    
    for (final entry in formData.entries) {
      final key = entry.key;
      final value = entry.value;
      final config = template.placeholders[key];
      
      if (config != null) {
        final formattedValue = _formatValueForTemplate(value, config);
        processedContent = processedContent.replaceAll('{$key}', formattedValue);
      }
    }
    
    return processedContent;
  }

  String _formatValueForTemplate(dynamic value, PlaceholderConfig config) {
    if (value == null) return '';

    switch (config.type) {
      case PlaceholderType.date:
        final date = DateTime.tryParse(value.toString());
        if (date != null) {
          return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
        }
        return value.toString();

      case PlaceholderType.checkbox:
        return value == true ? 'Evet' : 'Hayır';

      case PlaceholderType.number:
        return value.toString();

      default:
        return value.toString();
    }
  }
}