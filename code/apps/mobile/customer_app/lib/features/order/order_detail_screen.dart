import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../../widgets/brand.dart';
import 'food_tracking_screen.dart';
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
        data: (order) {
          final scheme = Theme.of(context).colorScheme;
          final statusColor = orderStatusColor(order.status);
          final dt = DateTime.tryParse(order.createdAt)?.toLocal();
          final date = dt == null
              ? ''
              : '${dt.day.toString().padLeft(2, "0")}.${dt.month.toString().padLeft(2, "0")}.${dt.year} '
                  '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Status kartasi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_statusIcon(order.status),
                          color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderStatusLabel(order.status, t),
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16),
                          ),
                          if (date.isNotEmpty)
                            Text(date,
                                style: TextStyle(
                                    color: scheme.outline, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buyurtma tarkibi
              Text('Buyurtma tarkibi',
                  style: theme(context).textTheme.titleSmall?.copyWith(
                      color: scheme.outline, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              for (final item in order.items)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${item.qty}',
                            style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                      ),
                      Text(
                        t.priceSom(groupThousands(item.lineTotal)),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Narxlar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _priceRow(context, t.subtotalLabel, order.itemsTotal, t),
                    const SizedBox(height: 6),
                    _priceRow(context, t.deliveryFeeLabel, order.deliveryFee, t),
                    if (order.discount > 0) ...[
                      const SizedBox(height: 6),
                      _priceRow(
                          context, t.discountLabel, -order.discount, t),
                    ],
                    const Divider(height: 20),
                    _priceRow(context, t.totalLabel, order.total, t,
                        bold: true, large: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Manzil
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_on_rounded,
                          color: scheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(order.addressText,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
              // Faol buyurtma — jonli kuzatuvga o'tish (xarita + ETA).
              if (order.isActive) ...[
                const SizedBox(height: 20),
                BrandButton(
                  label: 'Jonli kuzatuv',
                  icon: Icons.map_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          FoodTrackingScreen(orderId: order.id),
                    ),
                  ),
                ),
              ],
              if (order.status == 'PENDING') ...[
                const SizedBox(height: 20),
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
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_empty_rounded;
      case 'ACCEPTED':
        return Icons.check_circle_outline_rounded;
      case 'PREPARING':
        return Icons.restaurant_rounded;
      case 'READY':
        return Icons.done_all_rounded;
      case 'PICKED_UP':
      case 'IN_PROGRESS':
        return Icons.delivery_dining_rounded;
      case 'DELIVERED':
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
      case 'FAILED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

ThemeData theme(BuildContext context) => Theme.of(context);

Widget _priceRow(
    BuildContext context, String label, int amount, AppLocalizations t,
    {bool bold = false, bool large = false}) {
  final scheme = Theme.of(context).colorScheme;
  final style = large
      ? TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: scheme.onSurface)
      : bold
          ? const TextStyle(fontWeight: FontWeight.w700)
          : TextStyle(color: scheme.onSurface.withValues(alpha: 0.8));
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: style),
      Text(
        t.priceSom(groupThousands(amount)),
        style: large
            ? TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: scheme.primary)
            : style,
      ),
    ],
  );
}
