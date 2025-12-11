// Script to fix remaining BuildContext async issues
import 'dart:io';

void main() async {
  print('🔧 Fixing remaining BuildContext async issues...');
  
  final files = [
    'quickpdf_app/lib/presentation/screens/profile/creator_earnings_screen.dart',
    'quickpdf_app/lib/presentation/screens/templates/marketplace_home_screen.dart',
    'quickpdf_clean/lib/presentation/screens/profile/creator_earnings_screen.dart',
    'quickpdf_clean/lib/presentation/screens/templates/marketplace_home_screen.dart',
  ];
  
  for (final filePath in files) {
    await fixBuildContextAsync(File(filePath));
  }
  
  print('✅ Remaining BuildContext async issues fixed!');
}

Future<void> fixBuildContextAsync(File file) async {
  if (!await file.exists()) return;
  
  try {
    String content = await file.readAsString();
    bool changed = false;
    
    // Pattern: Add mounted check before any context usage after await
    final lines = content.split('\n');
    final fixedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      fixedLines.add(line);
      
      // If line contains await and next few lines contain context usage
      if (line.trim().startsWith('await ') && line.trim().endsWith(';')) {
        // Look ahead for context usage
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final nextLine = lines[j];
          if (nextLine.contains('context.') || 
              nextLine.contains('Navigator.of(context)') ||
              nextLine.contains('ScaffoldMessenger.of(context)') ||
              nextLine.contains('showDialog(')) {
            // Insert mounted check
            final indent = ' ' * (nextLine.length - nextLine.trimLeft().length);
            fixedLines.add('${indent}if (!mounted) return;');
            changed = true;
            break;
          }
          if (nextLine.trim().isEmpty) continue;
          if (nextLine.trim().startsWith('//')) continue;
          break;
        }
      }
    }
    
    if (changed) {
      await file.writeAsString(fixedLines.join('\n'));
      print('Fixed: ${file.path}');
    }
  } catch (e) {
    print('Error fixing ${file.path}: $e');
  }
}