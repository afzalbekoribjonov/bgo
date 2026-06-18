import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'order_api.dart';
import 'order_detail_screen.dart';
import 'order_status.dart';

/// Mening buyurtmalarim ro'yxati. plan/05-customer-app.md
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.myOrders)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) return Center(child: Text(t.noOrders));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final order = orders[i];
                return Card(
                  child: ListTile(
                    title: Text(t.orderNo(order.publicNo.toString())),
                    subtitle: Text(t.priceSom(groupThousands(order.total))),
                    trailing: Text(
                      orderStatusLabel(order.status, t),
                      style: TextStyle(
                        color: orderStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
