import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import '../order/order_api.dart' show FoodConfig, foodConfigProvider;
import 'restaurant_api.dart';
import 'restaurant_card.dart';
import 'restaurant_models.dart';

/// Oshxona menyusi — kategoriya chiplar + rasm qo'llab-quvvatlash. plan/05-customer-app.md
class RestaurantMenuScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  ConsumerState<RestaurantMenuScreen> createState() =>
      _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends ConsumerState<RestaurantMenuScreen> {
  int _activeCat = 0;
  final Map<String, GlobalKey> _catKeys = {};

  int _shownPrice(MenuItemView i, FoodConfig? cfg) =>
      i.price + (cfg?.markup(i.price) ?? 0);

  void _addToCart(BuildContext context, MenuItemView item, FoodConfig? cfg) {
    final t = AppLocalizations.of(context)!;
    final replaced = ref.read(cartProvider.notifier).addItem(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          menuItemId: item.id,
          name: item.name,
          price: _shownPrice(item, cfg),
          imageUrl: item.imageUrl,
        );
    if (replaced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.cartUpdatedNewRestaurant)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} — ${t.cart}'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  void _scrollToCategory(int index, String categoryId) {
    setState(() => _activeCat = index);
    final ctx = _catKeys[categoryId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(menuProvider(widget.restaurantId));
    final cart = ref.watch(cartProvider);
    final cfg = ref.watch(foodConfigProvider).value;

    final showCartBar =
        !cart.isEmpty && cart.restaurantId == widget.restaurantId;

    return Scaffold(
      body: async.when(
        loading: () => CustomScrollView(slivers: [
          _appBar(context),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ]),
        error: (e, _) => CustomScrollView(slivers: [
          _appBar(context),
          SliverFillRemaining(
            hasScrollBody: false,
            child: AsyncErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(menuProvider(widget.restaurantId)),
            ),
          ),
        ]),
        data: (menu) {
          final categories =
              menu.categories.where((c) => c.items.isNotEmpty).toList();
          return CustomScrollView(
            slivers: [
              _appBar(context, logoUrl: menu.restaurant.logoUrl),
              _profileInfoBlock(context, menu.restaurant),
              if (!menu.restaurant.isOpen)
                SliverToBoxAdapter(child: _closedBanner(context)),
              if (categories.length > 1) _categoryStrip(context, categories),
              if (categories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(t.emptyMenu)),
                )
              else ...[
                for (int ci = 0; ci < categories.length; ci++) ...[
                  SliverToBoxAdapter(
                    child: _categoryHeader(
                      context,
                      categories[ci].name,
                      key: _catKeys.putIfAbsent(
                          categories[ci].id, () => GlobalKey()),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.88,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final item = categories[ci].items[i];
                          return _MenuGridCard(
                            item: item,
                            displayPrice: _shownPrice(item, cfg),
                            onAdd: (item.isAvailable && menu.restaurant.isOpen)
                                ? () => _addToCart(context, item, cfg)
                                : null,
                          );
                        },
                        childCount: categories[ci].items.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: showCartBar
          ? _CartBar(
              itemCount: cart.itemCount,
              subtotal: cart.subtotal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            )
          : null,
    );
  }

  /// Oshxona yopiq bo'lganda menyu tepasida ko'rinadigan, tushunarli banner
  /// — "Add" tugmalari o'chirilgani sababini mijozga aniq tushuntiradi.
  Widget _closedBanner(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.restaurantClosedBanner,
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverPersistentHeader _categoryStrip(
      BuildContext context, List<MenuCategory> categories) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CatStripDelegate(
        categories: categories,
        activeIndex: _activeCat,
        onTap: _scrollToCategory,
        bgColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _appBar(BuildContext context, {String? logoUrl}) {
    final accent = restaurantAccent(widget.restaurantName);
    final cart = ref.watch(cartProvider);
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;
    return SliverAppBar(
      expandedHeight: 168,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: accent,
      actions: [
        // Savat — doim ko'rinadigan indikator (sonli badge bilan):
        // sahifani tark etib qaytganda ham tanlangan taomlar shu yerda.
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: AppLocalizations.of(context)!.cart,
                icon: const Icon(Icons.shopping_basket_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                          minWidth: 18, minHeight: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            height: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
        title: Text(widget.restaurantName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        background: hasLogo
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _appBarFallback(accent),
              )
            : _appBarFallback(accent),
      ),
    );
  }

  /// Logotip bo'lmasa yoki yuklanmasa — nomga mos gradient qopqoq.
  Widget _appBarFallback(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_menu, size: 76, color: Colors.white24),
      ),
    );
  }

  /// Profil bloki — banner ostida to'g'ridan-to'g'ri (Stack/manfiy offset
  /// YO'Q — oldingi ikkita urinish ham "avatar tepaga yopishib qolgan"
  /// muammosini keltirib chiqargan edi, chunki banner ustiga chiqib
  /// turuvchi qatlam nozik va sinov qilib bo'lmaydigan edi). Bu yerda
  /// avatar + nom + chiplar oddiy Row ichida, yumaloq burchakli oq karta
  /// ustida — hech qanday qatlam bir-birining ustiga chiqmaydi, shu bilan
  /// birga rounded-top karta banner bilan tabiiy uzviylashadi.
  Widget _profileInfoBlock(BuildContext context, RestaurantSummary restaurant) {
    final scheme = Theme.of(context).colorScheme;
    const avatarSize = 64.0;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 1.2),
              ),
              child: restaurantAvatar(restaurant.name, restaurant.logoUrl,
                  size: avatarSize),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(restaurant.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _infoChip(context, Icons.star_rounded,
                          restaurant.rating.toStringAsFixed(1),
                          color: Colors.amber),
                      _infoChip(
                        context,
                        restaurant.isOpen
                            ? Icons.check_circle_rounded
                            : Icons.access_time_rounded,
                        restaurant.isOpen ? 'Ochiq' : 'Hozircha yopiq',
                        color: restaurant.isOpen
                            ? const Color(0xFF2E7D32)
                            : scheme.error,
                      ),
                      if (restaurant.address.isNotEmpty)
                        _infoChip(
                          context,
                          Icons.location_on_rounded,
                          restaurant.address,
                          color: scheme.outline,
                          maxWidth: 170,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profil blokidagi ixcham ma'lumot chipi (yengil fon, rangli ikonka).
  Widget _infoChip(BuildContext context, IconData icon, String label,
      {required Color color, double? maxWidth}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? 260),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _categoryHeader(BuildContext context, String name, {Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

/// Kategoriyalar stripini ushlab turuvchi SliverPersistentHeaderDelegate.
class _CatStripDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> categories;
  final int activeIndex;
  final void Function(int, String) onTap;
  final Color bgColor;

  const _CatStripDelegate({
    required this.categories,
    required this.activeIndex,
    required this.onTap,
    required this.bgColor,
  });

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: bgColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final active = i == activeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(categories[i].name),
              selected: active,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (_) => onTap(i, categories[i].id),
              labelStyle: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
                color: active ? scheme.onPrimary : scheme.onSurface,
              ),
              backgroundColor: scheme.surfaceContainerHighest,
              selectedColor: scheme.primary,
              side: BorderSide(
                color: active ? scheme.primary : scheme.outlineVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_CatStripDelegate old) =>
      activeIndex != old.activeIndex ||
      categories != old.categories ||
      bgColor != old.bgColor;
}

/// Taom kartasi — rasmga mos moslashuvchan grid karta (profil ostidagi
/// postlar kabi). Butun karta bosilsa (mavjud bo'lsa) savatga qo'shadi.
class _MenuGridCard extends StatelessWidget {
  final MenuItemView item;
  final int displayPrice;
  final VoidCallback? onAdd;

  const _MenuGridCard(
      {required this.item, required this.displayPrice, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final disabled = !item.isAvailable;
    final accent = dishAccent(item.name);

    Widget imageWidget;
    final url = item.imageUrl;
    if (url != null && url.isNotEmpty) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(accent),
      );
    } else {
      imageWidget = _fallback(accent);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: disabled ? null : onAdd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 108,
              width: double.infinity,
              // Faqat rasm xiralashtiriladi — karta foni/ramkasi/soyasi
              // to'liq ko'rinishda qoladi, shunda "tugagan" taom ham
              // to'liq shakllangan kartaday ko'rinadi.
              child: disabled
                  ? Opacity(opacity: 0.45, child: imageWidget)
                  : imageWidget,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.name,
                            style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: disabled
                                    ? scheme.outline
                                    : scheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(item.description!,
                              style: TextStyle(
                                  color: scheme.outline, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            disabled
                                ? t.unavailable
                                : t.priceSom(groupThousands(displayPrice)),
                            style: TextStyle(
                              color: disabled ? scheme.error : scheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!disabled)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.add,
                                size: 16, color: Colors.white),
                          ),
                      ],
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

  Widget _fallback(Color accent) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(dishIcon(item.name), size: 34, color: Colors.white70),
        ),
      );
}

class _CartBar extends StatelessWidget {
  final int itemCount;
  final int subtotal;
  final VoidCallback onTap;

  const _CartBar({
    required this.itemCount,
    required this.subtotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('${t.cart} ($itemCount)'),
                ],
              ),
              Text(t.priceSom(groupThousands(subtotal))),
            ],
          ),
        ),
      ),
    );
  }
}
