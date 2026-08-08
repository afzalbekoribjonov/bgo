import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/location_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/brand.dart';
import '../cart/cart_controller.dart';
import '../order/order_api.dart';
import '../order/food_tracking_screen.dart';
import '../profile/profile_api.dart';
import '../profile/profile_models.dart';
import '../restaurant/restaurant_card.dart' show dishIcon;

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
  bool _locating = false;
  double? _lat;
  double? _lng;
  String? _error;

  // Promokod holati: yozilgan kod avval TEKSHIRILADI, keyin buyurtma davom
  // etadi. Matn o'zgarsa tekshiruv bekor bo'ladi.
  bool _promoChecking = false;
  bool _promoValid = false;
  int _promoDiscount = 0;
  String? _promoError;

  /// Promokodni serverda tekshiradi (chegirma summasi bilan qaytadi).
  Future<void> _checkPromo() async {
    final t = AppLocalizations.of(context)!;
    final code = _promoCtrl.text.trim();
    if (code.isEmpty || _promoChecking) return;
    final cart = ref.read(cartProvider);
    setState(() {
      _promoChecking = true;
      _promoError = null;
    });
    try {
      final res = await ref.read(dioProvider).post('/orders/promo-check',
          data: {'code': code, 'itemsTotal': cart.subtotal});
      final discount =
          ((res.data['data']?['discount']) as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() {
        _promoValid = true;
        _promoDiscount = discount;
        _promoChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Server sababi (masalan "Minimal buyurtma summasi...") ko'rsatiladi.
      String? serverMsg;
      if (e is DioException) {
        final m = e.response?.data;
        if (m is Map && m['message'] is String) {
          serverMsg = m['message'] as String;
        }
      }
      setState(() {
        _promoChecking = false;
        _promoValid = false;
        _promoDiscount = 0;
        _promoError = isNetworkError(e)
            ? t.errorNetwork
            : (serverMsg ?? t.promoInvalid);
      });
    }
  }

  /// Promo matni o'zgardi — oldingi tekshiruv natijasini bekor qilamiz.
  void _onPromoChanged(String _) {
    if (_promoValid || _promoError != null) {
      setState(() {
        _promoValid = false;
        _promoDiscount = 0;
        _promoError = null;
      });
    }
  }

  /// "Hozirgi joylashuvimga yetkazish" — GPS olib, manzilni to'ldiradi.
  Future<void> _useMyLocation() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _locating = true);
    final svc = ref.read(locationServiceProvider);
    await svc.ensurePermission();
    final pos = await svc.currentLatLng();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _addressCtrl.text = t.taxiCurrentLocation;
      }
    });
  }

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
    // Promokod yozilgan, lekin hali tekshirilmagan — avval tekshirish shart.
    if (_promoCtrl.text.trim().isNotEmpty && !_promoValid) {
      setState(() => _error = t.promoNeedsCheck);
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
            lat: _lat,
            lng: _lng,
            promoCode: _promoValid ? _promoCtrl.text.trim() : '',
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FoodTrackingScreen(orderId: order.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Server sababi (masalan "Oshxona hozirda yopiq") bo'lsa aynan shu
      // ko'rsatiladi — barcha 400'larni promokod xatosi deb noto'g'ri
      // taxmin qilmaymiz.
      String? serverMsg;
      if (e is DioException) {
        final m = e.response?.data;
        if (m is Map && m['message'] is String) {
          serverMsg = m['message'] as String;
        }
      }
      setState(() {
        _loading = false;
        _error = isNetworkError(e)
            ? t.errorNetwork
            : (serverMsg ?? t.errorGeneric);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(addressesProvider);
    // Yetkazish narxi — jami hisoblash uchun (mijoz yagona umumiy narxni ko'radi).
    final deliveryFee = ref.watch(foodConfigProvider).value?.deliveryFee ?? 0;
    final discount = _promoValid ? _promoDiscount : 0;
    final grandTotal =
        (cart.subtotal + deliveryFee - discount).clamp(0, 1 << 31).toInt();

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
            _sectionHeader(Icons.receipt_rounded, t.yourOrderLabel),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (int i = 0; i < cart.lines.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 14, indent: 52),
                      _orderLineRow(context, cart.lines[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader(Icons.location_on_rounded, t.addressLabel),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Joriy GPS joylashuviga yetkazish (eng oson yo'l)
                    FilledButton.tonalIcon(
                      onPressed: _locating ? null : _useMyLocation,
                      icon: _locating
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location),
                      label: Text(t.checkoutDeliverHere),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                    ),
                    if (_lat != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(t.checkoutGpsSelected,
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    ...addresses.maybeWhen<List<Widget>>(
                      data: (list) => list.isEmpty
                          ? const <Widget>[]
                          : <Widget>[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(t.addressChoose,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final a in list)
                                    ActionChip(
                                      avatar: Icon(
                                        a.isDefault
                                            ? Icons.home
                                            : Icons.location_on_outlined,
                                        size: 18,
                                      ),
                                      label: Text(a.label),
                                      onPressed: () => setState(
                                          () => _addressCtrl.text = a.text),
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
                      // Qo'lda tahrirlansa GPS koordinatasini bekor qilamiz.
                      onChanged: (_) {
                        if (_lat != null) {
                          setState(() {
                            _lat = null;
                            _lng = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: t.addressHint,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionHeader(Icons.account_balance_wallet_rounded, t.paymentMethod),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: Color(0xFF2E7D32), size: 22),
                ),
                title: Text(t.paymentCash,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32)),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                children: [
                  // Promokod — kompakt qator, ikonka-tugma bilan (avval tekshiriladi)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCtrl,
                          enabled: !_promoValid,
                          textCapitalization:
                              TextCapitalization.characters,
                          onChanged: _onPromoChanged,
                          decoration: InputDecoration(
                            hintText: t.promoLabel.toUpperCase(),
                            isDense: true,
                            prefixIcon: Icon(
                              _promoValid
                                  ? Icons.check_circle_rounded
                                  : Icons.local_offer_outlined,
                              color: _promoValid
                                  ? const Color(0xFF2E7D32)
                                  : null,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_promoValid)
                        IconButton.filledTonal(
                          tooltip: t.cancel,
                          onPressed: () {
                            _promoCtrl.clear();
                            setState(() {
                              _promoValid = false;
                              _promoDiscount = 0;
                            });
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      else
                        IconButton.filledTonal(
                          tooltip: t.promoCheck,
                          onPressed: _promoChecking ? null : _checkPromo,
                          icon: _promoChecking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.check_rounded),
                        ),
                    ],
                  ),
                  if (_promoError != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(_promoError!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error)),
                        ),
                      ],
                    ),
                  ],
                  if (_promoValid) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(t.promoApplied,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32))),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 22),
                  // Taomlar narxi yuqoridagi "Buyurtmangiz" ro'yxatida
                  // allaqachon ko'rinadi — bu yerda takrorlanmaydi.
                  _summaryRow(context, t.deliveryFeeLabel,
                      t.priceSom(groupThousands(deliveryFee))),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.discountLabel,
                            style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600)),
                        Text(
                            '− ${t.priceSom(groupThousands(discount))}',
                            style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.totalLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(t.priceSom(groupThousands(grandTotal)),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                ],
              ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            BrandButton(
              label:
                  '${t.placeOrder} · ${t.priceSom(groupThousands(grandTotal))}',
              icon: Icons.check_circle_rounded,
              loading: _loading,
              onPressed: _loading ? null : _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  /// Bo'lim sarlavhasi — rangli ikonka + qalin matn.
  Widget _sectionHeader(IconData icon, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: scheme.primary),
        ),
        const SizedBox(width: 9),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// "Buyurtmangiz" bo'limidagi bitta qator — kichik rasm + nom + miqdor + narx.
  Widget _orderLineRow(BuildContext context, CartLine line) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 42,
            height: 42,
            child: _orderLineThumb(scheme, line),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(line.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text('×${line.qty}',
            style: TextStyle(color: scheme.outline, fontSize: 12.5)),
        const SizedBox(width: 8),
        Text(t.priceSom(groupThousands(line.lineTotal)),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: scheme.primary)),
      ],
    );
  }

  Widget _orderLineThumb(ColorScheme scheme, CartLine line) {
    Widget fallback() => Container(
          color: scheme.primaryContainer,
          child: Icon(dishIcon(line.name),
              color: scheme.onPrimaryContainer, size: 18),
        );
    final url = line.imageUrl;
    if (url == null || url.isEmpty) return fallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }
}
