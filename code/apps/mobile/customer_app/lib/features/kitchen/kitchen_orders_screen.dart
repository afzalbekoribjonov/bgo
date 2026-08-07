import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../widgets/async_error.dart';
import 'kitchen_api.dart';
import 'kitchen_models.dart';
import 'kitchen_order_chat_screen.dart';

/// Faol buyurtmalar — 4s poll (restaurant_web bilan bir xil), qabul/tayyorlash/
/// tayyor/rad amallari.
class KitchenOrdersScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const KitchenOrdersScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<KitchenOrdersScreen> createState() => _KitchenOrdersScreenState();
}

class _KitchenOrdersScreenState extends ConsumerState<KitchenOrdersScreen> {
  Timer? _timer;
  List<KitchenOrder>? _orders;
  Object? _error;
  bool _loading = true;
  final _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final orders = await ref.read(kitchenApiProvider).orders(widget.restaurantId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent || _orders == null) _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _act(KitchenOrder order, String action) async {
    setState(() => _busyIds.add(order.id));
    try {
      await ref.read(kitchenApiProvider).orderAction(order.id, action);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(order.id));
    }
  }

  Future<void> _confirmReject(KitchenOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buyurtmani rad etish'),
        content: Text('#${order.publicNo} buyurtmasini rad etmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rad etish'),
          ),
        ],
      ),
    );
    if (ok == true) await _act(order, 'reject');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _orders == null) {
      return Center(child: AsyncErrorRetry(error: _error!, onRetry: _load));
    }
    final orders = _orders ?? const [];
    if (orders.isEmpty) {
      return const _EmptyState(icon: Icons.receipt_long_outlined, title: 'Hozircha buyurtma yo\'q');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          busy: _busyIds.contains(orders[i].id),
          onAccept: () => _act(orders[i], 'accept'),
          onPreparing: () => _act(orders[i], 'preparing'),
          onReady: () => _act(orders[i], 'ready'),
          onReject: () => _confirmReject(orders[i]),
          onChat: orders[i].driverId != null
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => KitchenOrderChatScreen(orderId: orders[i].id, publicNo: orders[i].publicNo),
                  ))
              : null,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final KitchenOrder order;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onPreparing;
  final VoidCallback onReady;
  final VoidCallback onReject;
  final VoidCallback? onChat;

  const _OrderCard({
    required this.order,
    required this.busy,
    required this.onAccept,
    required this.onPreparing,
    required this.onReady,
    required this.onReject,
    this.onChat,
  });

  (String, Color) get _statusMeta => switch (order.status) {
        KitchenOrderStatus.pending => ('Yangi', const Color(0xFFEF6C00)),
        KitchenOrderStatus.accepted => ('Qabul qilindi', const Color(0xFF1565C0)),
        KitchenOrderStatus.preparing => ('Tayyorlanmoqda', const Color(0xFF6A1B9A)),
        KitchenOrderStatus.ready => ('Tayyor — kuryer kutilmoqda', const Color(0xFF2E7D32)),
        KitchenOrderStatus.assigned => ('Kuryer biriktirildi', const Color(0xFF00838F)),
        KitchenOrderStatus.inProgress => ('Kuryer yo\'lda', const Color(0xFF00838F)),
        KitchenOrderStatus.pickedUp => ('Kuryer oldi', const Color(0xFF00838F)),
        _ => ('Faol', const Color(0xFF616161)),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = _statusMeta;
    final itemsText = order.items.map((i) => '${i.nameSnapshot} ×${i.qty}').join(', ');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${order.publicNo}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11.5)),
                ),
                const Spacer(),
                if (onChat != null)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    onPressed: onChat,
                    tooltip: 'Kuryer bilan suhbat',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(itemsText, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(order.addressText, style: TextStyle(color: scheme.outline, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${_formatSom(order.itemsTotal)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary, fontSize: 15)),
                const Spacer(),
                ..._actions(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    if (busy) {
      return const [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))];
    }
    switch (order.status) {
      case KitchenOrderStatus.pending:
        return [
          TextButton(onPressed: onReject, child: const Text('Rad etish')),
          const SizedBox(width: 4),
          FilledButton(onPressed: onAccept, child: const Text('Qabul qilish')),
        ];
      case KitchenOrderStatus.accepted:
        return [FilledButton(onPressed: onPreparing, child: const Text('Tayyorlashni boshlash'))];
      case KitchenOrderStatus.preparing:
        return [FilledButton(onPressed: onReady, child: const Text('Tayyor'))];
      default:
        return const [];
    }
  }
}

String _formatSom(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  const _EmptyState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: scheme.outline, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
