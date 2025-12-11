import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/mock_auth_provider.dart';
import 'presentation/providers/template_provider.dart';
import 'presentation/providers/pdf_provider.dart';
import 'presentation/providers/payment_provider.dart';
import 'presentation/providers/document_provider.dart';
import 'presentation/router/app_router.dart';
import 'data/repositories/document_repository_impl.dart';
import 'data/datasources/local/document_local_datasource.dart';
import 'data/datasources/local/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  runApp(const QuickPDFApp());
}

class QuickPDFApp extends StatelessWidget {
  const QuickPDFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockAuthProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => PDFProvider()),
        ChangeNotifierProxyProvider<MockAuthProvider, PaymentProvider>(
          create: (_) => PaymentProvider(MockAuthProvider()),
          update: (_, authProvider, __) => PaymentProvider(authProvider),
        ),
        ChangeNotifierProvider(create: (_) => DocumentProvider(DocumentRepositoryImpl(DocumentLocalDataSourceImpl(DatabaseHelper.instance)))),
      ],
      child: MaterialApp.router(
        title: 'QuickPDF',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}



