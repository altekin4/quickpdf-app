import 'package:flutter/material.dart';
import '../../domain/entities/template.dart';
import 'dynamic_form_field.dart';

class DynamicForm extends StatefulWidget {
  final Template template;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic> data, bool isValid) onDataChanged;
  final bool showValidationErrors;

  const DynamicForm({
    super.key,
    required this.template,
    this.initialData = const {},
    required this.onDataChanged,
    this.showValidationErrors = false,
  });

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;
  Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _formData = Map.from(widget.initialData);
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    for (final entry in widget.template.placeholders.entries) {
      final key = entry.key;
      final config = entry.value;
      
      if (!_formData.containsKey(key) && config.defaultValue != null) {
        if (config.type == PlaceholderType.date && config.defaultValue == 'today') {
          _formData[key] = DateTime.now().toIso8601String().split('T')[0];
        } else {
          _formData[key] = config.defaultValue;
        }
      }
    }
    _validateAndNotify();
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      _fieldErrors[key] = null; // Clear error when user starts typing
    });
    _validateAndNotify();
  }

  void _validateAndNotify() {
    final errors = _validateFormData();
    final isValid = errors.isEmpty;
    
    if (widget.showValidationErrors) {
      setState(() {
        _fieldErrors = errors;
      });
    }
    
    widget.onDataChanged(_formData, isValid);
  }

  Map<String, String?> _validateFormData() {
    final errors = <String, String?>{};

    for (final entry in widget.template.placeholders.entries) {
      final key = entry.key;
      final config = entry.value;
      final value = _formData[key];

      // Check required fields
      if (config.required && (value == null || value.toString().isEmpty)) {
        errors[key] = '${config.label} zorunludur';
        continue;
      }

      // Skip validation for empty optional fields
      if (!config.required && (value == null || value.toString().isEmpty)) {
        continue;
      }

      // Type-specific validation
      final fieldError = _validateFieldValue(key, config, value);
      if (fieldError != null) {
        errors[key] = fieldError;
      }
    }

    return errors;
  }

  String? _validateFieldValue(String key, PlaceholderConfig config, dynamic value) {
    if (value == null) return null;

    final validation = config.validation;
    final stringValue = value.toString();

    // Length validation for text fields
    if (config.type == PlaceholderType.string ||
        config.type == PlaceholderType.text ||
        config.type == PlaceholderType.textarea) {
      if (validation?.minLength != null && stringValue.length < validation!.minLength!) {
        return '${config.label} en az ${validation.minLength} karakter olmalıdır';
      }
      if (validation?.maxLength != null && stringValue.length > validation!.maxLength!) {
        return '${config.label} en fazla ${validation.maxLength} karakter olmalıdır';
      }
    }

    // Number validation
    if (config.type == PlaceholderType.number) {
      final numValue = double.tryParse(stringValue);
      if (numValue == null) {
        return '${config.label} geçerli bir sayı olmalıdır';
      }
      if (validation?.minValue != null && numValue < validation!.minValue!) {
        return '${config.label} en az ${validation.minValue} olmalıdır';
      }
      if (validation?.maxValue != null && numValue > validation!.maxValue!) {
        return '${config.label} en fazla ${validation.maxValue} olmalıdır';
      }
    }

    // Pattern validation
    if (validation?.pattern != null) {
      final regex = RegExp(validation!.pattern!);
      if (!regex.hasMatch(stringValue)) {
        return '${config.label} formatı geçersiz';
      }
    }

    // Email validation
    if (config.type == PlaceholderType.email) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(stringValue)) {
        return 'Geçerli bir e-posta adresi giriniz';
      }
    }

    // Phone validation
    if (config.type == PlaceholderType.phone) {
      final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$');
      if (!phoneRegex.hasMatch(stringValue)) {
        return 'Geçerli bir telefon numarası giriniz';
      }
    }

    return null;
  }

  List<MapEntry<String, PlaceholderConfig>> _getSortedPlaceholders() {
    final entries = widget.template.placeholders.entries.toList();
    entries.sort((a, b) => a.value.order.compareTo(b.value.order));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template title and description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.template.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.template.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Form fields
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Form Bilgileri',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Dynamic form fields
                  ..._getSortedPlaceholders().map((entry) {
                    final key = entry.key;
                    final config = entry.value;
                    
                    return DynamicFormField(
                      fieldKey: key,
                      config: config,
                      value: _formData[key],
                      onChanged: _onFieldChanged,
                      errorText: widget.showValidationErrors ? _fieldErrors[key] : null,
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // Form progress indicator
          if (_formData.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalFields = widget.template.placeholders.length;
    final filledFields = _formData.entries
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .length;
    final progress = totalFields > 0 ? filledFields / totalFields : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Form İlerlemesi',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '$filledFields / $totalFields',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% tamamlandı',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // Public method to validate the form
  bool validateForm() {
    final errors = _validateFormData();
    setState(() {
      _fieldErrors = errors;
    });
    return errors.isEmpty;
  }

  // Public method to get form data
  Map<String, dynamic> getFormData() {
    return Map.from(_formData);
  }

  // Public method to reset form
  void resetForm() {
    setState(() {
      _formData.clear();
      _fieldErrors.clear();
    });
    _initializeDefaultValues();
  }
}