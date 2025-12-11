class Template {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String body;
  final Map<String, PlaceholderConfig> placeholders;
  final String createdBy;
  final double price;
  final TemplateStatus status;
  final bool isVerified;
  final bool isFeatured;
  final double rating;
  final int totalRatings;
  final int downloadCount;
  final int purchaseCount;
  final String version;
  final String? previewImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isCached;

  const Template({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.body,
    required this.placeholders,
    required this.createdBy,
    required this.price,
    required this.status,
    required this.isVerified,
    required this.isFeatured,
    required this.rating,
    required this.totalRatings,
    required this.downloadCount,
    required this.purchaseCount,
    required this.version,
    this.previewImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isCached,
  });

  bool get isFree => price == 0.0;
  bool get isPaid => price > 0.0;
  bool get isPublished => status == TemplateStatus.published;
}

class PlaceholderConfig {
  final PlaceholderType type;
  final String label;
  final bool required;
  final ValidationRules? validation;
  final dynamic defaultValue;
  final List<String>? options; // for select type
  final int order;

  const PlaceholderConfig({
    required this.type,
    required this.label,
    required this.required,
    this.validation,
    this.defaultValue,
    this.options,
    required this.order,
  });
}

class ValidationRules {
  final int? minLength;
  final int? maxLength;
  final double? minValue;
  final double? maxValue;
  final String? pattern;

  const ValidationRules({
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.pattern,
  });
}

enum PlaceholderType {
  string,
  text,
  textarea,
  date,
  number,
  phone,
  email,
  select,
  checkbox,
  radio;

  String get displayName {
    switch (this) {
      case PlaceholderType.string:
        return 'Metin';
      case PlaceholderType.text:
        return 'Çok Satırlı Metin';
      case PlaceholderType.textarea:
        return 'Uzun Metin';
      case PlaceholderType.date:
        return 'Tarih';
      case PlaceholderType.number:
        return 'Sayı';
      case PlaceholderType.phone:
        return 'Telefon';
      case PlaceholderType.email:
        return 'E-posta';
      case PlaceholderType.select:
        return 'Seçim Listesi';
      case PlaceholderType.checkbox:
        return 'Onay Kutusu';
      case PlaceholderType.radio:
        return 'Tek Seçim';
    }
  }
}

enum TemplateStatus {
  draft,
  pending,
  published,
  rejected,
  archived;

  String get displayName {
    switch (this) {
      case TemplateStatus.draft:
        return 'Taslak';
      case TemplateStatus.pending:
        return 'İnceleme Bekliyor';
      case TemplateStatus.published:
        return 'Yayınlandı';
      case TemplateStatus.rejected:
        return 'Reddedildi';
      case TemplateStatus.archived:
        return 'Arşivlendi';
    }
  }
}