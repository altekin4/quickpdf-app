// Automated script to fix deprecated APIs
import 'dart:io';

void main() async {
  print('🔧 Fixing deprecated APIs...');
  
  final directory = Directory('quickpdf_app/lib');
  await fixDeprecatedAPIs(directory);
  
  final cleanDirectory = Directory('quickpdf_clean/lib');
  await fixDeprecatedAPIs(cleanDirectory);
  
  print('✅ Deprecated APIs fixed!');
}

Future<void> fixDeprecatedAPIs(Directory directory) async {
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await fixFileAPIs(entity);
    }
  }
}

Future<void> fixFileAPIs(File file) async {
  try {
    String content = await file.readAsString();
    bool changed = false;
    
    // Fix withOpacity -> withValues
    if (content.contains('.withOpacity(')) {
      content = content.replaceAllMapped(
        RegExp(r'\.withOpacity\(([^)]+)\)'),
        (match) {
          final opacity = match.group(1);
          return '.withValues(alpha: $opacity)';
        },
      );
      changed = true;
    }
    
    // Fix background -> surface (in ColorScheme)
    if (content.contains('background:')) {
      content = content.replaceAll('background:', 'surface:');
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