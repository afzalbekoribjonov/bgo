import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../widgets/async_error.dart';
import 'kitchen_api.dart';
import 'kitchen_history_screen.dart';
import 'kitchen_income_screen.dart';
import 'kitchen_menu_screen.dart';
import 'kitchen_models.dart';
import 'kitchen_orders_screen.dart';
import 'kitchen_settings_screen.dart';

/// Oshxona egasining native paneli — buyurtmalar/menyu/tarix/daromad/sozlamalar.
/// `restaurant_web`ning to'liq Flutter nusxasi (WebView emas).
final kitchenRestaurantProvider =
    FutureProvider.family<KitchenRestaurant, String>((ref, id) {
  return ref.read(kitchenApiProvider).restaurant(id);
});

class KitchenHomeScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  const KitchenHomeScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends ConsumerState<KitchenHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (icon: Icons.receipt_long_rounded, label: 'Buyurtmalar'),
    (icon: Icons.restaurant_menu_rounded, label: 'Menyu'),
    (icon: Icons.history_rounded, label: 'Tarix'),
    (icon: Icons.bar_chart_rounded, label: 'Daromad'),
    (icon: Icons.settings_rounded, label: 'Sozlamalar'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleOpen(KitchenRestaurant r) async {
    try {
      await ref.read(kitchenApiProvider).setOpen(widget.restaurantId, !r.isOpen);
      ref.invalidate(kitchenRestaurantProvider(widget.restaurantId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(kitchenRestaurantProvider(widget.restaurantId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: restaurantAsync.when(
          data: (r) => Text(r.name, overflow: TextOverflow.ellipsis),
          loading: () => const Text('Mening oshxonam'),
          error: (_, __) => const Text('Mening oshxonam'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(icon: Icon(t.icon, size: 20), text: t.label)).toList(),
        ),
      ),
      body: Column(
        children: [
          restaurantAsync.when(
            data: (r) => _StatusBanner(restaurant: r, onToggle: () => _toggleOpen(r)),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                KitchenOrdersScreen(restaurantId: widget.restaurantId),
                KitchenMenuScreen(restaurantId: widget.restaurantId),
                KitchenHistoryScreen(restaurantId: widget.restaurantId),
                KitchenIncomeScreen(restaurantId: widget.restaurantId),
                restaurantAsync.when(
                  data: (r) => KitchenSettingsScreen(restaurantId: widget.restaurantId, restaurant: r),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: AsyncErrorRetry(
                      error: e,
                      onRetry: () => ref.invalidate(kitchenRestaurantProvider(widget.restaurantId)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: scheme.surface,
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final KitchenRestaurant restaurant;
  final VoidCallback onToggle;
  const _StatusBanner({required this.restaurant, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final open = restaurant.isOpen;
    final color = open ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Material(
      color: color.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(open ? Icons.storefront_rounded : Icons.storefront_outlined, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  open ? "Oshxona ochiq — buyurtma qabul qilinmoqda" : "Oshxona yopiq — buyurtma qabul qilinmaydi",
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Text(
                open ? 'Yopish' : 'Ochish',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
