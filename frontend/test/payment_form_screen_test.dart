import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/payment_form_screen.dart';
import 'package:frontend/services/subscription_service.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  group('PaymentFormScreen Widget Tests', () {
    late SubscriptionService mockSubscriptionService;
    late AuthService mockAuthService;

    setUp(() {
      mockSubscriptionService = SubscriptionService();
      mockAuthService = AuthService();
    });

    Widget createTestWidget(String paymentMethod) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SubscriptionService>.value(
            value: mockSubscriptionService,
          ),
          ChangeNotifierProvider<AuthService>.value(
            value: mockAuthService,
          ),
        ],
        child: MaterialApp(
          home: PaymentFormScreen(paymentMethod: paymentMethod),
        ),
      );
    }

    testWidgets('displays bKash fields when payment method is bkash',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('bkash'));
      await tester.pumpAndSettle();

      // Verify bKash-specific fields are present
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('PIN'), findsOneWidget);

      // Verify card fields are not present
      expect(find.text('Card Number'), findsNothing);
      expect(find.text('Expiry Date'), findsNothing);
      expect(find.text('CVV'), findsNothing);
    });

    testWidgets('displays card fields when payment method is debit_card',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('debit_card'));
      await tester.pumpAndSettle();

      // Verify card-specific fields are present
      expect(find.text('Card Number'), findsOneWidget);
      expect(find.text('Expiry Date'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);

      // Verify bKash fields are not present
      expect(find.text('Mobile Number'), findsNothing);
      expect(find.text('PIN'), findsNothing);
    });

    testWidgets('displays card fields when payment method is credit_card',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('credit_card'));
      await tester.pumpAndSettle();

      // Verify card-specific fields are present
      expect(find.text('Card Number'), findsOneWidget);
      expect(find.text('Expiry Date'), findsOneWidget);
      expect(find.text('CVV'), findsOneWidget);

      // Verify bKash fields are not present
      expect(find.text('Mobile Number'), findsNothing);
      expect(find.text('PIN'), findsNothing);
    });

    testWidgets('displays amount to pay', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('bkash'));
      await tester.pumpAndSettle();

      // Verify amount display is present
      expect(find.text('Amount to Pay'), findsOneWidget);
      expect(find.textContaining('BDT'), findsWidgets);
    });

    testWidgets('Pay Now button is disabled initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('bkash'));
      await tester.pumpAndSettle();

      // Find the Pay Now button
      final payButton = find.widgetWithText(ElevatedButton, 'Pay BDT 999.00');
      expect(payButton, findsOneWidget);

      // Verify button is disabled (onPressed is null)
      final button = tester.widget<ElevatedButton>(payButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('validates bKash mobile number format',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('bkash'));
      await tester.pumpAndSettle();

      // Enter invalid mobile number
      await tester.enterText(
        find.widgetWithText(TextFormField, '01XXXXXXXXX'),
        '123456',
      );
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(
        find.text('Invalid mobile number format (01XXXXXXXXX)'),
        findsOneWidget,
      );
    });

    testWidgets('validates card number format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('debit_card'));
      await tester.pumpAndSettle();

      // Enter invalid card number
      await tester.enterText(
        find.widgetWithText(TextFormField, '1234 5678 9012 3456'),
        '1234',
      );
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Invalid card number length'), findsOneWidget);
    });

    testWidgets('validates CVV format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('credit_card'));
      await tester.pumpAndSettle();

      // Enter invalid CVV
      await tester.enterText(
        find.widgetWithText(TextFormField, '123').last,
        '12',
      );
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('CVV must be 3 digits'), findsOneWidget);
    });

    testWidgets('displays security notice', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('bkash'));
      await tester.pumpAndSettle();

      // Verify security notice is present
      expect(
        find.text('Your payment information is secure'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('displays correct payment method name in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget('bkash'));
      await tester.pumpAndSettle();

      expect(find.text('Pay with bKash'), findsOneWidget);

      await tester.pumpWidget(createTestWidget('debit_card'));
      await tester.pumpAndSettle();

      expect(find.text('Pay with Debit Card'), findsOneWidget);

      await tester.pumpWidget(createTestWidget('credit_card'));
      await tester.pumpAndSettle();

      expect(find.text('Pay with Credit Card'), findsOneWidget);
    });
  });
}
