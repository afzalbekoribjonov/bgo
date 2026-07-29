import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../parcel/parcel_api.dart';
import '../taxi/taxi_api.dart';
import 'order_api.dart';
import 'order_detail_screen.dart';
import 'order_status.dart';

/// Barcha turdagi buyurtmalar tarixi — Ovqat / Taksi / Dostavka.
/// plan/05-customer-app.md
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.myOrders),
          bottom: TabBar(
            tabs: [
              Tab(text: t.serviceFood),
              Tab(text: t.taxiTitle),
              Tab(text: t.parcelTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FoodTab(),
            _TaxiTab(),
            _ParcelTab(),
          ],
        ),
      ),
    );
  }
}

/// Ovqat buyurtmalari (bosilsa — tafsilot).
class _FoodTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(myOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myOrdersProvider),
      ),
      data: (orders) {
        if (orders.isEmpty) return _Empty(t.noOrders);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myOrdersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              final scheme = Theme.of(context).colorScheme;
              final statusColor = orderStatusColor(order.status);
              final dt = DateTime.tryParse(order.createdAt)?.toLocal();
              final date = dt == null
                  ? ''
                  : '${dt.day.toString().padLeft(2, "0")}.${dt.month.toString().padLeft(2, "0")} '
                      '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
              final preview = order.items.isEmpty
                  ? ''
                  : order.items
                          .take(2)
                          .map((it) => '${it.name} ×${it.qty}')
                          .join(', ') +
                      (order.items.length > 2
                          ? ' +${order.items.length - 2} ta'
                          : '');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: order.id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: Color(0xFF2E7D32), size: 17),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.orderNo(order.publicNo.toString()),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  if (date.isNotEmpty)
                                    Text(date,
                                        style: TextStyle(
                                            color: scheme.outline,
                                            fontSize: 10.5)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                orderStatusLabel(order.status, t),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            if (preview.isNotEmpty) ...[
                              Icon(Icons.restaurant_menu_rounded,
                                  size: 13, color: scheme.outline),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  preview,
                                  style: TextStyle(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.72),
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else
                              const Spacer(),
                            const SizedBox(width: 8),
                            Text(
                              t.priceSom(groupThousands(order.total)),
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: scheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Taksi safarlari tarixi.
class _TaxiTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(myTripsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myTripsProvider),
      ),
      data: (trips) {
        if (trips.isEmpty) return _Empty(t.noOrders);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myTripsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: trips.length,
            itemBuilder: (context, i) {
              final trip = trips[i];
              final (label, color) = _taxiStatus(t, trip.status);
              final scheme = Theme.of(context).colorScheme;
              final route = trip.destinationText.isEmpty
                  ? trip.pickupText
                  : '${trip.pickupText} → ${trip.destinationText}';
              final tripDt = DateTime.tryParse(trip.createdAt)?.toLocal();
              final tripDate = tripDt == null
                  ? ''
                  : '${tripDt.day.toString().padLeft(2, "0")}.${tripDt.month.toString().padLeft(2, "0")} '
                      '${tripDt.hour.toString().padLeft(2, "0")}:${tripDt.minute.toString().padLeft(2, "0")}';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6A609)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_taxi_rounded,
                                color: Color(0xFFF6A609), size: 17),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.taxiTitle} #${trip.publicNo}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                if (tripDate.isNotEmpty)
                                  Text(tripDate,
                                      style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 10.5)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.35)),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          if (route.isNotEmpty) ...[
                            Icon(Icons.route_rounded,
                                size: 13, color: scheme.outline),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(route,
                                  style: TextStyle(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.72),
                                      fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ] else
                            const Spacer(),
                          const SizedBox(width: 8),
                          Text(
                            t.priceSom(groupThousands(trip.displayFare)),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: scheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Dostavka tarixi.
class _ParcelTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(myParcelsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myParcelsProvider),
      ),
      data: (parcels) {
        if (parcels.isEmpty) return _Empty(t.noOrders);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myParcelsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: parcels.length,
            itemBuilder: (context, i) {
              final p = parcels[i];
              final (label, color) = _parcelStatus(t, p.status);
              final scheme = Theme.of(context).colorScheme;
              final pDt = DateTime.tryParse(p.createdAt)?.toLocal();
              final pDate = pDt == null
                  ? ''
                  : '${pDt.day.toString().padLeft(2, "0")}.${pDt.month.toString().padLeft(2, "0")} '
                      '${pDt.hour.toString().padLeft(2, "0")}:${pDt.minute.toString().padLeft(2, "0")}';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping_rounded,
                                color: Color(0xFF1565C0), size: 17),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t.parcelTitle} #${p.publicNo}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                if (pDate.isNotEmpty)
                                  Text(pDate,
                                      style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 10.5)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.35)),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(Icons.route_rounded,
                              size: 13, color: scheme.outline),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${p.pickupText} → ${p.destinationText}',
                              style: TextStyle(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.72),
                                  fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.priceSom(groupThousands(p.displayFare)),
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: scheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

(String, Color) _taxiStatus(AppLocalizations t, String status) {
  switch (status) {
    case 'ACCEPTED':
      return (t.taxiStatusAccepted, Colors.blue);
    case 'ARRIVED':
      return ('Haydovchi yetib keldi', const Color(0xFF2E7D32));
    case 'IN_PROGRESS':
      return (t.taxiStatusInProgress, Colors.orange);
    case 'COMPLETED':
      return (t.taxiStatusCompleted, Colors.green);
    case 'CANCELLED':
      return (t.taxiStatusCancelled, Colors.red);
    default:
      return (t.taxiStatusPending, Colors.grey);
  }
}

(String, Color) _parcelStatus(AppLocalizations t, String status) {
  switch (status) {
    case 'ACCEPTED':
      return (t.parcelStatusAccepted, Colors.blue);
    case 'ARRIVED':
      return ('Kuryer yetib keldi', const Color(0xFF2E7D32));
    case 'PICKED_UP':
      return (t.parcelStatusPickedUp, Colors.orange);
    case 'IN_TRANSIT':
      return ("Yo'lda", Colors.orange);
    case 'DELIVERED':
      return (t.parcelStatusDelivered, Colors.green);
    case 'CANCELLED':
      return (t.parcelStatusCancelled, Colors.red);
    default:
      return (t.parcelStatusPending, Colors.grey);
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text,
          style: TextStyle(color: Theme.of(context).colorScheme.outline)),
    );
  }
}
