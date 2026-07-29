import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/beshariq_map.dart';
import '../../core/location_service.dart';
import '../../core/routing_service.dart';
import '../../widgets/car_marker.dart';
import 'order_api.dart';
import 'order_models.dart';

/// Ovqat buyurtmasi jonli kuzatuvi: 2 rangli marshrut (kuryer→oshxona,
/// oshxona→mijoz) + jonli kuryer + holatlar + baholash.
class FoodTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const FoodTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<FoodTrackingScreen> createState() =>
      _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends ConsumerState<FoodTrackingScreen> {
  final MapController _map = MapController();
  Timer? _poll;
  OrderView? _order;
  LatLng? _driverLoc;
  List<LatLng> _toKitchen = const []; // kuryer -> oshxona (to'q sariq)
  List<LatLng> _toCustomer = const []; // oshxona -> mijoz (ko'k)
  List<LatLng> _toCustomerLive = const []; // olingach: kuryer -> mijoz (jonli)
  String? _routedFor; // qaysi holatga marshrut hisoblangan
  String? _liveRoutedFor; // kuryer->mijoz jonli marshrut kaliti
  bool _rated = false;

  // ETA bo'laklari (daqiqa): kuryer->oshxona, oshxona->mijoz, kuryer->mijoz.
  int? _minToKitchen;
  int? _minKitchenToCustomer;
  int? _minToCustomerLive;

  /// Tayyorlash zaxirasi (daqiqa) — oshxona hali tayyor demagan bosqichlarda.
  static const _prepBufferMin = 8;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final o = await ref.read(orderApiProvider).getOrderLive(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = o;
        if (o.driverLat != null && o.driverLng != null) {
          _driverLoc = LatLng(o.driverLat!, o.driverLng!);
        }
      });
      _syncRoutes(o);
      if (o.isDone) _maybeRate(o);
    } catch (_) {/* keyingi urinish */}
  }

  /// Marshrutlar + ETA bo'laklari: oshxona→mijoz doim; olishdan oldin
  /// kuryer→oshxona; olingandan keyin kuryer→mijoz (jonli yangilanadi).
  Future<void> _syncRoutes(OrderView o) async {
    final k = (o.restaurantLat != null && o.restaurantLng != null)
        ? LatLng(o.restaurantLat!, o.restaurantLng!)
        : null;
    final c = (o.addressLat != null && o.addressLng != null)
        ? LatLng(o.addressLat!, o.addressLng!)
        : null;
    final routing = ref.read(routingServiceProvider);

    // Oshxona -> mijoz (bir marta yetarli) + davomiyligi.
    if (k != null && c != null && _toCustomer.isEmpty) {
      final dir = await routing.directions(k, c);
      if (mounted && dir != null) {
        setState(() {
          _toCustomer = dir.points;
          _minKitchenToCustomer = dir.etaMinutes;
        });
      }
    }
    // Kuryer -> oshxona (olib ketishdan oldin, joylashuv o'zgarsa yangilanadi).
    final beforePickup = ['ACCEPTED', 'PREPARING', 'READY'].contains(o.status);
    if (beforePickup && k != null && _driverLoc != null) {
      final key = '${_driverLoc!.latitude.toStringAsFixed(4)}_${o.status}';
      if (_routedFor != key) {
        _routedFor = key;
        final dir = await routing.directions(_driverLoc!, k);
        if (mounted && dir != null) {
          setState(() {
            _toKitchen = dir.points;
            _minToKitchen = dir.etaMinutes;
          });
        }
      }
    } else if (!beforePickup && _toKitchen.isNotEmpty) {
      if (mounted) {
        setState(() {
          _toKitchen = const [];
          _minToKitchen = null;
        });
      }
    }
    // Olingandan keyin: kuryer -> mijoz (jonli — kuryer siljiganda yangilanadi).
    final afterPickup =
        ['PICKED_UP', 'ASSIGNED', 'IN_PROGRESS'].contains(o.status);
    if (afterPickup && c != null && _driverLoc != null) {
      final key = _driverLoc!.latitude.toStringAsFixed(4);
      if (_liveRoutedFor != key) {
        _liveRoutedFor = key;
        final dir = await routing.directions(_driverLoc!, c);
        if (mounted && dir != null) {
          setState(() {
            _toCustomerLive = dir.points;
            _minToCustomerLive = dir.etaMinutes;
          });
        }
      }
    } else if (!afterPickup && _toCustomerLive.isNotEmpty) {
      if (mounted) {
        setState(() {
          _toCustomerLive = const [];
          _minToCustomerLive = null;
        });
      }
    }
    // Xaritani markazlash (bir marta).
    if (_center == null && (k != null || c != null)) {
      _map.move(k ?? c!, 14);
    }
  }

  /// Taxminiy yetkazish vaqti (daqiqa) — bosqichga qarab yig'iladi:
  /// olishdan oldin: kuryer→oshxona + tayyorlash zaxirasi + oshxona→mijoz;
  /// olingandan keyin: kuryer→mijoz. Ma'lumot yetmasa null (chip yashirin).
  int? get _etaMinutes {
    final o = _order;
    if (o == null || o.isDone || o.isCancelled) return null;
    switch (o.status) {
      case 'PENDING':
        final kc = _minKitchenToCustomer;
        return kc == null ? null : kc + _prepBufferMin;
      case 'ACCEPTED':
      case 'PREPARING':
      case 'READY':
        final kc = _minKitchenToCustomer;
        if (kc == null) return null;
        final dk = _minToKitchen ?? 0;
        final prep = o.status == 'READY' ? 0 : _prepBufferMin;
        return dk + prep + kc;
      case 'PICKED_UP':
      case 'ASSIGNED':
      case 'IN_PROGRESS':
        return _minToCustomerLive ?? _minKitchenToCustomer;
    }
    return null;
  }

  LatLng? get _center {
    final o = _order;
    if (o?.restaurantLat != null) {
      return LatLng(o!.restaurantLat!, o.restaurantLng!);
    }
    return null;
  }

  Future<void> _callDriver() async {
    final p = (_order?.driverPhone ?? '').trim();
    if (p.isEmpty) return;
    try {
      await launchUrl(Uri(scheme: 'tel', path: p));
    } catch (_) {}
  }

  Future<void> _maybeRate(OrderView o) async {
    if (_rated || o.rating != null) return;
    _rated = true;
    final stars = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RatingSheet(no: o.publicNo),
    );
    if (stars == null) return;
    try {
      await ref.read(orderApiProvider).rate(o.id, stars);
    } catch (_) {}
    if (mounted) Navigator.of(context).maybePop(); // asosiy ekranga qaytish
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(
        title: Text(o == null ? 'Buyurtma' : 'Buyurtma #${o.publicNo}'),
      ),
      body: o == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMap(o)),
                _panel(o),
              ],
            ),
    );
  }

  Widget _buildMap(OrderView o) {
    final overlays = <Widget>[];
    final live = _toCustomerLive.length >= 2;
    // Oshxona -> mijoz (ko'k) — kuryer olgach jonli marshrut o'rnini bosadi.
    if (_toCustomer.length >= 2 && !live) {
      overlays.add(PolylineLayer(polylines: [
        Polyline(
          points: _toCustomer,
          strokeWidth: 6,
          color: const Color(0xFF1E88E5),
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ]));
    }
    // Kuryer -> oshxona (to'q sariq)
    if (_toKitchen.length >= 2) {
      overlays.add(PolylineLayer(polylines: [
        Polyline(
          points: _toKitchen,
          strokeWidth: 6,
          color: const Color(0xFFFB8C00),
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ]));
    }
    // Kuryer -> mijoz (jonli, olingandan keyin) — ko'k, kuryer bilan siljiydi.
    if (live) {
      overlays.add(PolylineLayer(polylines: [
        Polyline(
          points: _toCustomerLive,
          strokeWidth: 6,
          color: const Color(0xFF1E88E5),
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ]));
    }
    final markers = <Marker>[];
    if (o.restaurantLat != null) {
      markers.add(pickupMarker(LatLng(o.restaurantLat!, o.restaurantLng!)));
    }
    if (o.addressLat != null) {
      markers.add(destMarker(LatLng(o.addressLat!, o.addressLng!)));
    }
    if (_driverLoc != null) {
      markers.add(Marker(
        point: _driverLoc!,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: const CarMarker(
            size: 32, color: Color(0xFFFB8C00), glow: true),
      ));
    }
    overlays.add(MarkerLayer(markers: markers));

    return BeshariqMap(
      controller: _map,
      initialCenter: _center ?? LocationService.beshariqCenter,
      initialZoom: 14,
      overlays: overlays,
    );
  }

  // ---------------- Pastki panel ----------------
  Widget _panel(OrderView o) {
    final scheme = Theme.of(context).colorScheme;
    final (label, sub, color, active) = _phase(o);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bosqichlar chizig'i — har o'zgarish darhol ko'rinadi.
              if (!o.isCancelled) ...[
                _StepsBar(status: o.status),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    if (active)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.6, color: color),
                      )
                    else
                      Icon(
                        o.isCancelled
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded,
                        color: color,
                        size: 28,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: color)),
                          if (sub.isNotEmpty)
                            Text(sub,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: scheme.outline)),
                        ],
                      ),
                    ),
                    if (_etaMinutes != null) ...[
                      const SizedBox(width: 8),
                      _etaChip(_etaMinutes!, color),
                    ],
                  ],
                ),
              ),
              if ((o.driverName ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        o.driverName!.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kuryer: ${o.driverName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          Row(children: [
                            if ((o.driverCar ?? '').isNotEmpty)
                              Flexible(
                                child: Text(o.driverCar!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: scheme.outline, fontSize: 12.5)),
                              ),
                            if ((o.driverPlate ?? '').isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _plateChip(o.driverPlate!),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    if ((o.driverPhone ?? '').isNotEmpty)
                      IconButton.filledTonal(
                        onPressed: _callDriver,
                        icon: const Icon(Icons.call_rounded),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${o.items.length} taom · ${o.addressText}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.outline)),
                  ),
                  const SizedBox(width: 10),
                  Text('${groupThousands(o.total)} so‘m',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ETA chipi: ~N daqiqa + taxminiy yetib borish soati (HH:MM).
  Widget _etaChip(int minutes, Color color) {
    final at = DateTime.now().add(Duration(minutes: minutes));
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('~$minutes daq',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          Text('$hh:$mm da',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _plateChip(String plate) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF1A237E), width: 1.4),
        ),
        child: Text(plate.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
                letterSpacing: 0.8,
                color: Color(0xFF1A237E))),
      );

  /// (label, sub, color, active-spinner)
  (String, String, Color, bool) _phase(OrderView o) {
    const blue = Color(0xFF1565C0);
    const orange = Color(0xFFEF6C00);
    const green = Color(0xFF2E7D32);
    switch (o.status) {
      case 'PENDING':
        final parts = <String>[];
        if (o.kitchenAccepted) parts.add('oshxona qabul qildi');
        if (o.hasDriver) parts.add('kuryer topildi');
        // Dispatch mexanizmi ~40s ichida haydovchi topadi (2 urinish × 20s);
        // shundan uzoqroq davom etsa, mijozga "odatdagidan uzoqroq" signali
        // beramiz — aks holda 2+ daqiqagacha o'zgarmas "tasdiqlanmoqda" turib
        // qoladi va bekor qilinganda mijoz kutilmaganda hayron qoladi.
        final createdAt = DateTime.tryParse(o.createdAt);
        final waitingLong = createdAt != null &&
            DateTime.now().difference(createdAt).inSeconds > 45 &&
            !o.hasDriver;
        return (
          'Tasdiqlanmoqda…',
          parts.isEmpty
              ? (waitingLong
                  ? 'Kuryer qidirilmoqda — odatdagidan biroz uzoqroq ketmoqda'
                  : 'Oshxona va kuryer bilan aloqa o‘rnatilmoqda')
              : '${parts.join(", ")} — ikkinchisi kutilmoqda',
          orange,
          true,
        );
      case 'ACCEPTED':
      case 'PREPARING':
        return ('Tayyorlanmoqda', 'Oshxona buyurtmani tayyorlamoqda', orange, true);
      case 'READY':
        return ('Tayyor', 'Kuryer buyurtmani olyapti', blue, true);
      case 'ASSIGNED':
      case 'IN_PROGRESS':
      case 'PICKED_UP':
        return ('Kuryer yo‘lda', 'Buyurtmangiz sizga yetkazilmoqda', blue, true);
      case 'DELIVERED':
      case 'COMPLETED':
        return ('Yetkazildi', 'Yoqimli ishtaha!', green, false);
      case 'FAILED':
        // Tizim avtomatik bekor qildi — kuryer topilmadi (dispatch.service.ts
        // POOL_FAIL_SEC). Bu holatda buyurtma summasi hech kimdan yechilmagan.
        return (
          'Bekor qilindi',
          'Afsuski, kuryer topa olmadik. Pulingiz yechilmagan — qayta buyurtma bering',
          Colors.red,
          false,
        );
      case 'CANCELLED':
        return (
          'Bekor qilindi',
          'Buyurtma bekor qilindi',
          Colors.red,
          false,
        );
      default:
        return ('Bekor qilindi', '', Colors.red, false);
    }
  }
}

/// Buyurtma bosqichlari chizig'i: Qabul -> Tayyorlash -> Yo'lda -> Yetkazildi.
/// Har bosqich: bajarilgan (yashil to'liq), joriy (rangli puls), kutilmoqda (kul).
class _StepsBar extends StatelessWidget {
  final String status;
  const _StepsBar({required this.status});

  int get _stage {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'ACCEPTED':
      case 'PREPARING':
      case 'READY':
        return 1;
      case 'ASSIGNED':
      case 'PICKED_UP':
      case 'IN_PROGRESS':
        return 2;
      case 'DELIVERED':
      case 'COMPLETED':
        return 3;
    }
    return 0;
  }

  static const _steps = [
    (Icons.receipt_long_rounded, 'Qabul'),
    (Icons.restaurant_rounded, 'Tayyorlash'),
    (Icons.delivery_dining_rounded, "Yo'lda"),
    (Icons.home_rounded, 'Yetkazildi'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const green = Color(0xFF2E7D32);
    final stage = _stage;
    final delivered = stage == 3;
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i <= stage
                      ? green
                      : scheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: i < stage || (delivered && i == 3)
                      ? green
                      : (i == stage
                          ? green.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.7)),
                  shape: BoxShape.circle,
                  border: i == stage && !delivered
                      ? Border.all(color: green, width: 2)
                      : null,
                ),
                child: Icon(
                  i < stage || (delivered && i == 3)
                      ? Icons.check_rounded
                      : _steps[i].$1,
                  size: 17,
                  color: i < stage || (delivered && i == 3)
                      ? Colors.white
                      : (i == stage ? green : scheme.outline),
                ),
              ),
              const SizedBox(height: 3),
              Text(_steps[i].$2,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        i == stage ? FontWeight.w800 : FontWeight.w600,
                    color: i <= stage ? green : scheme.outline,
                  )),
            ],
          ),
        ],
      ],
    );
  }
}

/// Baholash (yulduzlar).
class _RatingSheet extends StatefulWidget {
  final int no;
  const _RatingSheet({required this.no});
  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 5;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_rounded,
              size: 40, color: Color(0xFF2E7D32)),
          const SizedBox(height: 8),
          Text('Buyurtma #${widget.no} yetkazildi',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Xizmatni baholang', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                IconButton(
                  iconSize: 38,
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF6A609)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _rating),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50)),
              child: const Text('Yuborish'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keyinroq'),
          ),
        ],
      ),
    );
  }
}
