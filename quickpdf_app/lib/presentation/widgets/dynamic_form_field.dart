import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/template.dart';

class DynamicFormField extends StatefulWidget {
  final String fieldKey;
  final PlaceholderConfig config;
  final dynamic value;
  final Function(String key, dynamic value) onChanged;
  final String? errorText;

  const DynamicFormField({
    super.key,
    required this.fieldKey,
    required this.config,
    this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<DynamicFormField> createState() => _DynamicFormFieldState();
}

class _DynamicFormFieldState extends State<DynamicFormField> {
  late TextEditingController _controller;
  DateTime? _selectedDate;
  bool _checkboxValue = false;
  String? _selectedRadioValue;
  String? _selectedDropdownValue;

  @override
  void initState() {
    super.initState();
    _initializeField();
  }

  void _initializeField() {
    switch (widget.config.type) {
      case PlaceholderType.string:
      case PlaceholderType.text:
      case PlaceholderType.textarea:
      case PlaceholderType.email:
      case PlaceholderType.phone:
      case PlaceholderType.number:
        _controller = TextEditingController(
          text: widget.value?.toString() ?? widget.config.defaultValue?.toString() ?? ''
        );
        break;
      case PlaceholderType.date:
        if (widget.value != null) {
          _selectedDate = DateTime.tryParse(widget.value.toString());
        } else if (widget.config.defaultValue == 'today') {
          _selectedDate = DateTime.now();
          widget.onChanged(widget.fieldKey, _selectedDate!.toIso8601String().split('T')[0]);
        }
        _controller = TextEditingController(
          text: _selectedDate?.toLocal().toString().split(' ')[0] ?? ''
        );
        break;
      case PlaceholderType.checkbox:
        _checkboxValue = widget.value == true || widget.config.defaultValue == true;
        widget.onChanged(widget.fieldKey, _checkboxValue);
        break;
      case PlaceholderType.radio:
        _selectedRadioValue = widget.value?.toString() ?? widget.config.defaultValue?.toString();
        if (_selectedRadioValue != null) {
          widget.onChanged(widget.fieldKey, _selectedRadioValue);
        }
        break;
      case PlaceholderType.select:
        _selectedDropdownValue = widget.value?.toString() ?? widget.config.defaultValue?.toString();
        if (_selectedDropdownValue != null) {
          widget.onChanged(widget.fieldKey, _selectedDropdownValue);
        }
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(),
          const SizedBox(height: 8),
          _buildField(),
          if (widget.errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        text: widget.config.label,
        style: Theme.of(context).textTheme.labelMedium,
        children: [
          if (widget.config.required)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField() {
    switch (widget.config.type) {
      case PlaceholderType.string:
      case PlaceholderType.email:
      case PlaceholderType.phone:
        return _buildTextFormField();
      case PlaceholderType.text:
      case PlaceholderType.textarea:
        return _buildTextAreaField();
      case PlaceholderType.number:
        return _buildNumberField();
      case PlaceholderType.date:
        return _buildDateField();
      case PlaceholderType.select:
        return _buildDropdownField();
      case PlaceholderType.radio:
        return _buildRadioField();
      case PlaceholderType.checkbox:
        return _buildCheckboxField();
    }
  }

  Widget _buildTextFormField() {
    return TextFormField(
      controller: _controller,
      keyboardType: _getKeyboardType(),
      inputFormatters: _getInputFormatters(),
      decoration: InputDecoration(
        hintText: _getHintText(),
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
      ),
      onChanged: (value) {
        widget.onChanged(widget.fieldKey, value);
      },
      validator: (value) => _validateField(value),
    );
  }

  Widget _buildTextAreaField() {
    return TextFormField(
      controller: _controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: _getHintText(),
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
      ),
      onChanged: (value) {
        widget.onChanged(widget.fieldKey, value);
      },
      validator: (value) => _validateField(value),
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))],
      decoration: InputDecoration(
        hintText: 'Sayı giriniz',
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
      ),
      onChanged: (value) {
        final numValue = double.tryParse(value);
        widget.onChanged(widget.fieldKey, numValue);
      },
      validator: (value) => _validateField(value),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Tarih seçiniz',
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        errorText: widget.errorText,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            _controller.text = date.toLocal().toString().split(' ')[0];
          });
          widget.onChanged(widget.fieldKey, date.toIso8601String().split('T')[0]);
        }
      },
      validator: (value) => _validateField(value),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDropdownValue,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        errorText: widget.errorText,
      ),
      hint: const Text('Seçiniz'),
      items: widget.config.options?.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDropdownValue = value;
        });
        widget.onChanged(widget.fieldKey, value);
      },
      validator: (value) => _validateField(value),
    );
  }

  Widget _buildRadioField() {
    return Column(
      children: widget.config.options?.map((option) {
        final isSelected = _selectedRadioValue == option;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedRadioValue = option;
            });
            widget.onChanged(widget.fieldKey, option);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(option)),
              ],
            ),
          ),
        );
      }).toList() ?? [],
    );
  }

  Widget _buildCheckboxField() {
    return CheckboxListTile(
      title: Text(widget.config.label),
      value: _checkboxValue,
      onChanged: (value) {
        setState(() {
          _checkboxValue = value ?? false;
        });
        widget.onChanged(widget.fieldKey, _checkboxValue);
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  TextInputType _getKeyboardType() {
    switch (widget.config.type) {
      case PlaceholderType.email:
        return TextInputType.emailAddress;
      case PlaceholderType.phone:
        return TextInputType.phone;
      case PlaceholderType.number:
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (widget.config.type) {
      case PlaceholderType.phone:
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]'))];
      case PlaceholderType.number:
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))];
      default:
        return [];
    }
  }

  String _getHintText() {
    switch (widget.config.type) {
      case PlaceholderType.email:
        return 'E-posta adresinizi giriniz';
      case PlaceholderType.phone:
        return 'Telefon numaranızı giriniz';
      case PlaceholderType.number:
        return 'Sayı giriniz';
      case PlaceholderType.string:
        return '${widget.config.label} giriniz';
      case PlaceholderType.text:
      case PlaceholderType.textarea:
        return '${widget.config.label} giriniz';
      default:
        return '';
    }
  }

  String? _validateField(dynamic value) {
    if (widget.config.required && (value == null || value.toString().isEmpty)) {
      return '${widget.config.label} zorunludur';
    }

    if (value == null || value.toString().isEmpty) {
      return null; // Optional field, no validation needed
    }

    final validation = widget.config.validation;
    if (validation == null) return null;

    final stringValue = value.toString();

    // Length validation for text fields
    if (widget.config.type == PlaceholderType.string ||
        widget.config.type == PlaceholderType.text ||
        widget.config.type == PlaceholderType.textarea) {
      if (validation.minLength != null && stringValue.length < validation.minLength!) {
        return '${widget.config.label} en az ${validation.minLength} karakter olmalıdır';
      }
      if (validation.maxLength != null && stringValue.length > validation.maxLength!) {
        return '${widget.config.label} en fazla ${validation.maxLength} karakter olmalıdır';
      }
    }

    // Number validation
    if (widget.config.type == PlaceholderType.number) {
      final numValue = double.tryParse(stringValue);
      if (numValue == null) {
        return '${widget.config.label} geçerli bir sayı olmalıdır';
      }
      if (validation.minValue != null && numValue < validation.minValue!) {
        return '${widget.config.label} en az ${validation.minValue} olmalıdır';
      }
      if (validation.maxValue != null && numValue > validation.maxValue!) {
        return '${widget.config.label} en fazla ${validation.maxValue} olmalıdır';
      }
    }

    // Pattern validation
    if (validation.pattern != null) {
      final regex = RegExp(validation.pattern!);
      if (!regex.hasMatch(stringValue)) {
        return '${widget.config.label} formatı geçersiz';
      }
    }

    // Email validation
    if (widget.config.type == PlaceholderType.email) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(stringValue)) {
        return 'Geçerli bir e-posta adresi giriniz';
      }
    }

    // Phone validation
    if (widget.config.type == PlaceholderType.phone) {
      final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$');
      if (!phoneRegex.hasMatch(stringValue)) {
        return 'Geçerli bir telefon numarası giriniz';
      }
    }

    return null;
  }
}