import 'package:flutter/material.dart';
import '../widgets/ui/glass_container.dart';
import '../theme/app_colors.dart';
import 'payment_form_screen.dart';

/// Payment method selection screen for subscription upgrade
/// Displays three payment options: bKash, Debit Card, and Credit Card
class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Select Payment Method',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header text
              const Text(
                'Choose your preferred payment method',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Payment method cards
              Expanded(
                child: ListView(
                  children: [
                    _PaymentMethodCard(
                      icon: Icons.phone_android,
                      title: 'bKash',
                      subtitle: 'Pay with your mobile wallet',
                      color: AppColors.accent,
                      onTap: () => _navigateToPaymentForm(context, 'bkash'),
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodCard(
                      icon: Icons.credit_card,
                      title: 'Debit Card',
                      subtitle: 'Pay with your debit card',
                      color: AppColors.primary,
                      onTap: () => _navigateToPaymentForm(context, 'debit_card'),
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodCard(
                      icon: Icons.credit_score,
                      title: 'Credit Card',
                      subtitle: 'Pay with your credit card',
                      color: AppColors.secondary,
                      onTap: () => _navigateToPaymentForm(context, 'credit_card'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPaymentForm(BuildContext context, String paymentMethod) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(
          paymentMethod: paymentMethod,
        ),
      ),
    );
  }
}

/// Individual payment method selection card
class _PaymentMethodCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.02 : 1.0),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: _isHovered ? 2 : 1,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: _isHovered
                      ? widget.color
                      : Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
