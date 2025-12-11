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
  ];

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.userTokenKey);
      final userData = prefs.getString(AppConfig.userDataKey);

      if (token != null && userData != null) {
        _token = token;
        final userJson = json.decode(userData);
        _currentUser = User.fromJson(userJson);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
  }

  Future<void> initializeAuth() async {
    await loadUserFromStorage();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final user = _mockUsers.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );

      if (user.isEmpty) {
        setError('Geçersiz email veya şifre');
        setLoading(false);
        return false;
      }

      _token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = User(
        id: user['id'],
        email: user['email'],
        fullName: user['full_name'],
        role: UserRole.values.firstWhere((r) => r.name == user['role']),
        isVerified: user['is_verified'],
        balance: user['balance'],
        totalEarnings: user['total_earnings'],
        createdAt: DateTime.parse(user['created_at']),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userTokenKey, _token!);
      await prefs.setString(AppConfig.userDataKey, json.encode(_currentUser!.toJson()));

      setLoading(false);
      return true;
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
      await Future.delayed(const Duration(seconds: 2));

      final existingUser = _mockUsers.any((user) => user['email'] == email);
      
      if (existingUser) {
        setError('Bu email adresi zaten kullanılıyor');
        setLoading(false);
        return false;
      }

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

  Future<void> resendVerificationEmail(String email) async {
    setLoading(true);
    setError(null);

    try {
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Verification email sent to: $email');
      setLoading(false);
    } catch (e) {
      setError('E-posta gönderme hatası: $e');
      setLoading(false);
      throw Exception('E-posta gönderme hatası: $e');
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(isVerified: true);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      setError('Doğrulama kontrolü hatası: $e');
      throw Exception('Doğrulama kontrolü hatası: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    setLoading(true);
    setError(null);

    try {
      await Future.delayed(const Duration(seconds: 2));
      
      final userExists = _mockUsers.any((user) => user['email'] == email);
      if (!userExists) {
        throw Exception('Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı');
      }
      
      debugPrint('Password reset email sent to: $email');
      setLoading(false);
    } catch (e) {
      setError('Şifre sıfırlama e-postası gönderme hatası: $e');
      setLoading(false);
      throw Exception('Şifre sıfırlama e-postası gönderme hatası: $e');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    setLoading(true);
    setError(null);

    try {
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Password reset with token: $token');
      setLoading(false);
    } catch (e) {
      setError('Şifre sıfırlama hatası: $e');
      setLoading(false);
      throw Exception('Şifre sıfırlama hatası: $e');
    }
  }
}