import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'order_api.dart';
import 'order_status.dart';

/// Buyurtma tafsilotlari + bekor qilish (PENDING bo'lsa). plan/05-customer-app.md
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(orderApiProvider).cancelOrder(widget.orderId);
      ref.invalidate(orderProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(orderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: async.maybeWhen(
          data: (o) => Text(t.orderNo(o.publicNo.toString())),
          orElse: () => Text(t.myOrders),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(orderProvider(widget.orderId)),
        ),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  orderStatusLabel(order.status, t),
                  style: TextStyle(
                    color: orderStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            for (final item in order.items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${item.name} × ${item.qty}'),
                trailing: Text(t.priceSom(groupThousands(item.lineTotal))),
              ),
            const Divider(height: 24),
            _row(context, t.subtotalLabel, order.itemsTotal),
            _row(context, t.deliveryFeeLabel, order.deliveryFee),
            if (order.discount > 0)
              _row(context, t.discountLabel, -order.discount),
            const SizedBox(height: 4),
            _row(context, t.totalLabel, order.total, bold: true),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(order.addressText),
            ),
            if (order.status == 'PENDING') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(t.cancelOrder),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, int amount,
      {bool bold = false}) {
    final t = AppLocalizations.of(context)!;
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(t.priceSom(groupThousands(amount)), style: style),
        ],
      ),
    );
  }
}
