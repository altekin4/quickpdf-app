import 'dart:convert';
import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  final String? filePath;
  final int? fileSize;
  final DateTime updatedAt;
  final bool isSynced;
  final String? serverId;
  final DateTime? lastSyncAttempt;

  const DocumentModel({
    required super.id,
    required super.userId,
    super.templateId,
    required super.filename,
    required super.content,
    super.fileUrl,
    required super.createdAt,
    this.filePath,
    this.fileSize,
    required this.updatedAt,
    this.isSynced = false,
    this.serverId,
    this.lastSyncAttempt,
  });

  // Convert from Document entity
  factory DocumentModel.fromEntity(Document document, {
    String? filePath,
    int? fileSize,
    DateTime? updatedAt,
    bool isSynced = false,
    String? serverId,
    DateTime? lastSyncAttempt,
  }) {
    return DocumentModel(
      id: document.id,
      userId: document.userId,
      templateId: document.templateId,
      filename: document.filename,
      content: document.content,
      fileUrl: document.fileUrl,
      createdAt: document.createdAt,
      filePath: filePath,
      fileSize: fileSize,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced,
      serverId: serverId,
      lastSyncAttempt: lastSyncAttempt,
    );
  }

  // Convert to Document entity
  Document toEntity() {
    return Document(
      id: id,
      userId: userId,
      templateId: templateId,
      filename: filename,
      content: content,
      fileUrl: fileUrl,
      createdAt: createdAt,
    );
  }

  // Convert from database map
  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      templateId: map['template_id'] as String?,
      filename: map['filename'] as String,
      content: map['content'] as String,
      fileUrl: map['file_url'] as String?,
      filePath: map['file_path'] as String?,
      fileSize: map['file_size'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isSynced: (map['is_synced'] as int?) == 1,
      serverId: map['server_id'] as String?,
      lastSyncAttempt: map['last_sync_attempt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_sync_attempt'] as int)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'template_id': templateId,
      'filename': filename,
      'content': content,
      'file_url': fileUrl,
      'file_path': filePath,
      'file_size': fileSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
      'server_id': serverId,
      'last_sync_attempt': lastSyncAttempt?.millisecondsSinceEpoch,
    };
  }

  // Convert from JSON
  factory DocumentModel.fromJson(dynamic json) {
    if (json is String) {
      final Map<String, dynamic> jsonMap = jsonDecode(json);
      return DocumentModel.fromMap(jsonMap);
    } else if (json is Map<String, dynamic>) {
      return DocumentModel.fromMap(json);
    } else {
      throw ArgumentError('Invalid JSON format for DocumentModel');
    }
  }

  // Convert to JSON
  String toJson() {
    return jsonEncode(toMap());
  }

  @override
  DocumentModel copyWith({
    String? id,
    String? userId,
    String? templateId,
    String? filename,
    String? content,
    String? fileUrl,
    DateTime? createdAt,
    String? filePath,
    int? fileSize,
    DateTime? updatedAt,
    bool? isSynced,
    String? serverId,
    DateTime? lastSyncAttempt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      filename: filename ?? this.filename,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      serverId: serverId ?? this.serverId,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentModel &&
        other.id == id &&
        other.userId == userId &&
        other.templateId == templateId &&
        other.filename == filename &&
        other.content == content &&
        other.fileUrl == fileUrl &&
        other.filePath == filePath &&
        other.fileSize == fileSize &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      templateId,
      filename,
      content,
      fileUrl,
      filePath,
      fileSize,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'DocumentModel(id: $id, filename: $filename, createdAt: $createdAt)';
  }
}