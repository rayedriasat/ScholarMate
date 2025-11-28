import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/ui/glass_container.dart';
import '../widgets/ui/animated_background.dart';
import '../theme/app_colors.dart';
import '../services/config_service.dart';
import '../services/subscription_service.dart';
import 'payment_success_screen.dart';
import 'payment_failed_screen.dart';

/// Payment form screen for entering payment credentials
/// Displays method-specific fields based on selected payment method
class PaymentFormScreen extends StatefulWidget {
  final String paymentMethod; // 'bkash', 'debit_card', or 'credit_card'

  const PaymentFormScreen({
    super.key,
    required this.paymentMethod,
  });

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _config = ConfigService();

  // bKash fields
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();

  // Card fields
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Amount field (pre-filled from config)
  late final double _amount;
  final String _currency = 'BDT';

  bool _isFormValid = false;
  bool _obscurePin = true;
  bool _obscureCvv = true;
  bool _isProcessing = false;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    // Get premium price from config (default to 999.00 if not set)
    _amount = double.tryParse(
          const String.fromEnvironment('PREMIUM_PRICE', defaultValue: '999.00'),
        ) ??
        999.00;

    // Add listeners to validate form on every change
    if (widget.paymentMethod == 'bkash') {
      _mobileController.addListener(_validateForm);
      _pinController.addListener(_validateForm);
    } else {
      _cardNumberController.addListener(_validateForm);
      _expiryController.addListener(_validateForm);
      _cvvController.addListener(_validateForm);
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  /// Validate the entire form and update button state
  void _validateForm() {
    setState(() {
      _isFormValid = _formKey.currentState?.validate() ?? false;
    });
  }

  /// Validate bKash mobile number format (01XXXXXXXXX)
  String? _validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number is required';
    }
    if (!RegExp(r'^01[0-9]{9}$').hasMatch(value)) {
      return 'Invalid mobile number format (01XXXXXXXXX)';
    }
    return null;
  }

  /// Validate bKash PIN
  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    if (value.length < 4) {
      return 'PIN must be at least 4 digits';
    }
    return null;
  }

  /// Validate card number using Luhn algorithm
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    // Remove spaces
    final cardNumber = value.replaceAll(' ', '');

    // Check if it's all digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cardNumber)) {
      return 'Card number must contain only digits';
    }

    // Check length (13-19 digits for most cards)
    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Invalid card number length';
    }

    // Luhn algorithm validation
    if (!_luhnCheck(cardNumber)) {
      return 'Invalid card number';
    }

    return null;
  }

  /// Luhn algorithm for card number validation
  bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Validate expiry date (MM/YY format, must be future date)
  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    // Check format MM/YY
    if (!RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$').hasMatch(value)) {
      return 'Invalid format (MM/YY)';
    }

    // Parse month and year
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');

    // Check if date is in the future
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month

    if (expiryDate.isBefore(now)) {
      return 'Card has expired';
    }

    return null;
  }

  /// Validate CVV (3 digits)
  String? _validateCvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    if (!RegExp(r'^[0-9]{3}$').hasMatch(value)) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  /// Format card number with spaces (XXXX XXXX XXXX XXXX)
  String _formatCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  /// Format expiry date with slash (MM/YY)
  String _formatExpiry(String value) {
    final cleaned = value.replaceAll('/', '');
    if (cleaned.length >= 2) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
    }
    return cleaned;
  }

  /// Get payment method display name
  String get _paymentMethodName {
    switch (widget.paymentMethod) {
      case 'bkash':
        return 'bKash';
      case 'debit_card':
        return 'Debit Card';
      case 'credit_card':
        return 'Credit Card';
      default:
        return 'Payment';
    }
  }

  /// Get payment method icon
  IconData get _paymentMethodIcon {
    switch (widget.paymentMethod) {
      case 'bkash':
        return Icons.phone_android;
      case 'debit_card':
        return Icons.credit_card;
      case 'credit_card':
        return Icons.credit_score;
      default:
        return Icons.payment;
    }
  }

  /// Get payment method color
  Color get _paymentMethodColor {
    switch (widget.paymentMethod) {
      case 'bkash':
        return AppColors.accent;
      case 'debit_card':
        return AppColors.primary;
      case 'credit_card':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 500.0 : screenWidth;

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(
                  'Pay with $_paymentMethodName',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                snap: true,
                iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
              ),
              SliverSafeArea(
                sliver: SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Payment method header
                        _buildPaymentMethodHeader(),
                        const SizedBox(height: 24),

                        // Amount display
                        _buildAmountDisplay(),
                        const SizedBox(height: 24),

                        // Payment method specific fields
                        if (widget.paymentMethod == 'bkash')
                          _buildBkashFields()
                        else
                          _buildCardFields(),

                        const SizedBox(height: 24),

                        // Pay Now button
                        _buildPayNowButton(),

                        const SizedBox(height: 16),

                        // Security notice
                        _buildSecurityNotice(),
                      ],
                    ),
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

  Widget _buildPaymentMethodHeader() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16),
      border: Border.all(color: Theme.of(context).dividerColor),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _paymentMethodColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _paymentMethodIcon,
              color: _paymentMethodColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentMethodName,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enter your payment details',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      color: _paymentMethodColor.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: _paymentMethodColor.withValues(alpha: 0.3),
        width: 1,
      ),
      child: Column(
        children: [
          Text(
            'Amount to Pay',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_currency ${_amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: _paymentMethodColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Premium Subscription (1 Year)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBkashFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mobile Number field
        _buildTextField(
          controller: _mobileController,
          label: 'Mobile Number',
          hint: '01XXXXXXXXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: _validateMobileNumber,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 20),

        // PIN field
        _buildTextField(
          controller: _pinController,
          label: 'PIN',
          hint: 'Enter your bKash PIN',
          icon: Icons.lock,
          keyboardType: TextInputType.number,
          validator: _validatePin,
          obscureText: _obscurePin,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePin ? Icons.visibility : Icons.visibility_off,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onPressed: () => setState(() => _obscurePin = !_obscurePin),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card Number field
        _buildTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          validator: _validateCardNumber,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            _CardNumberFormatter(),
          ],
        ),
        const SizedBox(height: 20),

        // Expiry and CVV row
        Row(
          children: [
            // Expiry Date field
            Expanded(
              child: _buildTextField(
                controller: _expiryController,
                label: 'Expiry Date',
                hint: 'MM/YY',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: _validateExpiry,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // CVV field
            Expanded(
              child: _buildTextField(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.security,
                keyboardType: TextInputType.number,
                validator: _validateCvv,
                obscureText: _obscureCvv,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCvv ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  onPressed: () => setState(() => _obscureCvv = !_obscureCvv),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            prefixIcon: Icon(
              icon,
              color: _paymentMethodColor,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _paymentMethodColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowButton() {
    return ElevatedButton(
      onPressed: (_isFormValid && !_isProcessing) ? _handlePayNow : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _paymentMethodColor,
        disabledBackgroundColor: Theme.of(context).disabledColor,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: (_isFormValid && !_isProcessing) ? 4 : 0,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Pay $_currency ${_amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecurityNotice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Text(
          'Your payment information is secure',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayNow() async {
    // Validate form one more time
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final subscriptionService = context.read<SubscriptionService>();

      // Step 1: Initialize payment
      final initResponse = await _initializePayment(subscriptionService);

      if (!initResponse['success']) {
        throw Exception(initResponse['message'] ?? 'Failed to initialize payment');
      }

      _transactionId = initResponse['transaction_id'];

      // Step 2: Verify payment with credentials
      final verifyResponse = await _verifyPayment(subscriptionService);

      if (!mounted) return;

      // Step 3: Navigate based on result
      if (verifyResponse['success'] == true) {
        _navigateToSuccess(verifyResponse);
      } else {
        _navigateToFailure(verifyResponse);
      }
    } catch (e) {
      if (!mounted) return;

      // Handle network errors with retry option
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Initialize payment transaction
  Future<Map<String, dynamic>> _initializePayment(
    SubscriptionService subscriptionService,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        return await subscriptionService.initializePayment(
          paymentMethod: widget.paymentMethod,
          amount: _amount,
          currency: _currency,
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (retryCount - 1)));
      }
    }

    throw Exception('Failed to initialize payment after $maxRetries attempts');
  }

  /// Verify payment with credentials
  Future<Map<String, dynamic>> _verifyPayment(
    SubscriptionService subscriptionService,
  ) async {
    if (_transactionId == null) {
      throw Exception('Transaction ID is null');
    }

    // Build payment credentials based on payment method
    final credentials = _buildPaymentCredentials();

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        return await subscriptionService.verifyPayment(
          transactionId: _transactionId!,
          paymentCredentials: credentials,
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << (retryCount - 1)));
      }
    }

    throw Exception('Failed to verify payment after $maxRetries attempts');
  }

  /// Build payment credentials based on payment method
  Map<String, dynamic> _buildPaymentCredentials() {
    if (widget.paymentMethod == 'bkash') {
      return {
        'mobile_number': _mobileController.text,
        'pin': _pinController.text,
      };
    } else {
      // Card payment (debit or credit)
      return {
        'card_number': _cardNumberController.text.replaceAll(' ', ''),
        'cvv': _cvvController.text,
        'expiry': _expiryController.text,
      };
    }
  }

  /// Navigate to success page
  void _navigateToSuccess(Map<String, dynamic> response) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          transactionId: response['transaction_id'] ?? _transactionId ?? 'N/A',
          amount: response['amount']?.toDouble() ?? _amount,
          currency: _currency,
        ),
      ),
    );
  }

  /// Navigate to failure page
  void _navigateToFailure(Map<String, dynamic> response) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentFailedScreen(
          transactionId: response['transaction_id'] ?? _transactionId,
          errorMessage: response['message'] ?? 'Payment could not be processed',
          paymentMethod: widget.paymentMethod,
        ),
      ),
    );
  }

  /// Show error dialog with retry option
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Payment Error',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'An error occurred while processing your payment:\n\n$error\n\nPlease check your internet connection and try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePayNow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _paymentMethodColor,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Text input formatter for card number (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Text input formatter for expiry date (adds slash after 2 digits)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return newValue;
  }
}
