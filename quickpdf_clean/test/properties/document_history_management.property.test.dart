/// **Feature: quickpdf-template-marketplace, Property 5: Document History Management**
/// **Validates: Requirements 4.1, 4.5**
/// 
/// Property-based tests for document history management.
/// Tests that the system maintains exactly the last 50 documents with complete metadata.
library;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:quickpdf_app/data/datasources/local/database_helper.dart';
import 'package:quickpdf_app/data/datasources/local/document_local_datasource.dart';
import 'package:quickpdf_app/data/models/document_model.dart';

void main() {
  group('Document History Management Property Tests', () {
    late DatabaseHelper databaseHelper;
    late DocumentLocalDataSourceImpl dataSource;
    const uuid = Uuid();
    final random = Random();

    setUp(() async {
      databaseHelper = DatabaseHelper.instance;
      dataSource = DocumentLocalDataSourceImpl(databaseHelper);
      
      // Clean up database before each test
      await databaseHelper.deleteDatabase();
    });

    tearDown(() async {
      await databaseHelper.deleteDatabase();
    });

    /**
     * Feature: quickpdf-template-marketplace, Property 5: Document History Management
     * For any sequence of document creation operations, the system should maintain exactly the last 50 documents with complete metadata
     * Validates: Requirements 4.1, 4.5
     */
    test('Property 5: Document History Management - maintains exactly last 50 documents', () async {
      // Property-based test: Run 100 iterations with different document counts
      for (int iteration = 0; iteration < 100; iteration++) {
        final userId = uuid.v4();
        final count = 1 + random.nextInt(100); // 1-100 documents
        
        // Create documents with sequential timestamps
        final documents = <DocumentModel>[];
        final baseTime = DateTime.now().millisecondsSinceEpoch;
        
        for (int i = 0; i < count; i++) {
          final document = DocumentModel(
            id: uuid.v4(),
            userId: userId,
            filename: 'document_$i.pdf',
            content: 'Content for document $i',
            createdAt: DateTime.fromMillisecondsSinceEpoch(baseTime + i * 1000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(baseTime + i * 1000),
          );
          documents.add(document);
          
          // Save document
          await dataSource.saveDocument(document, null);
        }
        
        // Get all documents for the user
        final retrievedDocuments = await dataSource.getAllDocuments(userId);
        
        // Verify document count constraint (max 50)
        expect(retrievedDocuments.length, lessThanOrEqualTo(50),
               reason: 'Should not exceed 50 documents for iteration $iteration');
        
        // If we created more than 50 documents, verify we have exactly 50
        if (count > 50) {
          expect(retrievedDocuments.length, equals(50),
                 reason: 'Should have exactly 50 documents when more than 50 created for iteration $iteration');
          
          // Verify we have the LAST 50 documents (most recent)
          final expectedDocuments = documents.skip(count - 50).toList();
          
          for (int i = 0; i < 50; i++) {
            expect(
              retrievedDocuments[i].id,
              equals(expectedDocuments[49 - i].id), // Reversed order (newest first)
              reason: 'Should have correct document order for iteration $iteration',
            );
          }
        } else {
          // If we created 50 or fewer, we should have all of them
          expect(retrievedDocuments.length, equals(count),
                 reason: 'Should have all documents when count <= 50 for iteration $iteration');
        }
        
        // Verify documents are ordered by creation date (newest first)
        for (int i = 0; i < retrievedDocuments.length - 1; i++) {
          expect(
            retrievedDocuments[i].createdAt.isAfter(retrievedDocuments[i + 1].createdAt) ||
            retrievedDocuments[i].createdAt.isAtSameMomentAs(retrievedDocuments[i + 1].createdAt),
            isTrue,
            reason: 'Documents should be ordered by creation date (newest first) for iteration $iteration',
          );
        }
        
        // Verify all documents have complete metadata
        for (final doc in retrievedDocuments) {
          expect(doc.id, isNotEmpty,
                 reason: 'Document ID should not be empty for iteration $iteration');
          expect(doc.userId, equals(userId),
                 reason: 'Document userId should match for iteration $iteration');
          expect(doc.filename, isNotEmpty,
                 reason: 'Document filename should not be empty for iteration $iteration');
          expect(doc.content, isNotEmpty,
                 reason: 'Document content should not be empty for iteration $iteration');
          expect(doc.createdAt, isNotNull,
                 reason: 'Document createdAt should not be null for iteration $iteration');
          expect(doc.updatedAt, isNotNull,
                 reason: 'Document updatedAt should not be null for iteration $iteration');
        }
        
        // Clean up for next iteration
        await databaseHelper.deleteDatabase();
      }
    });

    /**
     * Feature: quickpdf-template-marketplace, Property 5a: Document Search Accuracy
     * For any search query, all returned documents should match the search criteria
     * Validates: Requirements 4.2, 4.3
     */
    test('Property 5a: Document Search Accuracy - search results match criteria', () async {
      // Property-based test: Run 100 iterations with random search terms
      for (int iteration = 0; iteration < 100; iteration++) {
        final userId = uuid.v4();
        final searchTermCount = 1 + random.nextInt(10); // 1-10 search terms
        final searchTerms = <String>[];
        
        // Generate random search terms
        for (int i = 0; i < searchTermCount; i++) {
          searchTerms.add(generateRandomString(random, minLength: 1, maxLength: 20));
        }
        
        // Create documents with known content
        final documents = <DocumentModel>[];
        
        for (int i = 0; i < searchTerms.length; i++) {
          final term = searchTerms[i];
          final document = DocumentModel(
            id: uuid.v4(),
            userId: userId,
            filename: 'document_${term}_$i.pdf',
            content: 'This document contains the term: $term',
            createdAt: DateTime.now().subtract(Duration(minutes: i)),
            updatedAt: DateTime.now().subtract(Duration(minutes: i)),
          );
          documents.add(document);
          await dataSource.saveDocument(document, null);
        }
        
        // Test search with each term
        for (final searchTerm in searchTerms) {
          final searchResults = await dataSource.searchDocuments(userId, searchTerm);
          
          // Verify all results contain the search term
          for (final result in searchResults) {
            final containsInFilename = result.filename.toLowerCase().contains(searchTerm.toLowerCase());
            final containsInContent = result.content.toLowerCase().contains(searchTerm.toLowerCase());
            
            expect(
              containsInFilename || containsInContent,
              isTrue,
              reason: 'Search result should contain the search term "$searchTerm" in filename or content for iteration $iteration',
            );
          }
          
          // Verify we don't miss any documents that should match
          final expectedMatches = documents.where((doc) {
            return doc.filename.toLowerCase().contains(searchTerm.toLowerCase()) ||
                   doc.content.toLowerCase().contains(searchTerm.toLowerCase());
          }).length;
          
          expect(
            searchResults.length,
            equals(expectedMatches),
            reason: 'Search should return all matching documents for term "$searchTerm" for iteration $iteration',
          );
        }
        
        // Clean up for next iteration
        await databaseHelper.deleteDatabase();
      }
    });

    /**
     * Feature: quickpdf-template-marketplace, Property 5b: Document CRUD Consistency
     * For any document operations (create, read, update, delete), the system should maintain data consistency
     * Validates: Requirements 4.4, 4.5
     */
    test('Property 5b: Document CRUD Consistency - operations maintain data integrity', () async {
      // Property-based test: Run 100 iterations with random document data
      for (int iteration = 0; iteration < 100; iteration++) {
        final userId = uuid.v4();
        final filename = generateRandomString(random, minLength: 1, maxLength: 50);
        final content = generateRandomString(random, minLength: 1, maxLength: 1000);
        
        // Create a document
        final originalDocument = DocumentModel(
          id: uuid.v4(),
          userId: userId,
          filename: filename,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save document
        await dataSource.saveDocument(originalDocument, null);
        
        // Read document back
        final retrievedDocument = await dataSource.getDocumentById(originalDocument.id);
        expect(retrievedDocument, isNotNull,
               reason: 'Document should be retrievable after save for iteration $iteration');
        expect(retrievedDocument!.id, equals(originalDocument.id),
               reason: 'Document ID should match for iteration $iteration');
        expect(retrievedDocument.userId, equals(originalDocument.userId),
               reason: 'Document userId should match for iteration $iteration');
        expect(retrievedDocument.filename, equals(originalDocument.filename),
               reason: 'Document filename should match for iteration $iteration');
        expect(retrievedDocument.content, equals(originalDocument.content),
               reason: 'Document content should match for iteration $iteration');
        
        // Update document
        final updatedContent = '$content - updated';
        final updatedDocument = retrievedDocument.copyWith(
          content: updatedContent,
          updatedAt: DateTime.now(),
        );
        
        await dataSource.updateDocument(updatedDocument);
        
        // Read updated document
        final retrievedUpdatedDocument = await dataSource.getDocumentById(originalDocument.id);
        expect(retrievedUpdatedDocument, isNotNull,
               reason: 'Updated document should be retrievable for iteration $iteration');
        expect(retrievedUpdatedDocument!.content, equals(updatedContent),
               reason: 'Updated content should match for iteration $iteration');
        expect(
          retrievedUpdatedDocument.updatedAt.isAfter(retrievedDocument.updatedAt),
          isTrue,
          reason: 'Updated document should have newer updatedAt timestamp for iteration $iteration',
        );
        
        // Verify document count
        final countBeforeDelete = await dataSource.getDocumentCount(userId);
        expect(countBeforeDelete, greaterThan(0),
               reason: 'Document count should be positive before delete for iteration $iteration');
        
        // Delete document
        await dataSource.deleteDocument(originalDocument.id);
        
        // Verify document is deleted
        final deletedDocument = await dataSource.getDocumentById(originalDocument.id);
        expect(deletedDocument, isNull,
               reason: 'Document should be null after delete for iteration $iteration');
        
        // Verify document count decreased
        final countAfterDelete = await dataSource.getDocumentCount(userId);
        expect(countAfterDelete, equals(countBeforeDelete - 1),
               reason: 'Document count should decrease by 1 after delete for iteration $iteration');
        
        // Clean up for next iteration
        await databaseHelper.deleteDatabase();
      }
    });
  });
}

// Helper function to generate random strings
String generateRandomString(Random random, {int minLength = 0, int maxLength = 100}) {
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 çğıöşüÇĞİÖŞÜ.,!?-';
  return String.fromCharCodes(
    List.generate(length, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
  );
}