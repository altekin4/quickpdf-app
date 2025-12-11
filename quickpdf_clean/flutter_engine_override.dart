// Flutter Engine Override for Turkish Character Path Fix
// This file forces Flutter to use Skia renderer instead of Impeller

import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  // Set environment variables to disable Impeller
  Platform.environment['FLUTTER_ENGINE_SWITCH_TO_IMPELLER'] = 'false';
  Platform.environment['FLUTTER_WEB_USE_SKIA'] = 'true';
  Platform.environment['FLUTTER_DISABLE_SHADER_COMPILATION'] = 'true';
  
  if (kDebugMode) {
    print('Flutter Engine Override: Impeller disabled, Skia enabled');
  }
}