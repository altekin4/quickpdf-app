import 'dart:io';
import 'dart:typed_data';

import '../entities/document.dart';

abstract class DocumentRepository {
  /// Get all documents for a specific user (limited to last 50)
  Future<List<Document>> getAllDocuments(String userId);
  
  /// Get a specific document by ID
  Future<Document?> getDocumentById(String id);
  
  /// Save a new document with optional PDF data
  Future<String> saveDocument(Document document, Uint8List? pdfData);
  
  /// Update an existing document
  Future<void> updateDocument(Document document);
  
  /// Delete a document by ID
  Future<void> deleteDocument(String id);
  
  /// Search documents by query (filename or content)
  Future<List<Document>> searchDocuments(String userId, String query);
  
  /// Get the PDF file for a document
  Future<File?> getDocumentFile(String documentId);
  
  /// Get the total count of documents for a user
  Future<int> getDocumentCount(String userId);
  
  /// Clean up old documents to maintain the limit of 50
  Future<void> cleanupOldDocuments(String userId, {int maxDocuments = 50});
}