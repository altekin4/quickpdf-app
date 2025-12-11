import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/pdf/pdf_editor_screen.dart';
import '../screens/pdf/pdf_generation_screen.dart';
import '../screens/templates/template_list_screen.dart';
import '../screens/templates/template_detail_screen.dart';
import '../screens/documents/document_history_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main App
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // PDF Editor
      GoRoute(
        path: '/pdf-editor',
        name: 'pdf-editor',
        builder: (context, state) {
          final templateId = state.uri.queryParameters['templateId'];
          return PDFEditorScreen(templateId: templateId);
        },
      ),
      
      // PDF Generation
      GoRoute(
        path: '/pdf-generate',
        name: 'pdf-generate',
        builder: (context, state) => const PdfGenerationScreen(),
      ),
      
      // Templates
      GoRoute(
        path: '/templates',
        name: 'templates',
        builder: (context, state) => const TemplateListScreen(),
      ),
      GoRoute(
        path: '/templates/:id',
        name: 'template-detail',
        builder: (context, state) {
          final templateId = state.pathParameters['id']!;
          return TemplateDetailScreen(templateId: templateId);
        },
      ),
      
      // Documents
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentHistoryScreen(),
      ),
      
      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Sayfa bulunamadı',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    ),
  );
}