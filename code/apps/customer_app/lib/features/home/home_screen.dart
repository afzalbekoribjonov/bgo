import 'dart:async';

import 'package:flutter/material.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_error.dart';
import '../auth/auth_controller.dart';
import '../parcel/parcel_screen.dart';
import '../profile/profile_screen.dart';
import '../restaurant/restaurant_api.dart';
import '../restaurant/restaurant_card.dart';
import '../restaurant/restaurant_list_screen.dart';
import '../restaurant/restaurant_models.dart';
import '../taxi/taxi_screen.dart';

/// Bosh ekran — jonli: xizmatlar qatori, promo karusel, oshxona kontenti.
/// plan/05-customer-app.md
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageCtrl = PageController(viewportFraction: 0.92);
  Timer? _carousel;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    // Promo bannerlar avtomatik aylanadi (jonlilik).
    _carousel = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageCtrl.hasClients) return;
      _page = (_page + 1) % 3;
      _pageCtrl.animateToPage(_page,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _carousel?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : null;
    final restaurants = ref.watch(restaurantsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(restaurantsProvider),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(t, name),
            const SizedBox(height: 16),
            _services(t),
            const SizedBox(height: 20),
            _carouselSection(t),
            const SizedBox(height: 20),
            _popularSection(t, restaurants),
            _allSection(t, restaurants),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _header(AppLocalizations t, String? name) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name == null ? '${t.greetingHi}!' : '${t.greetingHi}, $name!',
                        style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 15,
                              color: scheme.onPrimary.withValues(alpha: 0.85)),
                          const SizedBox(width: 4),
                          Text(t.homeLocation,
                              style: TextStyle(
                                  color: scheme.onPrimary.withValues(alpha: 0.85),
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                Material(
                  color: scheme.onPrimary.withValues(alpha: 0.2),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(Icons.person, color: scheme.onPrimary),
                    tooltip: t.profileTitle,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Qidiruv (bosilsa ovqat ro'yxatiga o'tadi)
            InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RestaurantListScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: scheme.outline),
                    const SizedBox(width: 10),
                    Text(t.foodSearchHint,
                        style: TextStyle(color: scheme.outline)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Xizmatlar (bitta qator) ----------
  Widget _services(AppLocalizations t) {
    final items = [
      (Icons.restaurant, t.serviceFood, const Color(0xFFE8590C),
          () => _go(const RestaurantListScreen())),
      (Icons.local_taxi, t.serviceTaxi, const Color(0xFF1E88E5),
          () => _go(const TaxiScreen())),
      (Icons.delivery_dining, t.serviceDelivery, const Color(0xFF2E7D32),
          () => _go(const ParcelScreen())),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final (icon, label, color, onTap) in items)
            Expanded(
              child: _ServiceButton(
                  icon: icon, label: label, color: color, onTap: onTap),
            ),
        ],
      ),
    );
  }

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // ---------- Promo karusel ----------
  Widget _carouselSection(AppLocalizations t) {
    final banners = [
      (
        Icons.delivery_dining,
        t.foodPromoTitle,
        t.foodPromoSubtitle,
        [const Color(0xFFE8590C), const Color(0xFFF08C00)]
      ),
      (
        Icons.percent,
        t.homeBanner2Title,
        t.homeBanner2Sub,
        [const Color(0xFF7048E8), const Color(0xFF9775FA)]
      ),
      (
        Icons.bolt,
        t.homeBanner3Title,
        t.homeBanner3Sub,
        [const Color(0xFF0CA678), const Color(0xFF20C997)]
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: banners.length,
            itemBuilder: (_, i) {
              final (icon, title, sub, colors) = banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 46),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(sub,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _page == i ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _page == i
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Mashhur oshxonalar (gorizontal) ----------
  Widget _popularSection(
      AppLocalizations t, AsyncValue<List<RestaurantSummary>> async) {
    return async.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final top = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
        final popular = top.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(t.homePopular),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: popular.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    RestaurantMiniCard(restaurant: popular[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  // ---------- Barcha oshxonalar (vertikal) ----------
  Widget _allSection(
      AppLocalizations t, AsyncValue<List<RestaurantSummary>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(t.homeAllRestaurants),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => AsyncErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(restaurantsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(t.emptyRestaurants,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline)),
                  ),
                );
              }
              return Column(
                children: [for (final r in list) RestaurantCard(restaurant: r)],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

/// Bitta xizmat tugmasi — rangli dumaloq ikonka + yorliq.
class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
