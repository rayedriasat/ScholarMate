import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/ui/glass_container.dart';
import '../theme/app_colors.dart';

/// Payment success screen displayed after successful payment
/// Shows transaction details and premium activation confirmation
class PaymentSuccessScreen extends StatelessWidget {
  final String transactionId;
  final double amount;
  final String currency;

  const PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    this.currency = 'BDT',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Payment Successful',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Success icon
              _buildSuccessIcon(),
              const SizedBox(height: 32),

              // Premium activation banner
              _buildPremiumBanner(),
              const SizedBox(height: 32),

              // Transaction details
              _buildTransactionDetails(context),
              const SizedBox(height: 32),

              // Back to Settings button
              _buildBackButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.green,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.accent.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(24),
      border: Border.all(
        color: AppColors.accent.withValues(alpha: 0.3),
        width: 2,
      ),
      child: Column(
        children: [
          // Premium icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.2),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // Premium activated text
          const Text(
            'Premium Subscription Activated',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'You now have access to all premium features',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Transaction Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Transaction ID
          _buildDetailRow(
            context,
            icon: Icons.receipt_long,
            label: 'Transaction ID',
            value: transactionId,
            copyable: true,
          ),
          const SizedBox(height: 16),

          // Amount paid
          _buildDetailRow(
            context,
            icon: Icons.payments,
            label: 'Amount Paid',
            value: '$currency ${amount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 16),

          // Status
          _buildDetailRow(
            context,
            icon: Icons.check_circle_outline,
            label: 'Status',
            value: 'Success',
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Icon(
          icon,
          color: AppColors.accent,
          size: 20,
        ),
        const SizedBox(width: 12),

        // Label and value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (copyable)
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      onPressed: () => _copyToClipboard(context, value),
                      tooltip: 'Copy',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateToSettings(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 20),
          SizedBox(width: 8),
          Text(
            'Back to Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction ID copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Pop all routes until we reach the first route (home/main screen)
    // This ensures we go back to the main app, where Settings is accessible
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
