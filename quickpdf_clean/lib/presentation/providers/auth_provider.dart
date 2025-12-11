import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_config.dart';
import '../../domain/entities/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Alias for compatibility
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && _token != null;
  bool get isAuthenticated => _currentUser != null && _token != null;

  // Initialize auth state from storage
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
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['data']['token'];
        
        // Create user from response data
        final userData = data['data']['user'];
        _currentUser = User(
          id: userData['id'],
          email: userData['email'],
          fullName: userData['full_name'],
          role: _parseUserRole(userData['role']),
          isVerified: userData['is_verified'] ?? true,
          balance: double.tryParse(userData['balance']?.toString() ?? '0') ?? 0.0,
          totalEarnings: double.tryParse(userData['total_earnings']?.toString() ?? '0') ?? 0.0,
          createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        );
        
        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.userTokenKey, _token!);
        await prefs.setString(AppConfig.userDataKey, json.encode(_currentUser!.toJson()));
        
        setLoading(false);
        return true;
      } else {
        setError(data['error']?['message'] ?? 'Giriş başarısız');
        setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setError('Bağlantı hatası: $e');
      setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName) async {
    setLoading(true);
    setError(null);

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _token = data['data']['token'];
        
        // Create user from response data
        final userData = data['data']['user'];
        _currentUser = User(
          id: userData['id'],
          email: userData['email'],
          fullName: userData['full_name'],
          role: _parseUserRole(userData['role']),
          isVerified: userData['is_verified'] ?? true,
          balance: double.tryParse(userData['balance']?.toString() ?? '0') ?? 0.0,
          totalEarnings: double.tryParse(userData['total_earnings']?.toString() ?? '0') ?? 0.0,
          createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        );
        
        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.userTokenKey, _token!);
        await prefs.setString(AppConfig.userDataKey, json.encode(_currentUser!.toJson()));
        
        setLoading(false);
        return true;
      } else {
        setError(data['error']?['message'] ?? 'Kayıt başarısız');
        setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('Register error: $e');
      setError('Bağlantı hatası: $e');
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
      // TODO: Implement actual API call to refresh user data
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      // For now, just notify listeners to refresh UI
      notifyListeners();
    } catch (e) {
      setError('Kullanıcı bilgileri güncellenirken hata oluştu: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    await initializeAuth();
  }

  // Get authorization headers for API calls
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
}