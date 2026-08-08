import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/alert_sound.dart';
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
  Set<String> _pendingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    ref.read(alertSoundProvider).stop();
    super.dispose();
  }

  /// Yangi ("pending") buyurtma paydo bo'lganda takrorlanuvchi ovoz +
  /// vibratsiya boshlaydi; barcha yangi buyurtmalar hal qilinganda to'xtaydi.
  void _syncAlert(List<KitchenOrder> orders) {
    final nowPending = orders
        .where((o) => o.status == KitchenOrderStatus.pending)
        .map((o) => o.id)
        .toSet();
    final hasNew = nowPending.difference(_pendingIds).isNotEmpty;
    _pendingIds = nowPending;
    if (hasNew) {
      ref.read(alertSoundProvider).start();
      HapticFeedback.heavyImpact();
    } else if (nowPending.isEmpty) {
      ref.read(alertSoundProvider).stop();
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final orders = await ref.read(kitchenApiProvider).orders(widget.restaurantId);
      if (!mounted) return;
      _syncAlert(orders);
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

  (String, Color) get _statusMeta {
    if (order.isAwaitingDriver) return ('Kuryer qidirilmoqda', const Color(0xFF1565C0));
    return switch (order.status) {
      KitchenOrderStatus.pending => ('Yangi buyurtma', const Color(0xFFEF6C00)),
      KitchenOrderStatus.accepted => ('Qabul qilindi', const Color(0xFF1565C0)),
      KitchenOrderStatus.preparing => ('Tayyorlanmoqda', const Color(0xFF6A1B9A)),
      KitchenOrderStatus.ready => ('Tayyor — kuryer kutilmoqda', const Color(0xFF2E7D32)),
      KitchenOrderStatus.assigned => ('Kuryer biriktirildi', const Color(0xFF00838F)),
      KitchenOrderStatus.inProgress => ('Kuryer yo\'lda', const Color(0xFF00838F)),
      KitchenOrderStatus.pickedUp => ('Kuryer oldi', const Color(0xFF00838F)),
      KitchenOrderStatus.delivered || KitchenOrderStatus.completed => ('Yetkazildi', const Color(0xFF2E7D32)),
      KitchenOrderStatus.cancelled || KitchenOrderStatus.failed => ('Bekor qilindi', const Color(0xFFC62828)),
      _ => ('Faol', const Color(0xFF616161)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = _statusMeta;
    final isNew = order.status == KitchenOrderStatus.pending && !order.isAwaitingDriver;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNew ? BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- sarlavha: raqam, holat, vaqt, chat ----
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
                Text(_timeAgo(order.createdAt), style: TextStyle(color: scheme.outline, fontSize: 11.5)),
                if (onChat != null)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                    onPressed: onChat,
                    tooltip: 'Kuryer bilan suhbat',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // ---- taomlar ro'yxati (har biri narxi bilan) ----
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${it.nameSnapshot} ×${it.qty}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${_formatSom(it.lineTotal)} so\'m', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded, size: 15, color: scheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.addressText, style: TextStyle(color: scheme.outline, fontSize: 12.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            // ---- mijoz va haydovchi aloqa ma'lumoti ----
            if ((order.customer.name?.isNotEmpty ?? false) || (order.customer.phone?.isNotEmpty ?? false)) ...[
              const Divider(height: 18),
              _ContactRow(
                icon: Icons.person_rounded,
                fallbackLabel: 'Mijoz',
                name: order.customer.name,
                phone: order.customer.phone,
              ),
            ],
            if (order.driver != null) ...[
              const SizedBox(height: 6),
              _ContactRow(
                icon: Icons.two_wheeler_rounded,
                fallbackLabel: 'Kuryer',
                name: order.driver!.name,
                phone: order.driver!.phone,
                extra: [order.driver!.car, order.driver!.plate].where((v) => v != null && v.isNotEmpty).join(' · '),
                rating: order.driver!.rating,
              ),
            ],
            if (order.status == KitchenOrderStatus.ready) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 15, color: scheme.outline),
                  const SizedBox(width: 6),
                  Text('Kuryerga topshiring', style: TextStyle(color: scheme.outline, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const Divider(height: 18),
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

/// Mijoz/kuryer aloqa qatori — ism (+ ixtiyoriy mashina/plastinka/reyting) va
/// bosilsa qo'ng'iroq qiladigan telefon tugmasi.
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String fallbackLabel;
  final String? name;
  final String? phone;
  final String? extra;
  final double? rating;
  const _ContactRow({
    required this.icon,
    required this.fallbackLabel,
    this.name,
    this.phone,
    this.extra,
    this.rating,
  });

  Future<void> _call() async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'tel', path: p));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      (name?.isNotEmpty ?? false) ? name! : fallbackLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rating != null && rating! > 0) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.star_rounded, size: 13, color: Colors.amber[700]),
                    Text(rating!.toStringAsFixed(1), style: TextStyle(fontSize: 11.5, color: scheme.outline)),
                  ],
                ],
              ),
              if (extra != null && extra!.isNotEmpty)
                Text(extra!, style: TextStyle(fontSize: 11.5, color: scheme.outline)),
            ],
          ),
        ),
        if (phone != null && phone!.isNotEmpty)
          IconButton(
            icon: Icon(Icons.call_rounded, size: 18, color: scheme.primary),
            onPressed: _call,
            visualDensity: VisualDensity.compact,
            tooltip: "Qo'ng'iroq qilish",
          ),
      ],
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'hozir';
  if (diff.inMinutes < 60) return '${diff.inMinutes} daq. oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';
  return '${diff.inDays} kun oldin';
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
