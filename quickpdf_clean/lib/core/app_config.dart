class AppConfig {
  static const String appName = 'QuickPDF';
  static const String version = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:3000';
  static const String apiVersion = 'v1';
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Cache Configuration
  static const int maxCacheSize = 100; // MB
  static const int cacheExpiryDays = 7;
  
  // PDF Configuration
  static const int maxPdfSize = 50; // MB
  static const List<String> supportedFormats = ['pdf'];
  
  static Future<void> initialize() async {
    // Initialize app configuration
    // This can include loading remote config, setting up analytics, etc.
  }
}