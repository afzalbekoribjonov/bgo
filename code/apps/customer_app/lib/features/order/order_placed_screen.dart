import 'package:flutter/material.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import 'my_orders_screen.dart';
import 'order_models.dart';

/// Buyurtma muvaffaqiyatli berildi — tasdiq ekrani. plan/05-customer-app.md
class OrderPlacedScreen extends StatelessWidget {
  final OrderView order;
  const OrderPlacedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 96, color: Colors.green),
              const SizedBox(height: 16),
              Text(t.orderPlacedTitle,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(t.orderPlacedDesc, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(t.orderNo(order.publicNo.toString()),
                  style: Theme.of(context).textTheme.titleMedium),
              Text(t.priceSom(groupThousands(order.total)),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style:
                    FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(t.backToHome),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  );
                },
                child: Text(t.myOrders),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
