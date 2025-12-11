import 'dart:typed_data';
import 'dart:io';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/local/document_local_datasource.dart';
import '../models/document_model.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource _localDataSource;

  DocumentRepositoryImpl(this._localDataSource);

  @override
  Future<List<Document>> getAllDocuments(String userId) async {
    try {
      final documentModels = await _localDataSource.getAllDocuments(userId);
      return documentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    try {
      final documentModel = await _localDataSource.getDocumentById(id);
      return documentModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  @override
  Future<String> saveDocument(Document document, Uint8List? pdfData) async {
    try {
      final documentModel = DocumentModel.fromEntity(document);
      return await _localDataSource.saveDocument(documentModel, pdfData);
    } catch (e) {
      throw Exception('Failed to save document: $e');
    }
  }

  @override
  Future<void> updateDocument(Document document) async {
    try {
      final documentModel = DocumentModel.fromEntity(document);
      await _localDataSource.updateDocument(documentModel);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      await _localDataSource.deleteDocument(id);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  @override
  Future<List<Document>> searchDocuments(String userId, String query) async {
    try {
      final documentModels = await _localDataSource.searchDocuments(userId, query);
      return documentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search documents: $e');
    }
  }

  @override
  Future<File?> getDocumentFile(String documentId) async {
    try {
      final documentModel = await _localDataSource.getDocumentById(documentId);
      if (documentModel?.filePath != null) {
        return await _localDataSource.getDocumentFile(documentModel!.filePath!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get document file: $e');
    }
  }

  @override
  Future<int> getDocumentCount(String userId) async {
    try {
      return await _localDataSource.getDocumentCount(userId);
    } catch (e) {
      throw Exception('Failed to get document count: $e');
    }
  }

  @override
  Future<void> cleanupOldDocuments(String userId, {int maxDocuments = 50}) async {
    try {
      await _localDataSource.cleanupOldDocuments(userId, maxDocuments: maxDocuments);
    } catch (e) {
      throw Exception('Failed to cleanup old documents: $e');
    }
  }
}