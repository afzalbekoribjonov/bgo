import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/brand.dart';
import '../checkout/checkout_screen.dart';
import '../restaurant/restaurant_card.dart' show dishIcon;
import 'cart_controller.dart';

/// Savat — taomlar, miqdor, jami. plan/05-customer-app.md
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.restaurantName ?? t.cart),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              tooltip: "Savatni tozalash",
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_basket_outlined,
                          size: 44,
                          color: scheme.primary.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 16),
                    Text(t.cartEmpty,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Menyudan yoqqan taomlaringizni tanlang',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: scheme.outline, fontSize: 13)),
                    const SizedBox(height: 20),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.restaurant_menu_rounded,
                          size: 19),
                      label: const Text('Menyuga qaytish'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 13)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              itemCount: cart.lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final line = cart.lines[i];
                // Chapга surib o'chirish — tez va tabiiy boshqaruv.
                return Dismissible(
                  key: ValueKey(line.menuItemId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => notifier.remove(line.menuItemId),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 24),
                  ),
                  child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: _lineThumb(scheme, line),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.priceSom(groupThousands(line.price)),
                                style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QtyBtn(
                                icon: Icons.remove,
                                onPressed: () =>
                                    notifier.decrement(line.menuItemId),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${line.qty}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ),
                              _QtyBtn(
                                icon: Icons.add,
                                onPressed: () =>
                                    notifier.increment(line.menuItemId),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                );
              },
            ),
      bottomNavigationBar:
          cart.isEmpty ? null : _CartSummary(subtotal: cart.subtotal),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Savatni tozalash'),
        content:
            const Text("Barcha mahsulotlarni savatdan olib tashlamoqchimisiz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Bekor qilish")),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Ha, tozalash"),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(cartProvider.notifier).clear();
  }
}

/// Savat qatoridagi kichik rasm — taom rasmi bo'lsa haqiqiy rasm, bo'lmasa
/// nomga mos ikonka (umumiy fastfood belgisi o'rniga).
Widget _lineThumb(ColorScheme scheme, CartLine line) {
  Widget fallback() => Container(
        color: scheme.primaryContainer,
        child: Icon(dishIcon(line.name), color: scheme.onPrimaryContainer, size: 22),
      );
  final url = line.imageUrl;
  if (url == null || url.isEmpty) return fallback();
  return Image.network(
    url,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => fallback(),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _QtyBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int subtotal;
  const _CartSummary({required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.subtotalLabel,
                    style: TextStyle(color: scheme.outline, fontSize: 14)),
                Text(t.priceSom(groupThousands(subtotal)),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.deliveryNote,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            BrandButton(
              label: t.checkoutButton,
              icon: Icons.receipt_long_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
