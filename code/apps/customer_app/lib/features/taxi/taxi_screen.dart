import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/beshariq_map.dart';
import '../../core/location_service.dart';
import '../../core/places.dart';
import '../../core/routing_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../map/map_picker_screen.dart';
import 'taxi_api.dart';
import 'taxi_chat_screen.dart';
import 'taxi_models.dart';

/// Taksi chaqirish — xaritali oqim. plan/05-customer-app.md, plan/12-maps-navigation.md
class TaxiScreen extends ConsumerStatefulWidget {
  const TaxiScreen({super.key});

  @override
  ConsumerState<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends ConsumerState<TaxiScreen> {
  final MapController _map = MapController();
  LatLng? _myLoc;
  GeoPlace? _from;
  GeoPlace? _to;
  bool _noDest = false;
  TaxiEstimate? _estimate;
  bool _requesting = false;
  String? _error;
  List<LatLng> _cars = const []; // real yaqin haydovchilar
  List<LatLng> _routeLine = const [];
  Timer? _ticker;
  int _tick = 0;
  DateTime? _orderedAt;
  String? _ratedHandledId;

  // Jonli kuzatuv (biriktirilgan haydovchi)
  String? _activeTripId;
  String? _activeStatus;
  LatLng? _driverLoc;
  List<LatLng> _driverRoute = const [];
  int? _etaMinutes;
  bool _etaToDestination = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Har soniya: mashinalar harakati + 5 soniyada safar holatini yangilash.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _map.dispose();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    _tick++;
    setState(() {}); // jonli taymer ko'rinishini yangilab turish
    if (_tick % 5 == 0) ref.invalidate(myTripsProvider);
    if (_tick % 6 == 0) _refreshNearby(); // real yaqin mashinalar
    if (_tick % 4 == 0) _refreshDriverLocation(); // biriktirilgan haydovchi
  }

  Future<void> _initLocation() async {
    final t = AppLocalizations.of(context)!;
    final svc = ref.read(locationServiceProvider);
    // Majburiy GPS — ruxsat/xizmatni so'raymiz, so'ng joylashuvni olamiz.
    await svc.ensurePermission();
    final pos = await svc.currentLatLng();
    if (!mounted) return;
    setState(() {
      _myLoc = pos;
      // Joriy joylashuvni "Qayerdan" sifatida avtomatik o'rnatamiz.
      if (pos != null) {
        _from = GeoPlace(t.taxiCurrentLocation, pos.latitude, pos.longitude);
      }
    });
    if (pos != null) {
      _map.move(pos, 16);
      _refreshNearby(); // atrofdagi real mashinalar
    }
  }

  LatLng get _center =>
      _myLoc ??
      (_from != null
          ? LatLng(_from!.lat, _from!.lng)
          : LocationService.beshariqCenter);

  Future<void> _pick({required bool isFrom}) async {
    final initial = isFrom
        ? (_from != null ? LatLng(_from!.lat, _from!.lng) : _myLoc)
        : (_to != null ? LatLng(_to!.lat, _to!.lng) : _myLoc);
    final result = await Navigator.of(context).push<GeoPlace>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initial: initial ?? _center),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isFrom) {
        _from = result;
      } else {
        _to = result;
      }
    });
    await _recompute();
  }

  Future<void> _recompute() async {
    if (_noDest || _from == null || _to == null) {
      setState(() {
        _estimate = null;
        _routeLine = const [];
      });
      return;
    }
    try {
      final e = await ref.read(taxiApiProvider).estimate(_from!, _to!);
      if (mounted) setState(() => _estimate = e);
    } catch (_) {
      if (mounted) setState(() => _estimate = null);
    }
    // Yo'l marshruti — chiziq yo'llar ustidan ketsin (to'g'ri chiziq emas).
    final pts = await ref.read(routingServiceProvider).route(
          LatLng(_from!.lat, _from!.lng),
          LatLng(_to!.lat, _to!.lng),
        );
    if (mounted) setState(() => _routeLine = pts);
  }

  Future<void> _request() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null) return;
    if (!_noDest && _to == null) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      await ref.read(taxiApiProvider).request(_from!, _noDest ? null : _to);
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      _orderedAt = DateTime.now();
      _refreshNearby();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.taxiRequested)));
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  /// Xaritadagi real "yaqin mashinalar" — online haydovchilar (backend).
  Future<void> _refreshNearby() async {
    final base = _from != null
        ? LatLng(_from!.lat, _from!.lng)
        : (_myLoc ?? LocationService.beshariqCenter);
    try {
      final cars = await ref
          .read(taxiApiProvider)
          .nearbyDrivers(base.latitude, base.longitude);
      if (mounted) setState(() => _cars = cars);
    } catch (_) {/* tarmoq — jim o'tkazamiz */}
  }

  /// Biriktirilgan haydovchining jonli joylashuvi + ETA (OSRM).
  Future<void> _refreshDriverLocation() async {
    final id = _activeTripId;
    if (id == null) {
      if (_driverLoc != null || _driverRoute.isNotEmpty || _etaMinutes != null) {
        setState(() {
          _driverLoc = null;
          _driverRoute = const [];
          _etaMinutes = null;
        });
      }
      return;
    }
    try {
      final loc = await ref.read(taxiApiProvider).driverLocation(id);
      if (!mounted) return;
      if (loc == null) {
        setState(() {
          _driverLoc = null;
          _driverRoute = const [];
          _etaMinutes = null;
        });
        return;
      }
      final driver = LatLng(loc.lat, loc.lng);
      setState(() => _driverLoc = driver);
      // IN_PROGRESS bo'lsa manzilga, aks holda olib ketish nuqtasiga ETA.
      final toDest = _activeStatus == 'IN_PROGRESS' && _to != null;
      final target = toDest
          ? LatLng(_to!.lat, _to!.lng)
          : (_from != null ? LatLng(_from!.lat, _from!.lng) : null);
      if (target == null) return;
      final dir =
          await ref.read(routingServiceProvider).directions(driver, target);
      if (!mounted || dir == null) return;
      setState(() {
        _driverRoute = dir.points;
        _etaMinutes = dir.etaMinutes;
        _etaToDestination = toDest;
      });
    } catch (_) {/* tarmoq — jim o'tkazamiz */}
  }

  Future<void> _cancel(String id) async {
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(taxiApiProvider).cancel(id);
      ref.invalidate(myTripsProvider);
      setState(() {
        _driverLoc = null;
        _driverRoute = const [];
        _etaMinutes = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final trips = ref.watch(myTripsProvider).valueOrNull ?? const [];
    final active = trips
        .where((tr) =>
            tr.status == 'PENDING' ||
            tr.status == 'ACCEPTED' ||
            tr.status == 'IN_PROGRESS')
        .toList();
    final activeTrip = active.isNotEmpty ? active.first : null;
    // Jonli kuzatuv uchun (ticker o'qiydi).
    _activeTripId = activeTrip?.id;
    _activeStatus = activeTrip?.status;

    // Yakunlangan, hali baholanmagan safar — reyting oynasini ko'rsatamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRate(trips));

    return Scaffold(
      appBar: AppBar(title: Text(t.taxiTitle)),
      body: Column(
        children: [
          Expanded(child: _buildMap()),
          if (activeTrip != null)
            _activePanel(t, activeTrip)
          else
            _bookingPanel(t),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final overlays = <Widget>[];

    // Marshrut: booking (ko'k) — yo'l geometriyasi yoki to'g'ri chiziq zaxira.
    final line = _routeLine.isNotEmpty
        ? _routeLine
        : ((_from != null && _to != null && !_noDest)
            ? [LatLng(_from!.lat, _from!.lng), LatLng(_to!.lat, _to!.lng)]
            : null);
    if (line != null) {
      overlays.add(PolylineLayer(polylines: [
        Polyline(
          points: line,
          strokeWidth: 6,
          color: const Color(0xFF1E88E5),
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ]));
    }
    // Haydovchining jonli marshruti — to'q sariq.
    if (_driverRoute.length >= 2) {
      overlays.add(PolylineLayer(polylines: [
        Polyline(
          points: _driverRoute,
          strokeWidth: 6,
          color: const Color(0xFFFB8C00),
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ]));
    }

    final markers = <Marker>[];
    // Haydovchi qidirilayotganda boshlang'ich nuqtada radar pulsi.
    if (_activeStatus == 'PENDING' && _from != null) {
      markers.add(searchPulseMarker(LatLng(_from!.lat, _from!.lng)));
    }
    // Yaqin mashinalar.
    for (final c in _cars) {
      markers.add(Marker(
        point: c,
        width: 34,
        height: 34,
        child: _carBadge(const Color(0xFFFFB300)),
      ));
    }
    // Joriy GPS ("siz turgan joy") — faqat pickupdan farq qilsa (ortiqcha emas).
    if (_myLoc != null && _farFromPickup(_myLoc!)) {
      markers.add(myLocationMarker(_myLoc!));
    }
    // Boshlang'ich (yashil doira) va yakuniy (qizil pin) — aniq farqli.
    if (_from != null) markers.add(pickupMarker(LatLng(_from!.lat, _from!.lng)));
    if (_to != null && !_noDest) {
      markers.add(destMarker(LatLng(_to!.lat, _to!.lng)));
    }
    // Biriktirilgan haydovchi.
    if (_driverLoc != null) {
      markers.add(Marker(
        point: _driverLoc!,
        width: 44,
        height: 44,
        child: _carBadge(const Color(0xFFFB8C00), big: true),
      ));
    }
    overlays.add(MarkerLayer(markers: markers));

    return Stack(
      children: [
        BeshariqMap(
          controller: _map,
          initialCenter: _center,
          initialZoom: 15,
          overlays: overlays,
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'taxiMyLoc',
            onPressed: _recenter,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  /// GPS nuqtasi tanlangan boshlang'ich nuqtadan sezilarli uzoqmi (~40m).
  bool _farFromPickup(LatLng p) {
    if (_from == null) return true;
    return (p.latitude - _from!.lat).abs() > 0.0004 ||
        (p.longitude - _from!.lng).abs() > 0.0004;
  }

  Widget _carBadge(Color color, {bool big = false}) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: big ? 3 : 2.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: Icon(Icons.local_taxi, color: Colors.white, size: big ? 24 : 20),
      );

  Future<void> _recenter() async {
    final pos = await ref.read(locationServiceProvider).currentLatLng();
    if (!mounted || pos == null) return;
    _map.move(pos, 16);
    setState(() => _myLoc = pos);
  }

  // ---------- Buyurtma paneli ----------
  Widget _bookingPanel(AppLocalizations t) {
    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _addressRow(
            icon: Icons.my_location,
            color: Colors.green,
            label: _from?.label ?? t.taxiSelectFromHint,
            filled: _from != null,
            onTap: () => _pick(isFrom: true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _addressRow(
                  icon: Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  label: _noDest
                      ? t.taxiMeteredBadge
                      : (_to?.label ?? t.taxiSelectToHint),
                  filled: _noDest || _to != null,
                  onTap: _noDest ? null : () => _pick(isFrom: false),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  t.taxiMeteredBadge,
                  style: TextStyle(
                    color: _noDest
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _noDest,
                showCheckmark: false,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                selectedColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: _noDest
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                onSelected: (v) {
                  setState(() {
                    _noDest = v;
                    if (v) _to = null;
                  });
                  _recompute();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fareLine(t),
          if (_cars.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_taxi,
                      size: 14, color: Color(0xFFFFB300)),
                  const SizedBox(width: 6),
                  Text(t.taxiNearbyCars(_cars.length.toString()),
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed:
                (_requesting || _from == null || (!_noDest && _to == null))
                    ? null
                    : _request,
            icon: _requesting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.local_taxi),
            label: Text(t.taxiRequest),
          ),
        ],
      ),
    );
  }

  Widget _fareLine(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    if (_estimate != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(t.priceSom(groupThousands(_estimate!.fare)),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary)),
            const SizedBox(width: 6),
            Text('· ${t.taxiKm(_estimate!.distanceKm.toStringAsFixed(1))}',
                style: TextStyle(color: scheme.outline)),
          ],
        ),
      );
    }
    // Manzil yo'q — minimal narx
    final tariff = ref.watch(taxiTariffProvider).valueOrNull;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 18, color: scheme.outline),
          const SizedBox(width: 6),
          Text(
            tariff != null
                ? t.taxiFareFrom(groupThousands(tariff.minFare))
                : '…',
            style: TextStyle(fontWeight: FontWeight.w600, color: scheme.outline),
          ),
        ],
      ),
    );
  }

  // ---------- Faol safar paneli ----------
  Widget _activePanel(AppLocalizations t, TaxiTrip trip) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = _statusInfo(t, trip.status);
    final pending = trip.status == 'PENDING';
    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.taxiTripNo(trip.publicNo.toString()),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          if (pending)
            Row(
              children: [
                const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(t.taxiSearchingCars,
                        style: TextStyle(color: scheme.outline))),
                if (_elapsed() != null)
                  Text(_elapsed()!,
                      style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            )
          else
            Text(
              trip.fare > 0
                  ? t.priceSom(groupThousands(trip.fare))
                  : t.taxiMeteredHint,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (!pending && _etaMinutes != null) ...[
            const SizedBox(height: 10),
            _etaChip(t),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (trip.status == 'ACCEPTED' || trip.status == 'IN_PROGRESS')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaxiChatScreen(
                          tripId: trip.id,
                          tripTitle: t.taxiTripNo(trip.publicNo.toString()),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(t.chatTitle),
                  ),
                ),
              if ((trip.status == 'PENDING' || trip.status == 'ACCEPTED')) ...[
                if (trip.status == 'ACCEPTED' || trip.status == 'IN_PROGRESS')
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(trip.id),
                    icon: Icon(Icons.close, size: 18, color: scheme.error),
                    label: Text(t.taxiCancel,
                        style: TextStyle(color: scheme.error)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5))),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Haydovchi/manzil ETA chipi (jonli, OSRM bo'yicha).
  Widget _etaChip(AppLocalizations t) {
    final m = _etaMinutes!.toString();
    final label = _etaToDestination ? t.taxiArriveEta(m) : t.taxiDriverEta(m);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFB8C00).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_car, size: 18, color: Color(0xFFFB8C00)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Widget _addressRow({
    required IconData icon,
    required Color color,
    required String label,
    required bool filled,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled ? scheme.onSurface : scheme.outline,
                    fontWeight: filled ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(AppLocalizations t, String status) {
    switch (status) {
      case 'ACCEPTED':
        return (t.taxiStatusAccepted, Colors.blue);
      case 'IN_PROGRESS':
        return (t.taxiStatusInProgress, Colors.orange);
      default:
        return (t.taxiStatusPending, Colors.grey);
    }
  }

  String? _elapsed() {
    if (_orderedAt == null) return null;
    final s = DateTime.now().difference(_orderedAt!).inSeconds;
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  /// Yakunlangan, baholanmagan safar uchun reyting oynasi (bir marta).
  Future<void> _maybeRate(List<TaxiTrip> trips) async {
    final done = trips
        .where((tr) => tr.status == 'COMPLETED' && tr.rating == null)
        .toList();
    if (done.isEmpty) return;
    final trip = done.first;
    if (_ratedHandledId == trip.id) return;
    _ratedHandledId = trip.id;
    _orderedAt = null;
    final result = await showModalBottomSheet<({int rating, String? comment})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RatingSheet(fare: trip.fare),
    );
    if (result == null) return;
    try {
      await ref
          .read(taxiApiProvider)
          .rate(trip.id, result.rating, comment: result.comment);
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.rateThanks)));
    } catch (_) {/* best-effort */}
  }
}

/// Safarni baholash varaqasi — yulduzlar + ixtiyoriy izoh.
class _RatingSheet extends StatefulWidget {
  final int fare;
  const _RatingSheet({required this.fare});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          Text(t.taxiStatusCompleted,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (widget.fare > 0)
            Text(t.priceSom(groupThousands(widget.fare)),
                style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 12),
          Text(t.rateSubtitle, style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                iconSize: 38,
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(filled ? Icons.star : Icons.star_border,
                    color: Colors.amber),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(hintText: t.rateHint),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              rating: _rating,
              comment: _commentCtrl.text.trim().isEmpty
                  ? null
                  : _commentCtrl.text.trim(),
            )),
            child: Text(t.rateSubmit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.rateSkip),
          ),
        ],
      ),
    );
  }
}
