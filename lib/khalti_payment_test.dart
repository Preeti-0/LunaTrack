import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

class KhaltiPaymentTest extends StatelessWidget {
  const KhaltiPaymentTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Khalti Payment")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            KhaltiScope.of(context).pay(
              config: PaymentConfig(
                amount: 1000, // Rs. 10 in paisa
                productIdentity: 'test_product_01',
                productName: 'Test Product',
              ),
              preferences: [PaymentPreference.khalti],
              onSuccess: (success) {
                debugPrint("✅ Payment Successful! Token: ${success.token}");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Payment successful")),
                );
              },
              onFailure: (failure) {
                debugPrint("❌ Payment Failed: ${failure.message}");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Payment failed")),
                );
              },
              onCancel: () {
                debugPrint("⚠️ Payment Cancelled");
              },
            );
          },
          child: const Text("Pay Rs. 10 with Khalti"),
        ),
      ),
    );
  }
}
