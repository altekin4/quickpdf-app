import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/app_config.dart';

class PaymentProvider extends ChangeNotifier {
  final dynamic _authProvider;
  
  PaymentProvider(this._authProvider);

  bool _isProcessingPayment = false;
  String? _error;
  List<Purchase> _purchases = [];
  List<Payout> _payouts = [];

  bool get isProcessingPayment => _isProcessingPayment;
  bool get isProcessing => _isProcessingPayment; // Alias for compatibility
  String? get error => _error;
  List<Purchase> get purchases => _purchases;
  List<Payout> get payouts => _payouts;

  Future<PaymentIntent?> createPaymentIntent(String templateId) async {
    try {
      _setProcessing(true);
      _clearError();

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/payments/payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode({
          'templateId': templateId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return PaymentIntent.fromJson(data['data']['paymentIntent']);
        } else {
          throw Exception(data['error']['message'] ?? 'Payment intent creation failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']['message'] ?? 'Payment intent creation failed');
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  Future<bool> confirmPayment(String paymentIntentId) async {
    try {
      _setProcessing(true);
      _clearError();

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/payments/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode({
          'paymentIntentId': paymentIntentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Refresh purchase history
          await loadPurchases();
          return true;
        } else {
          throw Exception(data['error']['message'] ?? 'Payment confirmation failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']['message'] ?? 'Payment confirmation failed');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  Future<bool> hasUserPurchased(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/payments/check-purchase/$templateId'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['hasPurchased'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking purchase status: $e');
      return false;
    }
  }

  Future<void> loadPurchases({int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/payments/purchases?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final purchaseList = data['data']['purchases'] as List;
          if (offset == 0) {
            _purchases = purchaseList.map((p) => Purchase.fromJson(p)).toList();
          } else {
            _purchases.addAll(purchaseList.map((p) => Purchase.fromJson(p)));
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading purchases: $e');
    }
  }

  Future<bool> requestPayout(double amount) async {
    try {
      _setProcessing(true);
      _clearError();

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/payments/payout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authProvider.token}',
        },
        body: json.encode({
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          // Refresh payout history
          await loadPayouts();
          return true;
        } else {
          throw Exception(data['error']['message'] ?? 'Payout request failed');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']['message'] ?? 'Payout request failed');
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> loadPayouts({int limit = 50, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/payments/payouts?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer ${_authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final payoutList = data['data']['payouts'] as List;
          if (offset == 0) {
            _payouts = payoutList.map((p) => Payout.fromJson(p)).toList();
          } else {
            _payouts.addAll(payoutList.map((p) => Payout.fromJson(p)));
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading payouts: $e');
    }
  }

  void _setProcessing(bool processing) {
    _isProcessingPayment = processing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

class PaymentIntent {
  final String id;
  final String clientSecret;
  final double amount;
  final String currency;
  final String status;

  PaymentIntent({
    required this.id,
    required this.clientSecret,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'],
      clientSecret: json['clientSecret'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      status: json['status'],
    );
  }
}

class Purchase {
  final String id;
  final String userId;
  final String templateId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String paymentGateway;
  final String transactionId;
  final String? gatewayTransactionId;
  final String status;
  final DateTime purchasedAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? templateTitle;
  final String? templateDescription;

  Purchase({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentGateway,
    required this.transactionId,
    this.gatewayTransactionId,
    required this.status,
    required this.purchasedAt,
    this.completedAt,
    this.refundedAt,
    this.templateTitle,
    this.templateDescription,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      userId: json['userId'],
      templateId: json['templateId'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      paymentGateway: json['paymentGateway'],
      transactionId: json['transactionId'],
      gatewayTransactionId: json['gatewayTransactionId'],
      status: json['status'],
      purchasedAt: DateTime.parse(json['purchasedAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      refundedAt: json['refundedAt'] != null ? DateTime.parse(json['refundedAt']) : null,
      templateTitle: json['template_title'],
      templateDescription: json['template_description'],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
}

class Payout {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String? paymentMethod;
  final Map<String, dynamic>? paymentDetails;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  Payout({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.paymentDetails,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'],
      userId: json['userId'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      paymentDetails: json['paymentDetails'],
      requestedAt: DateTime.parse(json['requestedAt']),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}