/// Model representing a payment transaction
class Transaction {
  final String transactionId;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  Transaction({
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
  });

  /// Create from JSON response
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'] as String,
      paymentMethod: json['payment_method'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'amount': amount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  /// Check if transaction was successful
  bool get isSuccess => status == 'success';

  /// Check if transaction failed
  bool get isFailed => status == 'failed';

  /// Check if transaction is pending
  bool get isPending => status == 'pending';

  @override
  String toString() {
    return 'Transaction(id: $transactionId, method: $paymentMethod, '
        'amount: $amount $currency, status: $status)';
  }
}
