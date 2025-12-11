import 'package:flutter_test/flutter_test.dart';
import 'package:quickpdf_app/core/services/connectivity_service.dart';

void main() {
  group('Connectivity Service Tests', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    test('should initialize connectivity service', () async {
      // Act
      await connectivityService.initialize();
      
      // Assert
      expect(connectivityService.hasBeenInitialized, isTrue);
    });

    test('should provide status text', () {
      // Act & Assert
      expect(connectivityService.statusText, isA<String>());
      expect(['Çevrimiçi', 'Çevrimdışı'].contains(connectivityService.statusText), isTrue);
    });

    test('should provide status icon', () {
      // Act & Assert
      expect(connectivityService.statusIcon, isA<String>());
      expect(['wifi', 'wifi_off'].contains(connectivityService.statusIcon), isTrue);
    });

    test('should refresh connectivity status', () async {
      // Arrange
      await connectivityService.initialize();
      
      // Act
      await connectivityService.refresh();
      
      // Assert - Should not throw any errors
      expect(connectivityService.hasBeenInitialized, isTrue);
    });
  });
}