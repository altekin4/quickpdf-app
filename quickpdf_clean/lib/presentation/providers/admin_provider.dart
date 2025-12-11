import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  // Dashboard Stats
  Map<String, dynamic> _dashboardStats = {};
  
  // Users Management
  List<User> _users = [];
  List<User> _filteredUsers = [];
  String _userSearchQuery = '';
  UserRole? _selectedUserRole;
  
  // Templates Management
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _filteredTemplates = [];
  String _templateSearchQuery = '';
  String? _selectedTemplateStatus;
  
  // Payments Management
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  String _paymentSearchQuery = '';
  String? _selectedPaymentStatus;
  
  // Analytics
  Map<String, dynamic> _analytics = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<User> get users => _filteredUsers;
  List<Map<String, dynamic>> get templates => _filteredTemplates;
  List<Map<String, dynamic>> get payments => _filteredPayments;
  Map<String, dynamic> get analytics => _analytics;

  AdminProvider() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock Dashboard Stats
    _dashboardStats = {
      'totalUsers': 1250,
      'activeUsers': 890,
      'totalTemplates': 156,
      'activeTemplates': 142,
      'totalRevenue': 45670.50,
      'monthlyRevenue': 8920.30,
      'totalDownloads': 12450,
      'monthlyDownloads': 2340,
    };

    // Mock Users
    _users = [
      User(
        id: '1',
        email: 'test@test.com',
        fullName: 'Test Kullanıcı',
        role: UserRole.user,
        isVerified: true,
        balance: 100.0,
        totalEarnings: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: '2',
        email: 'admin@quickpdf.com',
        fullName: 'Admin Kullanıcı',
        role: UserRole.admin,
        isVerified: true,
        balance: 1000.0,
        totalEarnings: 500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      User(
        id: '3',
        email: 'creator@quickpdf.com',
        fullName: 'İçerik Üreticisi',
        role: UserRole.creator,
        isVerified: true,
        balance: 250.0,
        totalEarnings: 150.0,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      User(
        id: '4',
        email: 'john.doe@example.com',
        fullName: 'John Doe',
        role: UserRole.user,
        isVerified: false,
        balance: 0.0,
        totalEarnings: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      User(
        id: '5',
        email: 'jane.smith@example.com',
        fullName: 'Jane Smith',
        role: UserRole.creator,
        isVerified: true,
        balance: 450.0,
        totalEarnings: 320.0,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];

    // Mock Templates
    _templates = [
      {
        'id': '1',
        'title': 'Fatura Şablonu',
        'description': 'Profesyonel fatura şablonu',
        'category': 'İş',
        'price': 29.99,
        'downloads': 450,
        'rating': 4.8,
        'status': 'active',
        'creatorId': '3',
        'creatorName': 'İçerik Üreticisi',
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
      },
      {
        'id': '2',
        'title': 'CV Şablonu',
        'description': 'Modern CV şablonu',
        'category': 'Kişisel',
        'price': 19.99,
        'downloads': 320,
        'rating': 4.6,
        'status': 'active',
        'creatorId': '5',
        'creatorName': 'Jane Smith',
        'createdAt': DateTime.now().subtract(const Duration(days: 25)),
      },
      {
        'id': '3',
        'title': 'Sözleşme Şablonu',
        'description': 'Hukuki sözleşme şablonu',
        'category': 'Hukuk',
        'price': 49.99,
        'downloads': 180,
        'rating': 4.9,
        'status': 'pending',
        'creatorId': '3',
        'creatorName': 'İçerik Üreticisi',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
    ];

    // Mock Payments
    _payments = [
      {
        'id': '1',
        'userId': '1',
        'userName': 'Test Kullanıcı',
        'templateId': '1',
        'templateTitle': 'Fatura Şablonu',
        'amount': 29.99,
        'currency': 'TRY',
        'status': 'completed',
        'paymentMethod': 'credit_card',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '2',
        'userId': '4',
        'userName': 'John Doe',
        'templateId': '2',
        'templateTitle': 'CV Şablonu',
        'amount': 19.99,
        'currency': 'TRY',
        'status': 'completed',
        'paymentMethod': 'paypal',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': '3',
        'userId': '5',
        'userName': 'Jane Smith',
        'templateId': '1',
        'templateTitle': 'Fatura Şablonu',
        'amount': 29.99,
        'currency': 'TRY',
        'status': 'pending',
        'paymentMethod': 'bank_transfer',
        'createdAt': DateTime.now().subtract(const Duration(hours: 6)),
      },
    ];

    // Mock Analytics
    _analytics = {
      'userGrowth': [
        {'month': 'Ocak', 'users': 100},
        {'month': 'Şubat', 'users': 150},
        {'month': 'Mart', 'users': 200},
        {'month': 'Nisan', 'users': 280},
        {'month': 'Mayıs', 'users': 350},
        {'month': 'Haziran', 'users': 420},
      ],
      'revenueGrowth': [
        {'month': 'Ocak', 'revenue': 2500},
        {'month': 'Şubat', 'revenue': 3200},
        {'month': 'Mart', 'revenue': 4100},
        {'month': 'Nisan', 'revenue': 5800},
        {'month': 'Mayıs', 'revenue': 7200},
        {'month': 'Haziran', 'revenue': 8920},
      ],
      'topCategories': [
        {'category': 'İş', 'count': 45, 'revenue': 12500},
        {'category': 'Kişisel', 'count': 38, 'revenue': 8900},
        {'category': 'Hukuk', 'count': 22, 'revenue': 15600},
        {'category': 'Eğitim', 'count': 31, 'revenue': 7800},
        {'category': 'Sağlık', 'count': 20, 'revenue': 6200},
      ],
    };

    _applyFilters();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // User Management
  void searchUsers(String query) {
    _userSearchQuery = query;
    _applyUserFilters();
  }

  void filterUsersByRole(UserRole? role) {
    _selectedUserRole = role;
    _applyUserFilters();
  }

  void _applyUserFilters() {
    _filteredUsers = _users.where((user) {
      final matchesSearch = _userSearchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
      
      final matchesRole = _selectedUserRole == null || user.role == _selectedUserRole;
      
      return matchesSearch && matchesRole;
    }).toList();
    
    notifyListeners();
  }

  Future<void> updateUserStatus(String userId, bool isVerified) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = User(
          id: _users[userIndex].id,
          email: _users[userIndex].email,
          fullName: _users[userIndex].fullName,
          role: _users[userIndex].role,
          isVerified: isVerified,
          balance: _users[userIndex].balance,
          totalEarnings: _users[userIndex].totalEarnings,
          createdAt: _users[userIndex].createdAt,
        );
        _applyUserFilters();
      }
    } catch (e) {
      _setError('Kullanıcı durumu güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUser(String userId) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      _users.removeWhere((user) => user.id == userId);
      _applyUserFilters();
    } catch (e) {
      _setError('Kullanıcı silinirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Template Management
  void searchTemplates(String query) {
    _templateSearchQuery = query;
    _applyTemplateFilters();
  }

  void filterTemplatesByStatus(String? status) {
    _selectedTemplateStatus = status;
    _applyTemplateFilters();
  }

  void _applyTemplateFilters() {
    _filteredTemplates = _templates.where((template) {
      final matchesSearch = _templateSearchQuery.isEmpty ||
          template['title'].toLowerCase().contains(_templateSearchQuery.toLowerCase()) ||
          template['description'].toLowerCase().contains(_templateSearchQuery.toLowerCase());
      
      final matchesStatus = _selectedTemplateStatus == null || 
          template['status'] == _selectedTemplateStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
    
    notifyListeners();
  }

  Future<void> updateTemplateStatus(String templateId, String status) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final templateIndex = _templates.indexWhere((template) => template['id'] == templateId);
      if (templateIndex != -1) {
        _templates[templateIndex]['status'] = status;
        _applyTemplateFilters();
      }
    } catch (e) {
      _setError('Şablon durumu güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      _templates.removeWhere((template) => template['id'] == templateId);
      _applyTemplateFilters();
    } catch (e) {
      _setError('Şablon silinirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Payment Management
  void searchPayments(String query) {
    _paymentSearchQuery = query;
    _applyPaymentFilters();
  }

  void filterPaymentsByStatus(String? status) {
    _selectedPaymentStatus = status;
    _applyPaymentFilters();
  }

  void _applyPaymentFilters() {
    _filteredPayments = _payments.where((payment) {
      final matchesSearch = _paymentSearchQuery.isEmpty ||
          payment['userName'].toLowerCase().contains(_paymentSearchQuery.toLowerCase()) ||
          payment['templateTitle'].toLowerCase().contains(_paymentSearchQuery.toLowerCase());
      
      final matchesStatus = _selectedPaymentStatus == null || 
          payment['status'] == _selectedPaymentStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
    
    notifyListeners();
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      
      final paymentIndex = _payments.indexWhere((payment) => payment['id'] == paymentId);
      if (paymentIndex != -1) {
        _payments[paymentIndex]['status'] = status;
        _applyPaymentFilters();
      }
    } catch (e) {
      _setError('Ödeme durumu güncellenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _applyFilters() {
    _applyUserFilters();
    _applyTemplateFilters();
    _applyPaymentFilters();
  }

  Future<void> refreshData() async {
    _setLoading(true);
    
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      _initializeMockData();
    } catch (e) {
      _setError('Veriler yenilenirken hata oluştu: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}