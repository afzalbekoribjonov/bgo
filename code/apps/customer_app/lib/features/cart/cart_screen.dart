import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../checkout/checkout_screen.dart';
import 'cart_controller.dart';

/// Savat — taomlar, miqdor, jami. plan/05-customer-app.md
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(cart.restaurantName ?? t.cart)),
      body: cart.isEmpty
          ? Center(child: Text(t.cartEmpty))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final line = cart.lines[i];
                      return ListTile(
                        title: Text(line.name),
                        subtitle:
                            Text(t.priceSom(groupThousands(line.price))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  notifier.decrement(line.menuItemId),
                            ),
                            Text('${line.qty}',
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  notifier.increment(line.menuItemId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _CartSummary(subtotal: cart.subtotal),
              ],
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.subtotalLabel),
                Text(t.priceSom(groupThousands(subtotal))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              t.deliveryNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(t.checkoutButton),
            ),
          ],
        ),
      ),
    );
  }
}
