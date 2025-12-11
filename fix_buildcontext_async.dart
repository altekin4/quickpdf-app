// Script to fix BuildContext async issues
import 'dart:io';

void main() async {
  print('🔧 Fixing BuildContext async issues...');
  
  final files = [
    'quickpdf_app/lib/presentation/screens/documents/document_history_screen.dart',
    'quickpdf_app/lib/presentation/screens/profile/creator_earnings_screen.dart',
    'quickpdf_app/lib/presentation/screens/templates/marketplace_home_screen.dart',
    'quickpdf_clean/lib/presentation/screens/documents/document_history_screen.dart',
    'quickpdf_clean/lib/presentation/screens/profile/creator_earnings_screen.dart',
    'quickpdf_clean/lib/presentation/screens/templates/marketplace_home_screen.dart',
  ];
  
  for (final filePath in files) {
    await fixBuildContextAsync(File(filePath));
  }
  
  print('✅ BuildContext async issues fixed!');
}

Future<void> fixBuildContextAsync(File file) async {
  if (!await file.exists()) return;
  
  try {
    String content = await file.readAsString();
    bool changed = false;
    
    // Pattern 1: Navigator.of(context) after await
    if (content.contains('await ') && content.contains('Navigator.of(context)')) {
      // Add mounted check before Navigator calls
      content = content.replaceAllMapped(
        RegExp(r'(await [^;]+;)\s*(Navigator\.of\(context\)[^;]+;)'),
        (match) {
          final awaitCall = match.group(1);
          final navigatorCall = match.group(2);
          return '$awaitCall\n      if (mounted) {\n        $navigatorCall\n      }';
        },
      );
      changed = true;
    }
    
    // Pattern 2: ScaffoldMessenger.of(context) after await
    if (content.contains('await ') && content.contains('ScaffoldMessenger.of(context)')) {
      content = content.replaceAllMapped(
        RegExp(r'(await [^;]+;)\s*(ScaffoldMessenger\.of\(context\)[^;]+;)'),
        (match) {
          final awaitCall = match.group(1);
          final scaffoldCall = match.group(2);
          return '$awaitCall\n      if (mounted) {\n        $scaffoldCall\n      }';
        },
      );
      changed = true;
    }
    
    if (changed) {
      await file.writeAsString(content);
      print('Fixed: ${file.path}');
    }
  } catch (e) {
    print('Error fixing ${file.path}: $e');
  }
}