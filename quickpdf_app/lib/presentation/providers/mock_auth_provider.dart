import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_config.dart';
import '../../domain/entities/user.dart';

class MockAuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  User? get user => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isAuthenticated => _currentUser != null && _token != null;

  // Mock users for testing
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'email': 'test@test.com',
      'password': '123456',
      'full_name': 'Test Kullanıcı',
      'role': 'user',
      'is_verified': true,
      'balance': 100.0,
      'total_earnings': 0.0,
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': '2',
      'email': 'admin@quickpdf.com',
      'password': 'admin123',
      'full_name': 'Admin Kullanıcı',
      'role': 'admin',
      'is_verified': true,
      'balance': 1000.0,
      'total_earnings': 500.0,
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'id': '3',
      'email': 'creator@quickpdf.com',
      'password': 'creator123',
      'full_name': 'İçerik Üreticisi',
      'role': 'creator',
      'is_verified': true,
      'balance': 250.0,
      'total_earnings': 150.0,
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  Future<void> initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.userTokenKey);
      final userData = prefs.getString(AppConfig.userDataKey);
      
      if (token != null && userData != null) {
        _token = token;
        final userMap = json.decode(userData);
        _currentUser = User.fromJson(userMap);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Find mock user
      final mockUser = _mockUsers.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );

      if (mockUser.isNotEmpty) {
        // Generate mock token
        _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        
        // Create user from mock data
        _currentUser = User(
          id: mockUser['id'],
          email: mockUser['email'],
          fullName: mockUser['full_name'],
          role: _parseUserRole(mockUser['role']),
          isVerified: mockUser['is_verified'] ?? true,
          balance: double.tryParse(mockUser['balance']?.toString() ?? '0') ?? 0.0,
          totalEarnings: double.tryParse(mockUser['total_earnings']?.toString() ?? '0') ?? 0.0,
          createdAt: DateTime.tryParse(mockUser['created_at'] ?? '') ?? DateTime.now(),
        );
        
        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.userTokenKey, _token!);
        await prefs.setString(AppConfig.userDataKey, json.encode(_currentUser!.toJson()));
        
        setLoading(false);
        return true;
      } else {
        setError('Geçersiz email veya şifre');
        setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setError('Giriş hatası: $e');
      setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    setLoading(true);
    setError(null);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if user already exists
      final existingUser = _mockUsers.any((user) => user['email'] == email);
      
      if (existingUser) {
        setError('Bu email adresi zaten kullanılıyor');
        setLoading(false);
        return false;
      }

      // Create new mock user
      final newUserId = (_mockUsers.length + 1).toString();
      _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      
      _currentUser = User(
        id: newUserId,
        email: email,
        fullName: fullName,
        role: UserRole.user,
        isVerified: true,
        balance: 0.0,
        totalEarnings: 0.0,
        createdAt: DateTime.now(),
      );
      
      // Add to mock users list
      _mockUsers.add({
        'id': newUserId,
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': 'user',
        'is_verified': true,
        'balance': 0.0,
        'total_earnings': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userTokenKey, _token!);
      await prefs.setString(AppConfig.userDataKey, json.encode(_currentUser!.toJson()));
      
      setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      setError('Kayıt hatası: $e');
      setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Clear storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.userTokenKey);
      await prefs.remove(AppConfig.userDataKey);
      
      _currentUser = null;
      _token = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<void> refreshUser() async {
    if (!isLoggedIn) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      notifyListeners();
    } catch (e) {
      setError('Kullanıcı bilgileri güncellenirken hata oluştu: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    await initializeAuth();
  }

  Map<String, String> get authHeaders {
    if (_token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  UserRole _parseUserRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'creator':
        return UserRole.creator;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  // Helper method to get mock user credentials for testing
  List<Map<String, String>> getMockCredentials() {
    return [
      {'email': 'test@test.com', 'password': '123456', 'role': 'Kullanıcı'},
      {'email': 'admin@quickpdf.com', 'password': 'admin123', 'role': 'Admin'},
      {'email': 'creator@quickpdf.com', 'password': 'creator123', 'role': 'İçerik Üreticisi'},
    ];
  }
}