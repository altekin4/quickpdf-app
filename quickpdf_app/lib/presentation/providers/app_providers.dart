import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'auth_provider.dart';
import 'template_provider.dart';
import 'document_provider.dart';
import 'pdf_provider.dart';
import 'payment_provider.dart';
import 'tag_provider.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../data/datasources/local/document_local_datasource.dart';
import '../../data/datasources/local/database_helper.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => TemplateProvider()),
    ChangeNotifierProvider(create: (_) => DocumentProvider(DocumentRepositoryImpl(DocumentLocalDataSourceImpl(DatabaseHelper.instance)))),
    ChangeNotifierProvider(create: (_) => PDFProvider()),
    ChangeNotifierProvider(create: (_) => PaymentProvider(AuthProvider())),
    ChangeNotifierProvider(create: (_) => TagProvider()),
  ];
}