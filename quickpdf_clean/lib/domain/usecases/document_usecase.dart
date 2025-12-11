import 'dart:io';
import 'dart:typed_data';

import '../entities/document.dart';
import '../repositories/document_repository.dart';

class DocumentUseCase {
  final DocumentRepository _repository;

  DocumentUseCase(this._repository);

  /// Get all documents for a user
  Future<List<Document>> getAllDocuments(String userId) async {
    return await _repository.getAllDocuments(userId);
  }

  /// Get a specific document by ID
  Future<Document?> getDocumentById(String id) async {
    return await _repository.getDocumentById(id);
  }

  /// Save a new document
  Future<String> saveDocument(Document document, Uint8List? pdfData) async {
    return await _repository.saveDocument(document, pdfData);
  }

  /// Update an existing document
  Future<void> updateDocument(Document document) async {
    await _repository.updateDocument(document);
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id);
  }

  /// Search documents by query
  Future<List<Document>> searchDocuments(String userId, String query) async {
    return await _repository.searchDocuments(userId, query);
  }

  /// Get the PDF file for sharing
  Future<File?> getDocumentFile(String documentId) async {
    return await _repository.getDocumentFile(documentId);
  }

  /// Get document count for a user
  Future<int> getDocumentCount(String userId) async {
    return await _repository.getDocumentCount(userId);
  }

  /// Clean up old documents to maintain limit
  Future<void> cleanupOldDocuments(String userId, {int maxDocuments = 50}) async {
    await _repository.cleanupOldDocuments(userId, maxDocuments: maxDocuments);
  }

  /// Check if a document can be shared
  bool canShareDocument(Document document) {
    return document.filename.isNotEmpty && document.content.isNotEmpty;
  }

  /// Check if a document can be reopened for editing
  bool canReopenDocument(Document document) {
    return document.content.isNotEmpty;
  }

  /// Get sharing text for a document
  String getShareText(Document document) {
    return 'PDF Belgesi: ${document.filename}';
  }

  /// Get export filename for a document
  String getExportFilename(Document document) {
    String filename = document.filename;
    if (!filename.toLowerCase().endsWith('.pdf')) {
      filename += '.pdf';
    }
    return filename;
  }
}