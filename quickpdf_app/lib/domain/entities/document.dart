class Document {
  final String id;
  final String userId;
  final String? templateId;
  final String filename;
  final String content; // JSON serialized user data
  final String? fileUrl;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.userId,
    this.templateId,
    required this.filename,
    required this.content,
    this.fileUrl,
    required this.createdAt,
  });

  Document copyWith({
    String? id,
    String? userId,
    String? templateId,
    String? filename,
    String? content,
    String? fileUrl,
    DateTime? createdAt,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      filename: filename ?? this.filename,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isFromTemplate => templateId != null;
  bool get isPlainText => templateId == null;
}