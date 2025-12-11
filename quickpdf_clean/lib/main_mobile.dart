import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/mock_auth_provider.dart';
import 'presentation/screens/mobile/mobile_splash_screen.dart';
import 'presentation/screens/mobile/mobile_login_screen.dart';
import 'presentation/screens/mobile/mobile_home_screen.dart';
import 'core/theme/mobile_theme.dart';

void main() {
  runApp(const QuickPDFMobileApp());
}

class QuickPDFMobileApp extends StatelessWidget {
  const QuickPDFMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MockAuthProvider(),
      child: MaterialApp(
        title: 'QuickPDF',
        theme: MobileTheme.lightTheme,
        darkTheme: MobileTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MobileSplashScreen(),
        routes: {
          '/login': (context) => const MobileLoginScreen(),
          '/home': (context) => const MobileHomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}