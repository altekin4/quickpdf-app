import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/document_model.dart';
import 'database_helper.dart';

abstract class DocumentLocalDataSource {
  Future<List<DocumentModel>> getAllDocuments(String userId);
  Future<DocumentModel?> getDocumentById(String id);
  Future<String> saveDocument(DocumentModel document, Uint8List? pdfData);
  Future<void> updateDocument(DocumentModel document);
  Future<void> deleteDocument(String id);
  Future<List<DocumentModel>> searchDocuments(String userId, String query);
  Future<void> cleanupOldDocuments(String userId, {int maxDocuments = 50});
  Future<File?> getDocumentFile(String filePath);
  Future<int> getDocumentCount(String userId);
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final DatabaseHelper _databaseHelper;

  DocumentLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<List<DocumentModel>> getAllDocuments(String userId) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.documentsTable,
      where: '${DatabaseHelper.columnUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
      limit: 50, // Limit to last 50 documents as per requirements
    );

    return maps.map((map) => DocumentModel.fromMap(map)).toList();
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.documentsTable,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DocumentModel.fromMap(maps.first);
  }

  @override
  Future<String> saveDocument(DocumentModel document, Uint8List? pdfData) async {
    final db = await _databaseHelper.database;
    
    // Save PDF file to local storage if provided
    String? filePath;
    int? fileSize;
    
    if (pdfData != null) {
      final directory = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${directory.path}/documents');
      
      // Create documents directory if it doesn't exist
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${document.id}_$timestamp.pdf';
      filePath = '${documentsDir.path}/$fileName';
      
      // Write PDF data to file
      final file = File(filePath);
      await file.writeAsBytes(pdfData);
      fileSize = pdfData.length;
    }

    // Create document with file path and size
    final documentWithFile = document.copyWith(
      filePath: filePath,
      fileSize: fileSize,
      updatedAt: DateTime.now(),
    );

    // Insert into database
    await db.insert(
      DatabaseHelper.documentsTable,
      documentWithFile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Clean up old documents to maintain limit of 50
    await cleanupOldDocuments(document.userId);

    return filePath ?? '';
  }

  @override
  Future<void> updateDocument(DocumentModel document) async {
    final db = await _databaseHelper.database;
    
    final updatedDocument = document.copyWith(updatedAt: DateTime.now());
    
    await db.update(
      DatabaseHelper.documentsTable,
      updatedDocument.toMap(),
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [document.id],
    );
  }

  @override
  Future<void> deleteDocument(String id) async {
    final db = await _databaseHelper.database;
    
    // Get document to delete associated file
    final document = await getDocumentById(id);
    if (document?.filePath != null) {
      final file = File(document!.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    // Delete from database
    await db.delete(
      DatabaseHelper.documentsTable,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<DocumentModel>> searchDocuments(String userId, String query) async {
    final db = await _databaseHelper.database;
    
    if (query.isEmpty) {
      return getAllDocuments(userId);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.documentsTable,
      where: '''
        ${DatabaseHelper.columnUserId} = ? AND (
          ${DatabaseHelper.columnFilename} LIKE ? OR 
          ${DatabaseHelper.columnContent} LIKE ?
        )
      ''',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
    );

    return maps.map((map) => DocumentModel.fromMap(map)).toList();
  }

  @override
  Future<void> cleanupOldDocuments(String userId, {int maxDocuments = 50}) async {
    final db = await _databaseHelper.database;
    
    // Get count of documents for user
    final count = await getDocumentCount(userId);
    
    if (count <= maxDocuments) return;
    
    // Get documents to delete (oldest ones beyond the limit)
    final documentsToDelete = await db.query(
      DatabaseHelper.documentsTable,
      where: '${DatabaseHelper.columnUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
      limit: count - maxDocuments,
      offset: maxDocuments,
    );
    
    // Delete files and database records
    for (final docMap in documentsToDelete) {
      final document = DocumentModel.fromMap(docMap);
      
      // Delete associated file
      if (document.filePath != null) {
        final file = File(document.filePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Delete from database
      await db.delete(
        DatabaseHelper.documentsTable,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [document.id],
      );
    }
  }

  @override
  Future<File?> getDocumentFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  @override
  Future<int> getDocumentCount(String userId) async {
    final db = await _databaseHelper.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.documentsTable} WHERE ${DatabaseHelper.columnUserId} = ?',
      [userId],
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }
}