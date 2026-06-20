import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoInternetApp extends StatelessWidget {
  const NoInternetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.signal_wifi_off, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
