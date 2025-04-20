import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

class KhaltiPaymentTest extends StatelessWidget {
  const KhaltiPaymentTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Khalti Test")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Pay Rs. 10 with Khalti"),
          onPressed: () {
            KhaltiScope.of(context).pay(
              config: PaymentConfig(
                amount: 1000, // Rs. 10 = 1000 paisa
                productIdentity: 'luna-doctor-payment',
                productName: 'Doctor Booking',
              ),
              preferences: [PaymentPreference.khalti],
              onSuccess: (success) {
                debugPrint("✅ Payment Successful");
                debugPrint("Token: ${success.token}");
                debugPrint("Amount: ${success.amount}");

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment Successful ✅")),
                );
              },
              onFailure: (failure) {
                debugPrint("❌ Payment Failed: ${failure.message}");
              },
              onCancel: () {
                debugPrint("⚠️ Payment Cancelled");
              },
            );
          },
        ),
      ),
    );
  }
}
