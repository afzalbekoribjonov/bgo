import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cart/cart_controller.dart';
import '../order/order_api.dart';
import '../order/order_placed_screen.dart';

/// Rasmiylashtirish — manzil, to'lov (naqd), tasdiqlash. plan/05-customer-app.md
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final t = AppLocalizations.of(context)!;
    final cart = ref.read(cartProvider);
    final address = _addressCtrl.text.trim();
    if (address.isEmpty || cart.isEmpty || cart.restaurantId == null) {
      setState(() => _error = t.errorGeneric);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await ref.read(orderApiProvider).createFoodOrder(
            restaurantId: cart.restaurantId!,
            lines: cart.lines,
            addressText: address,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderPlacedScreen(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.checkoutTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _addressCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t.addressLabel,
                hintText: t.addressHint,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.paymentMethod,
                style: Theme.of(context).textTheme.titleSmall),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(t.paymentCash),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.subtotalLabel),
                Text(t.priceSom(groupThousands(cart.subtotal))),
              ],
            ),
            const SizedBox(height: 4),
            Text(t.deliveryNote, style: Theme.of(context).textTheme.bodySmall),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _placeOrder,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.placeOrder),
            ),
          ],
        ),
      ),
    );
  }
}
