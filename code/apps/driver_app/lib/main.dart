import 'package:flutter/material.dart';

void main() => runApp(const DriverApp());

/// Beshariq haydovchi ilovasi — Faza 0 skeleti (placeholder).
/// To'liq mantiq (online holat, fon GPS, buyurtma taklifi, kuryer/taksi oqimi)
/// Faza 3 da quriladi. Reja: plan/06-driver-app.md
class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beshariq Haydovchi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      home: const _DriverHome(),
    );
  }
}

class _DriverHome extends StatelessWidget {
  const _DriverHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beshariq Haydovchi')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping, size: 64),
              SizedBox(height: 16),
              Text(
                'Haydovchi ilovasi — Faza 3',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Online holat, fon GPS, buyurtma taklifi va kuryer/taksi oqimi shu yerda bo\'ladi.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
