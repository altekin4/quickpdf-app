import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentRepository _documentRepository;
  
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  DocumentProvider(this._documentRepository);

  List<Document> get documents => _searchQuery.isEmpty ? _documents : _filteredDocuments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadDocuments(String userId) async {
    setLoading(true);
    setError(null);

    try {
      _documents = await _documentRepository.getAllDocuments(userId);
      
      // If there's an active search, update filtered results
      if (_searchQuery.isNotEmpty) {
        await searchDocuments(userId, _searchQuery);
      }
    } catch (e) {
      setError('Belgeler yüklenirken hata oluştu: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveDocument(Document document, Uint8List? pdfData) async {
    try {
      setError(null);
      await _documentRepository.saveDocument(document, pdfData);
      
      // Reload documents to reflect changes
      await loadDocuments(document.userId);
    } catch (e) {
      setError('Belge kaydedilirken hata oluştu: $e');
    }
  }

  Future<void> deleteDocument(String documentId, String userId) async {
    try {
      setError(null);
      await _documentRepository.deleteDocument(documentId);
      
      // Reload documents to reflect changes
      await loadDocuments(userId);
    } catch (e) {
      setError('Belge silinirken hata oluştu: $e');
    }
  }

  Future<void> searchDocuments(String userId, String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredDocuments = [];
      notifyListeners();
      return;
    }

    try {
      setError(null);
      _filteredDocuments = await _documentRepository.searchDocuments(userId, query);
      notifyListeners();
    } catch (e) {
      setError('Arama yapılırken hata oluştu: $e');
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredDocuments = [];
    notifyListeners();
  }

  Future<Document?> getDocumentById(String id) async {
    try {
      return await _documentRepository.getDocumentById(id);
    } catch (e) {
      setError('Belge alınırken hata oluştu: $e');
      return null;
    }
  }

  Future<File?> getDocumentFile(String documentId) async {
    try {
      return await _documentRepository.getDocumentFile(documentId);
    } catch (e) {
      setError('Belge dosyası alınırken hata oluştu: $e');
      return null;
    }
  }

  Future<int> getDocumentCount(String userId) async {
    try {
      return await _documentRepository.getDocumentCount(userId);
    } catch (e) {
      setError('Belge sayısı alınırken hata oluştu: $e');
      return 0;
    }
  }
}