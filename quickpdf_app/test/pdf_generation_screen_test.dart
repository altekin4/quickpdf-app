import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quickpdf_app/core/services/connectivity_service.dart';
import 'package:quickpdf_app/presentation/providers/pdf_provider.dart';
import 'package:quickpdf_app/presentation/providers/document_provider.dart';
import 'package:quickpdf_app/presentation/screens/pdf/pdf_generation_screen.dart';
import 'package:quickpdf_app/data/repositories/document_repository_impl.dart';
import 'package:quickpdf_app/data/datasources/local/document_local_datasource.dart';
import 'package:quickpdf_app/data/datasources/local/database_helper.dart';

void main() {
  group('PDF Generation Screen Tests', () {
    late ConnectivityService connectivityService;
    late PDFProvider pdfProvider;
    late DocumentProvider documentProvider;

    setUp(() {
      connectivityService = ConnectivityService();
      pdfProvider = PDFProvider();
      documentProvider = DocumentProvider(DocumentRepositoryImpl(DocumentLocalDataSourceImpl(DatabaseHelper.instance)));
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectivityService>.value(value: connectivityService),
            ChangeNotifierProvider<PDFProvider>.value(value: pdfProvider),
            ChangeNotifierProvider<DocumentProvider>.value(value: documentProvider),
          ],
          child: const PdfGenerationScreen(),
        ),
      );
    }

    testWidgets('should display PDF generation screen', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Assert
      expect(find.text('PDF Oluştur'), findsOneWidget);
      expect(find.text('Belge Bilgileri'), findsOneWidget);
      expect(find.text('Metin İçeriği'), findsOneWidget);
      expect(find.text('Biçimlendirme Seçenekleri'), findsOneWidget);
    });

    testWidgets('should show connectivity status in app bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Assert
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('should show offline mode indicator when in offline mode', (WidgetTester tester) async {
      // Arrange
      pdfProvider.setOfflineMode(true);
      
      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Assert
      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
      expect(find.text('PDF çevrimdışı modda oluşturuldu. Tüm özellikler yerel olarak çalışmaktadır.'), findsOneWidget);
    });

    testWidgets('should have Turkish test button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Assert
      expect(find.text('Türkçe Test'), findsOneWidget);
    });

    testWidgets('should have PDF generation button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Assert
      expect(find.text('PDF Oluştur'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show help dialog when help button is pressed', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Yardım'), findsOneWidget);
      expect(find.text('PDF Oluşturma Rehberi:'), findsOneWidget);
      expect(find.text('• İnternet bağlantısı olmadan da çalışır'), findsOneWidget);
    });
  });
}