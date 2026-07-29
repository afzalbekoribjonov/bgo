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
import '../geo/geo_api.dart';
import '../map/map_picker_screen.dart';
import '../taxi/taxi_chat_screen.dart';
import 'parcel_api.dart';
import 'parcel_models.dart';

/// Dostavka (pochta) — xaritali oqim. plan/05-customer-app.md, plan/12-maps-navigation.md
class ParcelScreen extends ConsumerStatefulWidget {
  const ParcelScreen({super.key});

  @override
  ConsumerState<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends ConsumerState<ParcelScreen> {
  final MapController _map = MapController();
  LatLng? _myLoc;
  GeoPlace? _from;
  GeoPlace? _to;
  ParcelSize _size = ParcelSize.small;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ParcelEstimate? _estimate;
  bool _sending = false;
  String? _error;
  List<LatLng> _routeLine = const [];
  int _step = 0; // 0=manzil, 1=hajm, 2=qabul qiluvchi, 3=tasdiqlash
  String? _ratedHandledId;
  Timer? _poll;
  // Faol dostavka kuzatuvi — jonli kuryer + marshrut (taksi kabi).
  LatLng? _driverLoc;
  String? _trackedId;
  LatLng? _trackFrom;
  LatLng? _trackTo;
  List<LatLng> _trackRoute = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(placesProvider));
    _initLocation();
    // Faol dostavka holatini + kuryer joylashuvini jonli yangilab turish.
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      ref.invalidate(myParcelsProvider);
      _pollDriver();
    });
  }

  /// Kuzatuvdagi dostavka kuryerining jonli joylashuvini oladi.
  Future<void> _pollDriver() async {
    final id = _trackedId;
    if (id == null) return;
    try {
      final loc = await ref.read(parcelApiProvider).driverLocation(id);
      if (!mounted) return;
      setState(() => _driverLoc = loc == null ? null : LatLng(loc.lat, loc.lng));
    } catch (_) {}
  }

  /// Faol dostavka o'zgarsa — kuzatuv marshruti va kuryer kuzatuvini sozlaydi.
  void _syncTracking(ParcelDelivery? active) {
    if (active == null ||
        active.pickupLat == null ||
        active.destLat == null) {
      if (_trackedId != null) {
        setState(() {
          _trackedId = null;
          _trackFrom = null;
          _trackTo = null;
          _trackRoute = const [];
          _driverLoc = null;
        });
      }
      return;
    }
    if (active.id == _trackedId) return;
    final from = LatLng(active.pickupLat!, active.pickupLng!);
    final to = LatLng(active.destLat!, active.destLng!);
    setState(() {
      _trackedId = active.id;
      _trackFrom = from;
      _trackTo = to;
      _trackRoute = const [];
    });
    _map.move(from, 14);
    _pollDriver();
    ref.read(routingServiceProvider).route(from, to).then((pts) {
      if (mounted && _trackedId == active.id) {
        setState(() => _trackRoute = pts);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final t = AppLocalizations.of(context)!;
    final svc = ref.read(locationServiceProvider);
    await svc.ensurePermission();
    final pos = await svc.currentLatLng();
    if (!mounted) return;
    setState(() {
      _myLoc = pos;
      if (pos != null) {
        _from = GeoPlace(t.taxiCurrentLocation, pos.latitude, pos.longitude);
      }
    });
    if (pos != null) _map.move(pos, 16);
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
      _estimate = null;
    });
    await _recompute();
  }

  Future<void> _recompute() async {
    if (_from == null || _to == null) {
      setState(() => _routeLine = const []);
      return;
    }
    await _doEstimate();
    final pts = await ref.read(routingServiceProvider).route(
          LatLng(_from!.lat, _from!.lng),
          LatLng(_to!.lat, _to!.lng),
        );
    if (mounted) setState(() => _routeLine = pts);
  }

  Future<void> _doEstimate() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null || _to == null) return;
    if (_from == _to) {
      setState(() => _error = t.taxiSamePoint);
      return;
    }
    setState(() {
      _error = null;
      _estimate = null;
    });
    try {
      final e = await ref.read(parcelApiProvider).estimate(_from!, _to!, _size);
      if (mounted) setState(() => _estimate = e);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
      }
    }
  }

  Future<void> _send() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null || _to == null || _from == _to) return;
    final phone = _phoneCtrl.text.trim();
    if (_nameCtrl.text.trim().isEmpty || phone.length != 9) {
      setState(() => _error = t.parcelRecipientRequired);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(parcelApiProvider).request(
            pickup: _from!,
            destination: _to!,
            size: _size,
            recipientName: _nameCtrl.text.trim(),
            recipientPhone: '+998$phone',
            note: _noteCtrl.text.trim(),
          );
      ref.invalidate(myParcelsProvider);
      if (!mounted) return;
      // Kuzatuv paneli avtomatik ochiladi — qo'shimcha xabar shart emas.
      setState(() {
        _step = 0;
        _estimate = null;
        _routeLine = const [];
        _to = null;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _noteCtrl.clear();
      });
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancel(String id) async {
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(parcelApiProvider).cancel(id);
      ref.invalidate(myParcelsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final parcels = ref.watch(myParcelsProvider).valueOrNull ??
        const <ParcelDelivery>[];
    final activeList = parcels.where((p) => p.isActive).toList();
    final active = activeList.isNotEmpty ? activeList.first : null;
    // Baholash (yetkazilgan, bahosiz) + faol dostavka kuzatuvini sozlash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRate(parcels);
      _syncTracking(active);
    });
    // Xarita asosiy (≈70%), kontent pastdagi panelda — taksi kabi.
    return Scaffold(
      appBar: AppBar(title: Text(t.parcelTitle)),
      body: Column(
        children: [
          Expanded(child: _buildMap()),
          active != null ? _trackingPanel(t, active) : _wizardPanel(t),
        ],
      ),
    );
  }

  /// Pastki panel — umumiy AppPanel (dasta + soya, taksi bilan bir xil uslub).
  Widget _panel({required Widget child}) {
    return AppPanel(safeArea: false, child: child);
  }

  Widget _wizardPanel(AppLocalizations t) {
    final h = MediaQuery.of(context).size.height;
    return _panel(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.52),
        child: _wizardView(t),
      ),
    );
  }

  Widget _trackingPanel(AppLocalizations t, ParcelDelivery active) {
    final h = MediaQuery.of(context).size.height;
    return _panel(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.5),
        child: _trackingView(t, active),
      ),
    );
  }

  // ---------------- Bosqichli buyurtma sehrgari ----------------

  bool get _stepOk {
    switch (_step) {
      case 0:
        return _from != null && _to != null && _from != _to;
      case 2:
        return _nameCtrl.text.trim().isNotEmpty &&
            _phoneCtrl.text.trim().length == 9;
      default:
        return true;
    }
  }

  String _stepTitle() => switch (_step) {
        0 => 'Manzilni tanlang',
        1 => 'Posilka hajmi',
        2 => 'Qabul qiluvchi',
        _ => 'Tasdiqlash',
      };

  Future<void> _nextStep() async {
    if (!_stepOk) return;
    if (_step == 0 || _step == 1) await _doEstimate();
    if (mounted) setState(() => _step = (_step + 1).clamp(0, 3));
  }

  Widget _wizardView(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kontent (kerak bo'lsa scroll bo'ladi)
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Bosqich indikatori
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? scheme.primary
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (i < 3) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text('Qadam ${_step + 1}/4 · ${_stepTitle()}',
                  style:
                      const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),
              ..._stepBody(t),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
              ],
            ),
          ),
        ),
        // Tugmalar — doim pastga mahkamlangan (ostida bo'sh joy qolmaydi)
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 10 + MediaQuery.of(context).padding.bottom),
          child: _stepNav(t),
        ),
      ],
    );
  }

  List<Widget> _stepBody(AppLocalizations t) {
    switch (_step) {
      case 0:
        return [
          RouteFields(
            fromLabel: _from?.label ?? t.taxiSelectFromHint,
            toLabel: _to?.label ?? t.taxiSelectToHint,
            fromFilled: _from != null,
            toFilled: _to != null,
            onFromTap: () => _pick(isFrom: true),
            onToTap: () => _pick(isFrom: false),
          ),
        ];
      case 1:
        return [
          Row(
            children: [
              _sizeCard(ParcelSize.small, Icons.inventory_2_outlined,
                  t.parcelSizeSmall, 'Hujjat, telefon'),
              const SizedBox(width: 10),
              _sizeCard(ParcelSize.medium, Icons.inventory_2,
                  t.parcelSizeMedium, 'Quti, sumka'),
              const SizedBox(width: 10),
              _sizeCard(ParcelSize.large, Icons.local_shipping_outlined,
                  t.parcelSizeLarge, 'Yirik jo\'natma'),
            ],
          ),
          const SizedBox(height: 10),
          Text('Yirikroq posilka biroz qimmatroq.',
              style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.outline)),
        ];
      case 2:
        return [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: t.parcelRecipientName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          _phoneField(t),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: t.parcelNote,
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
        ];
      default:
        return _reviewBody(t);
    }
  }

  /// Posilka hajmi kartasi — ikonka + nom + misol, tanlansa brend rangda.
  Widget _sizeCard(
      ParcelSize size, IconData icon, String label, String example) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _size == size;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          _size = size;
          _estimate = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.10)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            // Faqat tanlanganda yengil brend halqa; qolganlari chegarasiz.
            border: selected
                ? Border.all(color: scheme.primary, width: 1.6)
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 26,
                  color: selected ? scheme.primary : scheme.outline),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color:
                          selected ? scheme.primary : scheme.onSurface)),
              const SizedBox(height: 2),
              Text(example,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: scheme.outline)),
            ],
          ),
        ),
      ),
    );
  }

  /// +998 qatъiy old qo'shimchali telefon (9 raqam, o'chmaydi).
  Widget _phoneField(AppLocalizations t) {
    return TextField(
      controller: _phoneCtrl,
      keyboardType: TextInputType.number,
      maxLength: 9,
      onChanged: (v) {
        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits != v) {
          _phoneCtrl.value = TextEditingValue(
            text: digits,
            selection: TextSelection.collapsed(offset: digits.length),
          );
        }
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: t.parcelRecipientPhone,
        prefixText: '+998 ',
        prefixIcon: const Icon(Icons.phone_outlined),
        counterText: '',
      ),
    );
  }

  List<Widget> _reviewBody(AppLocalizations t) {
    return [
      _reviewRow(Icons.my_location, 'Qayerdan', _from?.label ?? '—',
          onEdit: () => setState(() => _step = 0)),
      _reviewRow(Icons.location_on, 'Qayerga', _to?.label ?? '—',
          onEdit: () => setState(() => _step = 0)),
      _reviewRow(Icons.inventory_2, 'Hajm', _sizeLabel(t),
          onEdit: () => setState(() => _step = 1)),
      _reviewRow(Icons.person, 'Qabul qiluvchi', _nameCtrl.text.trim(),
          onEdit: () => setState(() => _step = 2)),
      _reviewRow(Icons.phone, 'Telefon', '+998 ${_phoneCtrl.text.trim()}',
          onEdit: () => setState(() => _step = 2)),
      const SizedBox(height: 10),
      if (_estimate != null) _estimateCard(t, _estimate!),
    ];
  }

  String _sizeLabel(AppLocalizations t) => switch (_size) {
        ParcelSize.small => t.parcelSizeSmall,
        ParcelSize.medium => t.parcelSizeMedium,
        ParcelSize.large => t.parcelSizeLarge,
      };

  Widget _reviewRow(IconData icon, String label, String value,
      {VoidCallback? onEdit}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(label, style: TextStyle(color: scheme.outline)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (onEdit != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  Widget _stepNav(AppLocalizations t) {
    if (_step == 3) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sending ? null : () => setState(() => _step = 0),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              icon: const Icon(Icons.edit_outlined, size: 19),
              label: const Text('O‘zgartirish'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: BrandButton(
              label: 'Buyurtma berish',
              icon: Icons.local_shipping_rounded,
              loading: _sending,
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step -= 1),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56)),
              child: const Text('Orqaga'),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: BrandButton(
            label: 'Davom etish',
            icon: Icons.arrow_forward_rounded,
            onPressed: _stepOk ? _nextStep : null,
          ),
        ),
      ],
    );
  }

  // ---------------- Faol dostavka kuzatuvi ----------------

  Widget _trackingView(AppLocalizations t, ParcelDelivery active) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = _statusInfo(t, active.status);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.local_shipping_rounded,
                            size: 15, color: Color(0xFF1565C0)),
                        SizedBox(width: 5),
                        Text('Yetgazish',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: Color(0xFF1565C0))),
                      ]),
                    ),
                    const Spacer(),
                    Text(label,
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                if (active.hasDriver)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          active.driverName!.substring(0, 1).toUpperCase(),
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
                            Text('Kuryer: ${active.driverName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Color(0xFFF6A609)),
                              const SizedBox(width: 3),
                              Text(
                                  active.driverRatingCount > 0
                                      ? active.driverRating.toStringAsFixed(1)
                                      : 'Yangi',
                                  style: TextStyle(
                                      color: scheme.outline, fontSize: 12.5)),
                              if ((active.driverCar ?? '').isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('· ${active.driverCar}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: scheme.outline,
                                          fontSize: 12.5)),
                                ),
                              ],
                              if ((active.driverPlate ?? '').isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: const Color(0xFF1A237E),
                                        width: 1.4),
                                  ),
                                  child: Text(active.driverPlate!.toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5,
                                          letterSpacing: 0.8,
                                          color: Color(0xFF1A237E))),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      // Kuryer bilan suhbat (yuqorida qo'ng'iroq tugmasi ham bor)
                      IconButton.filledTonal(
                        tooltip: 'Suhbat',
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TaxiChatScreen(
                            tripId: active.id,
                            tripTitle: 'Dostavka #${active.publicNo}',
                            phone: active.driverPhone,
                            vertical: 'parcel',
                          ),
                        )),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                      ),
                    ],
                  )
                else
                  Row(children: [
                    const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Text('Kuryer qidirilmoqda…',
                        style: TextStyle(color: scheme.outline)),
                  ]),
                const SizedBox(height: 12),
                Text('${active.pickupText} → ${active.destinationText}',
                    style: TextStyle(color: scheme.outline)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Narx',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(t.priceSom(groupThousands(active.displayFare)),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                if (active.isCancellable) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelConfirm(active.id),
                      icon: Icon(Icons.close, size: 18, color: scheme.error),
                      label: Text(t.taxiCancel,
                          style: TextStyle(color: scheme.error)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Future<void> _cancelConfirm(String id) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.taxiCancel),
        content: const Text('Dostavkani bekor qilmoqchimisiz?'),
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
    if (ok == true) await _cancel(id);
  }

  Future<void> _maybeRate(List<ParcelDelivery> parcels) async {
    final done = parcels
        .where((p) => p.status == 'DELIVERED' && p.rating == null)
        .toList();
    if (done.isEmpty) return;
    final p = done.first;
    if (_ratedHandledId == p.id) return;
    _ratedHandledId = p.id;
    final stars = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _ParcelRatingSheet(no: p.publicNo),
    );
    if (stars == null) return;
    try {
      await ref.read(parcelApiProvider).rate(p.id, stars);
      ref.invalidate(myParcelsProvider);
    } catch (_) {}
    // Baholangach asosiy ekranga qaytamiz.
    if (mounted) Navigator.of(context).maybePop();
  }

  Widget _buildMap() {
    final overlays = <Widget>[];
    final tracking = _trackedId != null && _trackFrom != null && _trackTo != null;
    // Kuzatuvda — dostavka manzillari; aks holda sehrgardagi tanlov.
    final LatLng? aFrom = tracking
        ? _trackFrom
        : (_from != null ? LatLng(_from!.lat, _from!.lng) : null);
    final LatLng? aTo = tracking
        ? _trackTo
        : (_to != null ? LatLng(_to!.lat, _to!.lng) : null);
    final List<LatLng>? line = tracking
        ? (_trackRoute.isNotEmpty
            ? _trackRoute
            : (aFrom != null && aTo != null ? [aFrom, aTo] : null))
        : (_routeLine.isNotEmpty
            ? _routeLine
            : (aFrom != null && aTo != null ? [aFrom, aTo] : null));
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
    final markers = <Marker>[];
    // Jo'natuvchi (yashil doira) va qabul qiluvchi (qizil pin) — aniq farqli.
    if (aFrom != null) markers.add(pickupMarker(aFrom));
    if (aTo != null) markers.add(destMarker(aTo));
    // Jonli kuryer (kuzatuvda) — to'q sariq mashina belgisi.
    if (tracking && _driverLoc != null) {
      markers.add(Marker(
        point: _driverLoc!,
        width: 46,
        height: 46,
        child: _courierBadge(),
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

  Future<void> _recenter() async {
    final pos = await ref.read(locationServiceProvider).currentLatLng();
    if (!mounted || pos == null) return;
    _map.move(pos, 16);
    setState(() => _myLoc = pos);
  }

  /// Jonli kuryer belgisi (xaritada to'q sariq mashina).
  Widget _courierBadge() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFB8C00),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
        ),
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
      );

  /// Yakuniy narx kartasi — brend gradient, masofa chapda, narx o'ngda.
  Widget _estimateCard(AppLocalizations t, ParcelEstimate e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brand, AppTheme.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.taxiDistance,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text(t.taxiKm(e.distanceKm.toStringAsFixed(1)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          Container(width: 1, height: 34, color: Colors.white24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(t.taxiFare,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text(t.priceSom(groupThousands(e.fare)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }


  (String, Color) _statusInfo(AppLocalizations t, String status) {
    switch (status) {
      case 'ACCEPTED':
        return (t.parcelStatusAccepted, Colors.blue);
      case 'ARRIVED':
        return ('Kuryer yetib keldi', const Color(0xFF2E7D32));
      case 'PICKED_UP':
        return (t.parcelStatusPickedUp, Colors.orange);
      case 'IN_TRANSIT':
        return ('Yo‘lda', Colors.orange);
      case 'DELIVERED':
        return (t.parcelStatusDelivered, Colors.green);
      case 'CANCELLED':
        return (t.parcelStatusCancelled, Colors.red);
      default:
        return (t.parcelStatusPending, Colors.grey);
    }
  }
}

/// Dostavka yetkazilgach — xizmatni baholash (yulduzlar).
class _ParcelRatingSheet extends StatefulWidget {
  final int no;
  const _ParcelRatingSheet({required this.no});

  @override
  State<_ParcelRatingSheet> createState() => _ParcelRatingSheetState();
}

class _ParcelRatingSheetState extends State<_ParcelRatingSheet> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping_rounded,
              size: 40, color: Color(0xFF2E7D32)),
          const SizedBox(height: 8),
          Text('Dostavka #${widget.no} yetkazildi',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Xizmatni baholang',
              style: TextStyle(color: Colors.grey)),
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
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
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
