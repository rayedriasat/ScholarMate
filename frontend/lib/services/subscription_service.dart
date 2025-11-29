import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'config_service.dart';
import '../models/subscription_status.dart';
import '../models/transaction.dart';

/// Exception thrown when subscription API calls fail
class SubscriptionException implements Exception {
  final String message;
  final int? statusCode;

  SubscriptionException(this.message, [this.statusCode]);

  @override
  String toString() => 'SubscriptionException: $message (Status: $statusCode)';
}

/// Service for managing subscription and payment operations
class SubscriptionService extends ChangeNotifier {
  // Remove singleton pattern to work properly with Provider
  SubscriptionService();

  final _config = ConfigService();
  final _authService = AuthService();

  String get _baseUrl => _config.apiBaseUrl;

  // State
  SubscriptionStatus? _currentStatus;
  List<Transaction> _paymentHistory = [];
  bool _isLoading = false;
  String? _lastError;

  // Cache TTL (5 minutes)
  static const _cacheTTL = Duration(minutes: 5);
  DateTime? _statusCacheTime;
  DateTime? _historyCacheTime;

  // Getters
  SubscriptionStatus? get currentStatus => _currentStatus;
  List<Transaction> get paymentHistory => List.unmodifiable(_paymentHistory);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Check if user has premium subscription
  bool get isPremium => _currentStatus?.isPremium ?? false;

  /// Check if user is on free plan
  bool get isFree => _currentStatus?.isFree ?? true;

  /// Load subscription status from backend
  /// Uses cached data if available and not expired
  Future<void> loadSubscriptionStatus({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh &&
        _currentStatus != null &&
        _statusCacheTime != null &&
        DateTime.now().difference(_statusCacheTime!) < _cacheTTL) {
      debugPrint('Using cached subscription status');
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw SubscriptionException('User not authenticated');
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/payments/subscription-status?user_id=${user.id}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentStatus = SubscriptionStatus.fromJson(data);
        _statusCacheTime = DateTime.now();
        debugPrint('Subscription status loaded: ${_currentStatus?.plan}');
      } else {
        throw SubscriptionException(
          'Failed to load subscription status: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error loading subscription status: $e');
      if (e is SubscriptionException) rethrow;
      throw SubscriptionException('Failed to load subscription status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load payment history from backend
  /// Uses cached data if available and not expired
  Future<void> loadPaymentHistory({bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh &&
        _paymentHistory.isNotEmpty &&
        _historyCacheTime != null &&
        DateTime.now().difference(_historyCacheTime!) < _cacheTTL) {
      debugPrint('Using cached payment history');
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw SubscriptionException('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/payments/history?user_id=${user.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionsList = data['transactions'] as List;
        _paymentHistory = transactionsList
            .map((json) => Transaction.fromJson(json))
            .toList();
        _historyCacheTime = DateTime.now();
        debugPrint(
          'Payment history loaded: ${_paymentHistory.length} transactions',
        );
      } else {
        throw SubscriptionException(
          'Failed to load payment history: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error loading payment history: $e');
      if (e is SubscriptionException) rethrow;
      throw SubscriptionException('Failed to load payment history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize a payment transaction
  /// Returns transaction ID and payment URL (if applicable)
  Future<Map<String, dynamic>> initializePayment({
    required String paymentMethod,
    required double amount,
    String currency = 'BDT',
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw SubscriptionException('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/payments/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.id,
          'payment_method': paymentMethod,
          'amount': amount,
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Payment initialized: ${data['transaction_id']}');
        return data;
      } else {
        throw SubscriptionException(
          'Failed to initialize payment: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error initializing payment: $e');
      if (e is SubscriptionException) rethrow;
      throw SubscriptionException('Failed to initialize payment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify a payment transaction
  /// Returns verification result with subscription status
  Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
    required Map<String, dynamic> paymentCredentials,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transaction_id': transactionId,
          'payment_credentials': paymentCredentials,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Payment verified: ${data['success']}');

        // If payment was successful, invalidate caches to force refresh
        if (data['success'] == true) {
          _statusCacheTime = null;
          _historyCacheTime = null;
          // Reload subscription status immediately
          await loadSubscriptionStatus(forceRefresh: true);
        }

        return data;
      } else {
        throw SubscriptionException(
          'Failed to verify payment: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error verifying payment: $e');
      if (e is SubscriptionException) rethrow;
      throw SubscriptionException('Failed to verify payment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry a failed payment
  /// This is a convenience method that returns the transaction details
  /// so the user can navigate back to the payment form
  Future<Transaction?> getFailedTransaction(String transactionId) async {
    try {
      // Ensure payment history is loaded
      if (_paymentHistory.isEmpty) {
        await loadPaymentHistory();
      }

      // Find the transaction
      return _paymentHistory.firstWhere(
        (t) => t.transactionId == transactionId,
        orElse: () => throw SubscriptionException('Transaction not found'),
      );
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error getting failed transaction: $e');
      return null;
    }
  }

  /// Clear all cached data
  void clearCache() {
    _statusCacheTime = null;
    _historyCacheTime = null;
    _currentStatus = null;
    _paymentHistory = [];
    _lastError = null;
    notifyListeners();
    debugPrint('Subscription cache cleared');
  }

  /// Clear error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
