import 'package:flutter/material.dart';
class UnderReviewScreen extends StatelessWidget {
  const UnderReviewScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              SizedBox(height: 24),
              Text(
                'حسابك قيد المراجعة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'نقوم حالياً بمراجعة مستنداتك. سيتم إشعارك فور التحقق.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
