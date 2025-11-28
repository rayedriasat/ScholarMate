import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/animated_background.dart';
import '../theme/app_colors.dart';

/// Payment failed screen displayed after unsuccessful payment
/// Shows error message and provides retry option
class PaymentFailedScreen extends StatelessWidget {
  final String? transactionId;
  final String errorMessage;
  final String? paymentMethod;

  const PaymentFailedScreen({
    super.key,
    this.transactionId,
    required this.errorMessage,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: AnimatedBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(
                  'Payment Failed',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
              ),
              SliverSafeArea(
                sliver: SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width > 600 ? 500.0 : MediaQuery.of(context).size.width,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const SizedBox(height: 20),

                  // Error icon
                  _buildErrorIcon(),
                  const SizedBox(height: 32),

                  // Error message
                  _buildErrorMessage(),
                  const SizedBox(height: 32),

                  // Transaction details (if available)
                  if (transactionId != null) ...[
                    _buildTransactionDetails(context),
                    const SizedBox(height: 32),
                  ],

                  // Action buttons
                  _buildActionButtons(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorIcon() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.2),
          border: Border.all(
            color: Colors.red,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: Colors.red.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(24),
      border: Border.all(
        color: Colors.red.withValues(alpha: 0.3),
        width: 2,
      ),
      child: Column(
        children: [
          // Error title
          const Text(
            'Payment Unsuccessful',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Error message
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Help text
          Text(
            'Please check your payment details and try again',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
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
            value: transactionId!,
            copyable: true,
          ),
          const SizedBox(height: 16),

          // Status
          _buildDetailRow(
            context,
            icon: Icons.cancel_outlined,
            label: 'Status',
            value: 'Failed',
            valueColor: Colors.red,
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
          color: Colors.red,
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Retry Payment button
        ElevatedButton(
          onPressed: () => _retryPayment(context),
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
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text(
                'Retry Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Back to Settings button
        OutlinedButton(
          onPressed: () => _navigateToSettings(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        ),
      ],
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

  void _retryPayment(BuildContext context) {
    // Pop back to the payment form screen
    // This will allow the user to correct their payment details and try again
    Navigator.of(context).pop();
  }

  void _navigateToSettings(BuildContext context) {
    // Pop all routes until we reach the first route (home/main screen)
    // This ensures we go back to the main app, where Settings is accessible
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
