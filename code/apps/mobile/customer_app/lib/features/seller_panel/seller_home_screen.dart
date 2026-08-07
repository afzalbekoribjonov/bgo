import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_error.dart';
import 'seller_chat_screen.dart';
import 'seller_panel_api.dart';
import 'seller_panel_models.dart';
import 'seller_products_screen.dart';
import 'seller_profile_screen.dart';

/// Do'kon (sotuvchi) egasining native paneli — mahsulotlar/suhbatlar/profil.
/// `seller_web`ning to'liq Flutter nusxasi (WebView emas).
final sellerProfileProvider = FutureProvider<SellerProfile>((ref) {
  return ref.read(sellerPanelApiProvider).profile();
});

class SellerHomeScreen extends ConsumerStatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  ConsumerState<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends ConsumerState<SellerHomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (icon: Icons.inventory_2_rounded, label: 'Mahsulotlar'),
    (icon: Icons.chat_bubble_rounded, label: 'Suhbatlar'),
    (icon: Icons.storefront_rounded, label: 'Profil'),
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(sellerProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text(p.name, overflow: TextOverflow.ellipsis),
          loading: () => const Text('Mening do\'konim'),
          error: (_, __) => const Text('Mening do\'konim'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(icon: Icon(t.icon, size: 20), text: t.label)).toList(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: AsyncErrorRetry(error: e, onRetry: () => ref.invalidate(sellerProfileProvider)),
        ),
        data: (profile) => TabBarView(
          controller: _tabController,
          children: [
            SellerProductsScreen(sellerType: profile.sellerType),
            const SellerChatThreadsScreen(),
            SellerProfileScreen(profile: profile),
          ],
        ),
      ),
    );
  }
}
