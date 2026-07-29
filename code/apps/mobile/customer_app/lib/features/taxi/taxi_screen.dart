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
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/car_marker.dart';
import '../geo/geo_api.dart';
import '../map/map_picker_screen.dart';
import '../profile/profile_api.dart';
import '../profile/profile_models.dart';
import 'taxi_api.dart';
import 'taxi_chat_screen.dart';
import 'taxi_models.dart';

/// Taksi chaqirish — xaritali oqim. plan/05-customer-app.md, plan/12-maps-navigation.md
class TaxiScreen extends ConsumerStatefulWidget {
  const TaxiScreen({super.key});

  @override
  ConsumerState<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends ConsumerState<TaxiScreen>
    with SingleTickerProviderStateMixin {
  final MapController _map = MapController();
  LatLng? _myLoc;
  GeoPlace? _from;
  GeoPlace? _to;
  bool _noDest = false;
  TaxiEstimate? _estimate;
  String _tariffClass = 'start'; // start | comfort
  int? _routeEta; // OSRM bo'yicha taxminiy yurish vaqti (daqiqa)
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

  // Haydovchi belgisining silliq harakat animatsiyasi (har 4s GPS yangilanishi
  // orasida sakramasdan, doim yo'l bo'ylab suzib boruvchi ko'rinish uchun).
  late final AnimationController _driverAnimCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  )..addListener(_onDriverAnimTick);
  LatLng? _driverAnimFrom;
  LatLng? _driverAnimTo;
  LatLng? _driverAnimatedLoc;

  void _onDriverAnimTick() {
    final from = _driverAnimFrom;
    final to = _driverAnimTo;
    if (from == null || to == null) return;
    final t = Curves.easeInOut.transform(_driverAnimCtrl.value);
    setState(() => _driverAnimatedLoc = LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        ));
  }

  @override
  void initState() {
    super.initState();
    // Admin belgilagan joylarni qayta yuklash (yangi qo'shilganlar ko'rinsin).
    Future.microtask(() => ref.invalidate(placesProvider));
    _initLocation();
    // Har soniya: mashinalar harakati + 5 soniyada safar holatini yangilash.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _driverAnimCtrl.dispose();
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
        builder: (_) => MapPickerScreen(initial: initial),
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
        _routeEta = null;
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
    // Yo'l marshruti + aniq yurish vaqti — OSRM (chiziq yo'llar ustidan ketsin).
    final dir = await ref.read(routingServiceProvider).directions(
          LatLng(_from!.lat, _from!.lng),
          LatLng(_to!.lat, _to!.lng),
        );
    if (mounted && dir != null) {
      setState(() {
        _routeLine = dir.points;
        _routeEta = dir.etaMinutes;
      });
    }
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
      await ref.read(taxiApiProvider).request(
            _from!,
            _noDest ? null : _to,
            tariffClass: _tariffClass,
          );
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      _orderedAt = DateTime.now();
      _refreshNearby();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
      }
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
          _driverAnimatedLoc = null;
          _driverAnimFrom = null;
          _driverAnimTo = null;
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
          _driverAnimatedLoc = null;
          _driverAnimFrom = null;
          _driverAnimTo = null;
          _driverRoute = const [];
          _etaMinutes = null;
        });
        return;
      }
      final driver = LatLng(loc.lat, loc.lng);
      // Eski (yoki hozir animatsiya bilan ko'rsatilayotgan) nuqtadan yangi
      // GPS nuqtasigacha silliq suzib boradi — sakramaydi.
      final animFrom = _driverAnimatedLoc ?? _driverLoc ?? driver;
      setState(() {
        _driverLoc = driver;
        _driverAnimFrom = animFrom;
        _driverAnimTo = driver;
      });
      _driverAnimCtrl.forward(from: 0);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.taxiCancel),
        content: const Text('Buyurtmani bekor qilmoqchimisiz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Yo‘q')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ha, bekor qilish'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(taxiApiProvider).cancel(id);
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      setState(() {
        _driverLoc = null;
        _driverAnimatedLoc = null;
        _driverAnimFrom = null;
        _driverAnimTo = null;
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
    final active = trips.where((tr) => tr.isActive).toList();
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
    // Yaqin mashinalar — tepadan ko'rinishdagi professional avtomobil.
    for (final c in _cars) {
      markers.add(Marker(
        point: c,
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: const CarMarker(size: 26, color: Color(0xFFFFB300)),
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
    // Biriktirilgan haydovchi — porlagan avtomobil (ajralib turadi).
    // Silliq animatsiyalangan nuqta (mavjud bo'lsa) — sakramasdan suzadi.
    final driverDisplayLoc = _driverAnimatedLoc ?? _driverLoc;
    if (driverDisplayLoc != null) {
      markers.add(Marker(
        point: driverDisplayLoc,
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child:
            const CarMarker(size: 34, color: Color(0xFFFB8C00), glow: true),
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
          right: 14,
          bottom: 14,
          child: MapCircleButton(
            icon: Icons.my_location_rounded,
            onPressed: _recenter,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RouteFields(
            fromLabel: _from?.label ?? t.taxiSelectFromHint,
            toLabel: _noDest
                ? t.taxiMeteredBadge
                : (_to?.label ?? t.taxiSelectToHint),
            fromFilled: _from != null,
            toFilled: _noDest || _to != null,
            onFromTap: () => _pick(isFrom: true),
            onToTap: _noDest ? null : () => _pick(isFrom: false),
            toTrailing: _meteredToggle(t),
          ),
          _savedAddressChips(t),
          const SizedBox(height: 12),
          _tariffSelector(t),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          BrandButton(
            label: t.taxiRequest,
            icon: Icons.local_taxi_rounded,
            loading: _requesting,
            onPressed: (_from == null || (!_noDest && _to == null))
                ? null
                : _request,
          ),
        ],
      ),
    );
  }

  /// "Manzilsiz" rejimi tugmasi — ixcham pill (Qayerga qatorining o'ngida).
  Widget _meteredToggle(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _noDest = !_noDest;
            if (_noDest) _to = null;
          });
          _recompute();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _noDest ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _noDest ? scheme.primary : scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore_outlined,
                  size: 14, color: _noDest ? Colors.white : scheme.outline),
              const SizedBox(width: 4),
              Text(
                t.taxiMeteredBadge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _noDest ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Saqlangan manzillar — taksi uchun qulay chiplar (xaritaga xalaqit bermaydi).
  /// Tanlanganda joriy joylashuvdan o'sha manzilgacha narx avtomatik hisoblanadi.
  Widget _savedAddressChips(AppLocalizations t) {
    if (_noDest) return const SizedBox.shrink();
    final saved = ref.watch(addressesProvider).valueOrNull ?? const <Address>[];
    final withCoords =
        saved.where((a) => a.lat != null && a.lng != null).toList();
    if (withCoords.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: withCoords.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final a = withCoords[i];
            final selected = _to != null &&
                (_to!.lat - a.lat!).abs() < 1e-6 &&
                (_to!.lng - a.lng!).abs() < 1e-6;
            return ActionChip(
              avatar: Icon(
                a.isDefault ? Icons.home : Icons.bookmark_border,
                size: 16,
                color: selected ? scheme.onPrimary : scheme.primary,
              ),
              label: Text(a.label),
              labelStyle: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor:
                  selected ? scheme.primary : scheme.surfaceContainerHighest,
              side: BorderSide(
                  color: selected ? scheme.primary : scheme.outlineVariant),
              onPressed: () => _selectSavedAddress(a),
            );
          },
        ),
      ),
    );
  }

  void _selectSavedAddress(Address a) {
    if (a.lat == null || a.lng == null) return;
    setState(() {
      _noDest = false;
      _to = GeoPlace(a.label, a.lat!, a.lng!);
    });
    _recompute(); // joriy GPS (_from) -> saqlangan manzilgacha narx avtomatik
  }

  /// Tarif tanlagichi — Start / Comfort kartalari (nomi + ostida safar narxi)
  /// va yo'l ma'lumoti (masofa + taxminiy vaqt + yaqin mashinalar).
  Widget _tariffSelector(AppLocalizations t) {
    final est = _estimate;
    final tariff = ref.watch(taxiTariffProvider).valueOrNull;

    // Narxlar: hisoblangan bo'lsa aniq; ammo qisqa masofada narx minimal
    // chegaraga tegib qolgan bo'lsa (masofa narxga ta'sir qilmagan), bu ham
    // "dan" (boshlang'ich) sifatida ko'rsatiladi — aks holda mijoz narx
    // aniq shu masofa uchun hisoblangan deb o'ylab qolishi mumkin.
    // Manzilsiz/hisoblanmagan holatda ham xuddi shu "dan" formati ishlatiladi.
    String startPrice;
    String comfortPrice;
    if (est != null) {
      final atMinStart = tariff != null && est.fare <= tariff.minFare;
      final atMinComfort = tariff != null && est.fareComfort <= tariff.minFareComfort;
      startPrice = atMinStart
          ? t.taxiFareFrom(groupThousands(est.fare))
          : t.priceSom(groupThousands(est.fare));
      comfortPrice = atMinComfort
          ? t.taxiFareFrom(groupThousands(est.fareComfort))
          : t.priceSom(groupThousands(est.fareComfort));
    } else if (tariff != null) {
      startPrice = t.taxiFareFrom(groupThousands(tariff.baseFare));
      comfortPrice = t.taxiFareFrom(groupThousands(tariff.baseFareComfort));
    } else {
      startPrice = '…';
      comfortPrice = '…';
    }

    final eta = _routeEta ?? est?.etaMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Yo'l ma'lumoti qatori — masofa · vaqt · mashinalar
        if (est != null || _cars.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (est != null) ...[
                  _routeInfo(Icons.route_rounded,
                      t.taxiKm(est.distanceKm.toStringAsFixed(1))),
                  if (eta != null && eta > 0) ...[
                    _infoDot(),
                    _routeInfo(Icons.schedule_rounded, '~$eta daqiqa'),
                  ],
                ],
                if (_cars.isNotEmpty) ...[
                  if (est != null) _infoDot(),
                  _routeInfo(Icons.local_taxi_rounded,
                      t.taxiNearbyCars(_cars.length.toString())),
                ],
              ],
            ),
          ),
        // Tarif kartalari
        Row(
          children: [
            _tariffCard(
              value: 'start',
              icon: Icons.directions_car_filled_rounded,
              name: 'Start',
              price: startPrice,
            ),
            const SizedBox(width: 10),
            _tariffCard(
              value: 'comfort',
              icon: Icons.workspace_premium_rounded,
              name: 'Comfort',
              price: comfortPrice,
            ),
          ],
        ),
      ],
    );
  }

  /// Yo'l ma'lumoti elementi (masofa/vaqt/mashina).
  Widget _routeInfo(IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.outline),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _infoDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3.5,
        height: 3.5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Bitta tarif kartasi — tanlansa brend gradient, aks holda yumshoq sirt.
  Widget _tariffCard({
    required String value,
    required IconData icon,
    required String name,
    required String price,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _tariffClass == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _tariffClass = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [AppTheme.brand, AppTheme.brandDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected
                ? null
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.brand.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 24,
                  color: selected ? Colors.white : scheme.outline),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.9)
                                : scheme.primary)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Faol safar paneli ----------
  Widget _activePanel(AppLocalizations t, TaxiTrip trip) {
    final scheme = Theme.of(context).colorScheme;
    final (label, statusColor) = _statusInfo(t, trip.status);
    final pending = trip.status == 'PENDING';

    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sarlavha: raqam + holat badge
          Row(
            children: [
              Text(
                t.taxiTripNo(trip.publicNo.toString()),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              _statusBadge(label, statusColor),
            ],
          ),
          const SizedBox(height: 12),

          if (pending) ...[
            // Qidiruv holati
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.taxiSearchingCars,
                      style: TextStyle(color: scheme.onSurface, fontSize: 14),
                    ),
                  ),
                  if (_elapsed() != null)
                    Text(
                      _elapsed()!,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _cancel(trip.id),
              icon: Icon(Icons.close, size: 18, color: scheme.error),
              label: Text(t.taxiCancel, style: TextStyle(color: scheme.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
              ),
            ),
          ] else ...[
            // Haydovchi kartochkasi
            _driverCard(trip),
            const SizedBox(height: 10),

            // Narx + ETA qatori
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.payments_outlined,
                    topLabel: 'Narx',
                    value: trip.displayFare > 0
                        ? t.priceSom(groupThousands(trip.displayFare))
                        : t.taxiMeteredHint,
                    subLabel: trip.currentWaitFee > 0
                        ? '+${groupThousands(trip.currentWaitFee)} kutish'
                        : null,
                    color: scheme.primary,
                  ),
                ),
                if (_etaMinutes != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoTile(
                      icon: Icons.directions_car_outlined,
                      topLabel: _etaToDestination ? 'Yetib borish' : 'Keladi',
                      value: '~$_etaMinutes daq',
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ],
            ),

            if (trip.paidWaiting) ...[
              const SizedBox(height: 8),
              _waitWarning(),
            ],

            const SizedBox(height: 12),

            // Tugmalar
            Row(
              children: [
                if (trip.hasChat)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaxiChatScreen(
                            tripId: trip.id,
                            tripTitle: t.taxiTripNo(trip.publicNo.toString()),
                            phone: trip.driverPhone,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(t.chatTitle),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44)),
                    ),
                  ),
                if (trip.isCancellable) ...[
                  if (trip.hasChat) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(trip.id),
                      icon: Icon(Icons.close, size: 18, color: scheme.error),
                      label: Text(t.taxiCancel,
                          style: TextStyle(color: scheme.error)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Holat badge — rangli pill (qidirilmoqda / yo'lda / yetdi / ketmoqda).
  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Haydovchi kartochkasi — ism/reyting chapda, mashina/raqam o'ngda.
  Widget _driverCard(TaxiTrip trip) {
    final scheme = Theme.of(context).colorScheme;
    final name = (trip.driverName ?? '').trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initial,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Haydovchi' : name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 15, color: Color(0xFFF6A609)),
                    const SizedBox(width: 3),
                    Text(
                      trip.driverRatingCount > 0
                          ? trip.driverRating.toStringAsFixed(1)
                          : 'Yangi',
                      style: TextStyle(
                          color: scheme.outline,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    if (trip.driverRatingCount > 0)
                      Text(
                        '  ·  ${trip.driverRatingCount} ta',
                        style:
                            TextStyle(color: scheme.outline, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Mashina ma'lumoti o'ng tomonda — uzun modellar Row'ni
          // yorib chiqmasligi uchun cheklangan (Flexible + ellipsis).
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((trip.driverCar ?? '').isNotEmpty)
                  Text(
                    trip.driverCar!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.outline,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                if ((trip.driverPlate ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _plateChip(trip.driverPlate!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Raqamli davlat raqami chipi.
  Widget _plateChip(String plate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1A237E), width: 1.6),
      ),
      child: Text(
        plate.toUpperCase(),
        style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
            color: Color(0xFF1A237E)),
      ),
    );
  }

  /// Rangli ma'lumot katakchasi: narx yoki ETA uchun.
  Widget _infoTile({
    required IconData icon,
    required String topLabel,
    required String value,
    String? subLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(topLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(subLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  /// Pastki panel — umumiy AppPanel + kichik ekranlarda scroll (overflow yo'q).
  Widget _panel({required Widget child}) {
    final h = MediaQuery.of(context).size.height;
    return AppPanel(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.52),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: child,
        ),
      ),
    );
  }

  (String, Color) _statusInfo(AppLocalizations t, String status) {
    switch (status) {
      case 'ACCEPTED':
        return ('Yo\'lda', const Color(0xFF1565C0));
      case 'ARRIVED':
        return ('Yetib keldi', const Color(0xFF2E7D32));
      case 'IN_PROGRESS':
        return ('Ketmoqda', const Color(0xFFE65100));
      default:
        return ('Qidirilmoqda', Colors.grey);
    }
  }

  /// Pulli kutish ogohlantirishi — haydovchi kutmoqda, narx oshmoqda.
  Widget _waitWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.running_with_errors_rounded,
              color: Color(0xFFC62828), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shoshiling — pulli kutish! Haydovchi allaqachon sizni kutmoqda.',
              style: TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
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
