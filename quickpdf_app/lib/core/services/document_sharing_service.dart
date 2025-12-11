import 'dart:io';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/document.dart';

/// Share result enumeration
enum ShareResult {
  success,
  cancelled,
  failed
}

class DocumentSharingService {
  /// Share a document file using native sharing
  static Future<ShareResult> shareDocument(
    File file,
    Document document, {
    String? customText,
  }) async {
    final text = customText ?? 'PDF Belgesi: ${document.filename}';
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      subject: document.filename,
    );
    return ShareResult.success;
  }

  /// Share document via email specifically
  static Future<ShareResult> shareViaEmail(
    File file,
    Document document, {
    String? emailSubject,
    String? emailBody,
  }) async {
    final subject = emailSubject ?? document.filename;
    final body = emailBody ?? 'PDF belgesi ekte bulunmaktadır.\n\nOluşturulma tarihi: ${_formatDate(document.createdAt)}';
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: body,
      subject: subject,
    );
    return ShareResult.success;
  }

  /// Share document content as text (without PDF file)
  static Future<ShareResult> shareAsText(Document document) async {
    String shareText = 'Belge: ${document.filename}\n\n';
    shareText += 'İçerik:\n${document.content}\n\n';
    shareText += 'Oluşturulma tarihi: ${_formatDate(document.createdAt)}';
    
    await Share.share(shareText, subject: document.filename);
    return ShareResult.success;
  }

  /// Get available sharing options for the platform
  static List<SharingOption> getAvailableSharingOptions() {
    return [
      const SharingOption(
        id: 'native',
        title: 'Paylaş',
        description: 'Sistem paylaşım menüsünü kullan',
        icon: 'share',
      ),
      const SharingOption(
        id: 'email',
        title: 'E-posta',
        description: 'E-posta ile gönder',
        icon: 'email',
      ),
      const SharingOption(
        id: 'text',
        title: 'Metin Olarak',
        description: 'İçeriği metin olarak paylaş',
        icon: 'text_fields',
      ),
    ];
  }

  /// Check if file sharing is available
  static Future<bool> canShareFiles() async {
    try {
      // Try to share an empty file to check if sharing is available
      return true; // share_plus is generally available on mobile platforms
    } catch (e) {
      return false;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class SharingOption {
  final String id;
  final String title;
  final String description;
  final String icon;

  const SharingOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

enum ShareType {
  native,
  email,
  text,
}