import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/subscription_service.dart';
import '../models/subscription_status.dart';
import '../models/transaction.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/modern_button.dart';
import '../theme/app_colors.dart';
import '../screens/payment_method_screen.dart';

/// Widget that displays subscription status and payment history in Settings
class SubscriptionSection extends StatefulWidget {
  const SubscriptionSection({super.key});

  @override
  State<SubscriptionSection> createState() => _SubscriptionSectionState();
}

class _SubscriptionSectionState extends State<SubscriptionSection> {
  @override
  void initState() {
    super.initState();
    // Load subscription data when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final subscriptionService = context.read<SubscriptionService>();
    try {
      await subscriptionService.loadSubscriptionStatus();
      await subscriptionService.loadPaymentHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subscription data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    final subscriptionService = context.read<SubscriptionService>();
    try {
      await subscriptionService.loadSubscriptionStatus(forceRefresh: true);
      await subscriptionService.loadPaymentHistory(forceRefresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPayment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentMethodScreen(),
      ),
    );
  }

  void _retryPayment(String transactionId) {
    // TODO: Navigate to payment form with transaction details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retry payment for transaction: $transactionId'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, child) {
        final isLoading = subscriptionService.isLoading;
        final status = subscriptionService.currentStatus;
        final history = subscriptionService.paymentHistory;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription Status Card
            _buildStatusCard(status, isLoading),
            
            const SizedBox(height: 24),
            
            // Payment History Section
            _buildPaymentHistorySection(history, isLoading),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(SubscriptionStatus? status, bool isLoading) {
    if (isLoading && status == null) {
      return _buildLoadingCard();
    }

    final isPremium = status?.isPremium ?? false;
    final isFree = status?.isFree ?? true;

    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium : Icons.person_outline,
                color: isPremium ? AppColors.accent : Colors.white70,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Premium Plan' : 'Free Plan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium
                          ? 'Enjoy all premium features'
                          : 'Upgrade to unlock premium features',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _refreshData,
                  tooltip: 'Refresh',
                ),
            ],
          ),
          
          if (isPremium && status != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            _buildRenewalInfo(status),
          ],
          
          if (isFree) ...[
            const SizedBox(height: 20),
            ModernButton(
              label: 'Upgrade to Premium',
              icon: Icons.arrow_forward,
              onPressed: _navigateToPayment,
              variant: ModernButtonVariant.primary,
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRenewalInfo(SubscriptionStatus status) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Column(
      children: [
        if (status.activatedAt != null)
          _buildInfoRow(
            'Activated',
            dateFormat.format(status.activatedAt!),
            Icons.check_circle_outline,
          ),
        if (status.expiresAt != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            'Expires',
            dateFormat.format(status.expiresAt!),
            Icons.event_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistorySection(
    List<Transaction> history,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (isLoading && history.isEmpty)
          _buildLoadingCard()
        else if (history.isEmpty)
          _buildEmptyHistoryCard()
        else
          _buildHistoryList(history),
      ],
    );
  }

  Widget _buildHistoryList(List<Transaction> history) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < history.length; i++) ...[
            _buildTransactionItem(history[i]),
            if (i < history.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white10, height: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final isSuccess = transaction.isSuccess;
    final isFailed = transaction.isFailed;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Success';
    } else if (isFailed) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Failed';
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pending';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPaymentMethodIcon(transaction.paymentMethod),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatPaymentMethod(transaction.paymentMethod),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(transaction.createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Transaction ID: ${transaction.transactionId}',
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        
        if (isFailed) ...[
          const SizedBox(height: 12),
          ModernButton(
            label: 'Retry Payment',
            icon: Icons.refresh,
            onPressed: () => _retryPayment(transaction.transactionId),
            variant: ModernButtonVariant.outline,
            width: double.infinity,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingCard() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryCard() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No payment history yet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to premium to get started!',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ModernButton(
            label: 'Upgrade Now',
            icon: Icons.arrow_forward,
            onPressed: _navigateToPayment,
            variant: ModernButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'bkash':
        return Icons.phone_android;
      case 'debit_card':
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bkash':
        return 'bKash';
      case 'debit_card':
        return 'Debit Card';
      case 'credit_card':
        return 'Credit Card';
      default:
        return method;
    }
  }
}
