import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cart/cart_controller.dart';
import '../order/order_api.dart';
import '../order/order_placed_screen.dart';
import '../profile/profile_api.dart';
import '../profile/profile_models.dart';

/// Rasmiylashtirish — manzil, to'lov (naqd), tasdiqlash. plan/05-customer-app.md
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  bool _loading = false;
  bool _prefilled = false;
  String? _error;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _promoCtrl.dispose();
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
            promoCode: _promoCtrl.text.trim(),
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
        // 400 — promokod yoki boshqa validatsiya: backend xabarini ko'rsatamiz
        _error = isNetworkError(e)
            ? t.errorNetwork
            : (httpStatus(e) == 400 ? t.promoInvalid : t.errorGeneric);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(addressesProvider);

    // Standart manzilni bir marta avtomatik to'ldirish.
    ref.listen<AsyncValue<List<Address>>>(addressesProvider, (_, next) {
      next.whenData((list) {
        if (!_prefilled && _addressCtrl.text.isEmpty && list.isNotEmpty) {
          _prefilled = true;
          final def = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
          _addressCtrl.text = def.text;
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.checkoutTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...addresses.maybeWhen<List<Widget>>(
              data: (list) => list.isEmpty
                  ? const <Widget>[]
                  : <Widget>[
                      Text(t.addressChoose,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in list)
                            ActionChip(
                              avatar: Icon(
                                a.isDefault ? Icons.home : Icons.location_on_outlined,
                                size: 18,
                              ),
                              label: Text(a.label),
                              onPressed: () =>
                                  setState(() => _addressCtrl.text = a.text),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
              orElse: () => const <Widget>[],
            ),
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
            TextField(
              controller: _promoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: t.promoLabel,
                hintText: t.promoHint,
                prefixIcon: const Icon(Icons.local_offer_outlined),
                border: const OutlineInputBorder(),
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
