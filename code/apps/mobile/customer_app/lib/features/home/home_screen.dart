import 'dart:async';

import 'package:beshariq_core/beshariq_core.dart';
import 'package:flutter/material.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_webview_screen.dart';
import '../../core/location_service.dart';
import '../../widgets/async_error.dart';
import '../../widgets/brand.dart';
import '../auth/auth_controller.dart';
import '../order/order_api.dart';
import '../parcel/parcel_api.dart';
import '../parcel/parcel_models.dart';
import '../parcel/parcel_screen.dart';
import '../profile/profile_screen.dart';
import '../restaurant/restaurant_api.dart';
import '../restaurant/restaurant_card.dart';
import '../restaurant/restaurant_list_screen.dart';
import '../restaurant/restaurant_models.dart';
import '../taxi/taxi_api.dart';
import '../taxi/taxi_models.dart';
import '../taxi/taxi_screen.dart';

/// Bosh ekran — xizmatlar, promo karusel, 20 ta random taom karuseli, mashhur oshxonalar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _activeTimer;

  /// Foydalanuvchi joylashuvi — oshxonalarni "eng yaqini birinchi" saralash.
  LatLng? _myLoc;

  @override
  void initState() {
    super.initState();
    // GPS — best-effort: topilmasa reyting bo'yicha saralanadi.
    ref.read(locationServiceProvider).currentLatLng().then((p) {
      if (mounted && p != null) setState(() => _myLoc = p);
    });
    // Faol jarayonlar badge'lari jonli yangilanib turadi (taksi/ovqat/dostavka).
    _activeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.invalidate(myTripsProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(myParcelsProvider);
    });
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    super.dispose();
  }

  void _go(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).user;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.trim()
        : null;
    final restaurants = ref.watch(restaurantsProvider);
    final dishes = ref.watch(dishesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(restaurantsProvider);
          ref.invalidate(dishesProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(t, name),
            const SizedBox(height: 16),
            _services(t),
            const SizedBox(height: 20),
            _marketButtons(),
            const SizedBox(height: 24),
            _foodSection(t, dishes),
            const SizedBox(height: 24),
            _popularSection(t, restaurants),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _header(AppLocalizations t, String? name) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            // Brend qatori: Beshariq Go + profil
            Row(
              children: [
                const Expanded(child: BrandLogo(onDark: true, size: 19)),
                Material(
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Icon(Icons.person_rounded, color: scheme.onPrimary),
                    tooltip: t.profileTitle,
                    onPressed: () => _go(const ProfileScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name == null ? t.greetingHi : '${t.greetingHi}, $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Nima buyurtma bermoqchisiz?',
              style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 7),
            // Hudud — muzli chip (professional lokatsiya ko'rsatkichi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 13, color: scheme.onPrimary.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text(t.homeLocation,
                      style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _go(const RestaurantListScreen()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: scheme.outline),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t.foodSearchHint,
                          style:
                              TextStyle(color: scheme.outline, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: scheme.primary, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _services(AppLocalizations t) {
    // Faol jarayonlar soni — tugma ustidagi badge (taksi qidirilmoqda va h.k.).
    final activeFood = (ref.watch(myOrdersProvider).valueOrNull ?? const [])
        .where((o) => o.isActive)
        .length;
    final activeTaxi =
        (ref.watch(myTripsProvider).valueOrNull ?? const <TaxiTrip>[])
            .where((tr) => tr.isActive)
            .length;
    final activeParcel =
        (ref.watch(myParcelsProvider).valueOrNull ?? const <ParcelDelivery>[])
            .where((p) => p.isActive)
            .length;

    final items = [
      (
        Icons.restaurant_rounded,
        t.serviceFood,
        const Color(0xFFE8590C),
        activeFood,
        () => _go(const RestaurantListScreen())
      ),
      (
        Icons.local_taxi_rounded,
        t.serviceTaxi,
        const Color(0xFF1E88E5),
        activeTaxi,
        () => _go(const TaxiScreen())
      ),
      (
        Icons.delivery_dining_rounded,
        t.serviceDelivery,
        const Color(0xFF2E7D32),
        activeParcel,
        () => _go(const ParcelScreen())
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final (icon, label, color, badge, onTap) in items)
            Expanded(
              child: _ServiceButton(
                icon: icon,
                label: label,
                color: color,
                badge: badge,
                onTap: onTap,
              ),
            ),
        ],
      ),
    );
  }

  /// Beshariq Market / Do'konlar / Qurilishda foydali — har biri alohida
  /// mini-sayt (WebView) ochadigan, avtomatik aylanadigan va suriladigan
  /// karusel (bitta-bitta ko'rsatiladi).
  Widget _marketButtons() {
    final items = [
      _MarketCarouselItem(
        icon: Icons.storefront_rounded,
        title: 'Beshariq Market',
        subtitle: "O'z omborimizdan — tez yetkazamiz",
        colors: const [Color(0xFFE8590C), Color(0xFFF08C00)],
        onTap: _openMarket,
      ),
      _MarketCarouselItem(
        icon: Icons.storefront_outlined,
        title: "Do'konlar",
        subtitle: "Mahalliy sotuvchilar bilan bog'laning",
        colors: const [Color(0xFF7048E8), Color(0xFF9775FA)],
        onTap: () => _openShops(
          path: '/',
          title: "Do'konlar",
          icon: Icons.storefront_outlined,
        ),
      ),
      _MarketCarouselItem(
        icon: Icons.construction_rounded,
        title: 'Qurilishda foydali',
        subtitle: 'Qurilish mollari va anjomlar',
        colors: const [Color(0xFF0CA678), Color(0xFF20C997)],
        onTap: () => _openShops(
          path: '/qurilish',
          title: 'Qurilishda foydali',
          icon: Icons.construction_rounded,
        ),
      ),
    ];
    return _MarketCarousel(items: items);
  }

  Future<void> _openMarket() async {
    final token = await ref.read(tokenStorageProvider).readAccess();
    if (!mounted) return;
    _go(AppWebViewScreen(
      baseUrl: ApiConfig.marketBaseUrl,
      token: token,
      title: 'Beshariq Market',
      loadingIcon: Icons.storefront_rounded,
      loadingLabel: 'Market yuklanmoqda…',
    ));
  }

  Future<void> _openShops({
    required String path,
    required String title,
    required IconData icon,
  }) async {
    final token = await ref.read(tokenStorageProvider).readAccess();
    if (!mounted) return;
    final base = ApiConfig.shopsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    _go(AppWebViewScreen(
      baseUrl: '$base$path',
      token: token,
      title: title,
      loadingIcon: icon,
      loadingLabel: '$title yuklanmoqda…',
    ));
  }

  /// Karta ro'yxati yuklanayotganda joy egallovchi skeletonlar — bo'sh
  /// spinner o'rniga kelayotgan kontent shaklini oldindan ko'rsatadi.
  Widget _horizontalSkeletonRow({required double height, required double cardWidth}) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(
                height: height - 54,
                borderRadius: BorderRadius.circular(18),
              ),
              const SizedBox(height: 10),
              SkeletonBox(height: 14, width: cardWidth * 0.75, borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 8),
              SkeletonBox(height: 12, width: cardWidth * 0.5, borderRadius: BorderRadius.circular(6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foodSection(AppLocalizations t, AsyncValue<List<Dish>> async) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.homeDishes,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: () => _go(const RestaurantListScreen()),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(t.homeSeeAll),
                style: TextButton.styleFrom(foregroundColor: scheme.primary),
              ),
            ],
          ),
        ),
        async.when(
          loading: () => _horizontalSkeletonRow(height: 210, cardWidth: 150),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AsyncErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(dishesProvider),
            ),
          ),
          data: (dishes) {
            if (dishes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(t.emptyRestaurants,
                      style: TextStyle(color: scheme.outline)),
                ),
              );
            }
            return _FoodCarousel(dishes: dishes);
          },
        ),
      ],
    );
  }

  /// Oshxonalar lentasi — GPS bo'lsa ENG YAQINI BIRINCHI (masofa chipi
  /// bilan); GPS yo'q/joylashuvsiz oshxonalar reyting bo'yicha oxirida.
  Widget _popularSection(
      AppLocalizations t, AsyncValue<List<RestaurantSummary>> async) {
    return async.when(
      loading: () => _horizontalSkeletonRow(height: 172, cardWidth: 140),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(restaurantsProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final me = _myLoc;
        List<RestaurantSummary> ordered;
        final byDistance = <String, double>{};
        if (me != null && list.any((r) => r.hasLocation)) {
          const d = Distance();
          for (final r in list.where((r) => r.hasLocation)) {
            byDistance[r.id] =
                d.as(LengthUnit.Kilometer, me, LatLng(r.lat, r.lng));
          }
          final located = list.where((r) => r.hasLocation).toList()
            ..sort((a, b) => byDistance[a.id]!.compareTo(byDistance[b.id]!));
          final rest = list.where((r) => !r.hasLocation).toList()
            ..sort((a, b) => b.rating.compareTo(a.rating));
          ordered = [...located, ...rest];
        } else {
          ordered = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
        }
        final shown = ordered.take(7).toList();
        final nearby = byDistance.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 12),
              child: Row(
                children: [
                  if (nearby) ...[
                    Icon(Icons.near_me_rounded,
                        size: 19, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      nearby ? t.homeNearby : t.homePopular,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _go(const RestaurantListScreen()),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(t.homeSeeAll),
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shown.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => RestaurantMiniCard(
                  restaurant: shown[i],
                  distanceKm: byDistance[shown[i].id],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Xizmat tugmasi — rangli ikonka + yorliq + faol jarayon badge'i.
class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Faol jarayonlar soni — 0 dan katta bo'lsa tugma ustida belgi ko'rinadi.
  final int badge;

  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: _ActiveBadge(count: badge, color: color),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faol jarayon belgisi — pulslanadigan rangli doira ichida son.
class _ActiveBadge extends StatefulWidget {
  final int count;
  final Color color;
  const _ActiveBadge({required this.count, required this.color});

  @override
  State<_ActiveBadge> createState() => _ActiveBadgeState();
}

class _ActiveBadgeState extends State<_ActiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 1 + _c.value * 0.12,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        child: Center(
          child: Text(
            '${widget.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bosh ekrandagi Market/Do'konlar/Qurilish gradient kartochka-tugmasi.
class _MarketCarouselItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _MarketCarouselItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });
}

/// Market/Do'konlar/Qurilish tugmalari — PageView bilan avto-aylanadi va
/// qo'l bilan ham suriladi (_FoodCarousel bilan bir xil naqsh).
class _MarketCarousel extends StatefulWidget {
  final List<_MarketCarouselItem> items;
  const _MarketCarousel({required this.items});

  @override
  State<_MarketCarousel> createState() => _MarketCarouselState();
}

class _MarketCarouselState extends State<_MarketCarousel> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.92);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_ctrl.hasClients) return;
      final next = (_page + 1) % widget.items.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 420), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 116,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.items.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MarketCarouselCard(item: widget.items[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.items.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _page
                      ? widget.items[i].colors[0]
                      : scheme.outlineVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Bitta karusel kartasi — ikonka, sarlavha, qisqa tavsif va yo'nalish belgisi.
class _MarketCarouselCard extends StatelessWidget {
  final _MarketCarouselItem item;
  const _MarketCarouselCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: item.colors[0].withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 20 ta random taom karuseli — PageView bilan avto-aylanadi.
class _FoodCarousel extends StatefulWidget {
  final List<Dish> dishes;
  const _FoodCarousel({required this.dishes});

  @override
  State<_FoodCarousel> createState() => _FoodCarouselState();
}

class _FoodCarouselState extends State<_FoodCarousel> {
  late final PageController _ctrl;
  late final List<Dish> _shown;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _shown = ([...widget.dishes]..shuffle()).take(20).toList();
    _ctrl = PageController(viewportFraction: 0.88);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_ctrl.hasClients) return;
      final next = (_page + 1) % _shown.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 420), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _shown.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _FoodCard(dish: _shown[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${_page + 1} / ${_shown.length}',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.outline,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_page + 1) / _shown.length,
                    backgroundColor: scheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bitta taom kartasi (karusel elementi).
class _FoodCard extends StatelessWidget {
  final Dish dish;
  const _FoodCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = dishAccent(dish.name);
    final t = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () =>
          openRestaurantById(context, dish.restaurantId, dish.restaurantName),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _bg(accent),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dish.restaurantName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.45),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            t.priceSom(groupThousands(dish.price)),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        dish.restaurantRating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bg(Color accent) {
    final url = dish.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradient(accent),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _gradient(accent),
      );
    }
    return _gradient(accent);
  }

  Widget _gradient(Color accent) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent,
              accent.withValues(alpha: 0.55),
              const Color(0xFF0D1117),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(dishIcon(dish.name),
              size: 70, color: Colors.white.withValues(alpha: 0.22)),
        ),
      );
}
