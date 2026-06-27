import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/alert_sound.dart';
import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../../widgets/language_button.dart';
import '../auth/auth_controller.dart';
import '../nav/driver_nav_screen.dart';
import '../parcel/parcel_api.dart';
import '../parcel/parcel_models.dart';
import '../taxi/taxi_api.dart';
import '../taxi/taxi_chat_screen.dart';
import '../taxi/taxi_models.dart';
import 'delivery_api.dart';
import 'delivery_models.dart';

/// Haydovchi bosh ekrani — onlayn holat + yetkazib berish doskasi.
class DeliveryBoardScreen extends ConsumerStatefulWidget {
  const DeliveryBoardScreen({super.key});

  @override
  ConsumerState<DeliveryBoardScreen> createState() => _DeliveryBoardScreenState();
}

class _DeliveryBoardScreenState extends ConsumerState<DeliveryBoardScreen> {
  String? _busy;
  Timer? _pollTimer;
  int _lastAvailable = 0;
  bool _silenced = false;

  @override
  void initState() {
    super.initState();
    // Onlayn bo'lsa, mavjud buyurtmalarni davriy yangilab turamiz (yangi
    // buyurtma kelganini bilish + ovozli signal uchun).
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !ref.read(onlineProvider)) return;
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(availableTaxiProvider);
      ref.invalidate(availableParcelsProvider);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(alertSoundProvider).stop();
    super.dispose();
  }

  /// Qabul bosilganda signalni jim qiladi (yangi buyurtma kelsa qayta yonadi).
  void _silenceAlert() {
    _silenced = true;
    ref.read(alertSoundProvider).stop();
  }

  /// Mavjud buyurtmalar soniga qarab signalni boshqaradi.
  void _updateAlert(int available, bool online) {
    final alert = ref.read(alertSoundProvider);
    if (!online || available == 0) {
      _silenced = false;
      _lastAvailable = available;
      if (alert.isPlaying) alert.stop();
      return;
    }
    if (available > _lastAvailable) {
      _silenced = false; // yangi buyurtma keldi — qayta jaranglaydi
    }
    _lastAvailable = available;
    if (_silenced) {
      if (alert.isPlaying) alert.stop();
    } else {
      if (!alert.isPlaying) alert.start();
    }
  }

  Future<void> _run(String orderId, Future<void> Function() action) async {
    setState(() => _busy = orderId);
    try {
      await action();
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(myDeliveriesProvider);
      ref.invalidate(earningsProvider);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final online = ref.watch(onlineProvider);

    // Uchala vertikaldagi mavjud (kutilayotgan) buyurtmalar soni — ovozli
    // signal uchun. Providerlarni shu yerda kuzatib turamiz (har doim faol).
    final available = (ref.watch(availableOrdersProvider).value?.length ?? 0) +
        (ref.watch(availableTaxiProvider).value?.length ?? 0) +
        (ref.watch(availableParcelsProvider).value?.length ?? 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAlert(available, online);
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.appName),
          actions: [
            Center(child: Text(online ? t.online : t.offline)),
            Switch(
              value: online,
              onChanged: (v) => ref.read(onlineProvider.notifier).state = v,
            ),
            const LanguageButton(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: t.logout,
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: t.deliveryTab, icon: const Icon(Icons.delivery_dining)),
              Tab(text: t.taxiTab, icon: const Icon(Icons.local_taxi)),
              Tab(text: t.parcelTab, icon: const Icon(Icons.local_shipping)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _deliveryTab(t, online),
            _taxiTab(t, online),
            _parcelTab(t, online),
          ],
        ),
      ),
    );
  }

  Widget _deliveryTab(AppLocalizations t, bool online) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(availableOrdersProvider);
        ref.invalidate(myDeliveriesProvider);
        ref.invalidate(earningsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildEarnings(t),
          const SizedBox(height: 16),
          _SectionTitle(t.myDeliveriesTitle),
          _buildMyDeliveries(t),
          const SizedBox(height: 16),
          _SectionTitle(t.availableTitle),
          if (online)
            _buildAvailable(t)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.offlineHint,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
        ],
      ),
    );
  }

  // ---------- Taksi tab ----------

  Widget _taxiTab(AppLocalizations t, bool online) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(availableTaxiProvider);
        ref.invalidate(myTaxiTripsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionTitle(t.taxiMyTripsTitle),
          _buildMyTaxiTrips(t),
          const SizedBox(height: 16),
          _SectionTitle(t.taxiAvailableTitle),
          if (online)
            _buildAvailableTaxi(t)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.offlineHint,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
        ],
      ),
    );
  }

  Future<void> _runTaxi(String id, Future<void> Function() action) async {
    setState(() => _busy = id);
    try {
      await action();
      ref.invalidate(availableTaxiProvider);
      ref.invalidate(myTaxiTripsProvider);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _buildMyTaxiTrips(AppLocalizations t) {
    final async = ref.watch(myTaxiTripsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myTaxiTripsProvider),
      ),
      data: (trips) {
        final active = trips
            .where((tr) => tr.status == 'ACCEPTED' || tr.status == 'IN_PROGRESS')
            .toList();
        if (active.isEmpty) return _emptyHint(t.taxiNoActive);
        return Column(children: active.map((tr) => _taxiActiveCard(t, tr)).toList());
      },
    );
  }

  Widget _buildAvailableTaxi(AppLocalizations t) {
    final async = ref.watch(availableTaxiProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(availableTaxiProvider),
      ),
      data: (trips) {
        if (trips.isEmpty) return _emptyHint(t.taxiNoAvailable);
        return Column(children: trips.map((tr) => _taxiAvailableCard(t, tr)).toList());
      },
    );
  }

  Widget _taxiRoute(AppLocalizations t, TaxiTrip tr) {
    final hasDest = tr.destinationText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.taxiTripNo(tr.publicNo.toString()),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(hasDest
            ? '${tr.pickupText} → ${tr.destinationText}'
            : '${tr.pickupText} → ${t.taxiMeteredBadge}'),
        if (tr.fare > 0) ...[
          Text('${t.taxiKm(tr.distanceKm.toStringAsFixed(1))} · '
              '${t.priceSom(groupThousands(tr.fare))}'),
          Text(
              '${t.yourEarning}: ${t.priceSom(groupThousands(tr.driverEarning))}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              )),
        ] else
          Text(t.taxiMeteredFareHint,
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }

  Widget _taxiAvailableCard(AppLocalizations t, TaxiTrip tr) {
    final busy = _busy == tr.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _taxiRoute(t, tr),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      _silenceAlert();
                      _runTaxi(tr.id, () => ref.read(taxiApiProvider).accept(tr.id));
                    },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: busy ? const _Spinner() : Text(t.accept),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taxiActiveCard(AppLocalizations t, TaxiTrip tr) {
    final busy = _busy == tr.id;
    final isAccepted = tr.status == 'ACCEPTED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _taxiRoute(t, tr)),
                Text(
                  isAccepted ? t.taxiStatusAccepted : t.taxiStatusInProgress,
                  style: TextStyle(
                    color: isAccepted ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tr.pickupLat != null) ...[
              OutlinedButton.icon(
                onPressed: () => _openTaxiNav(tr),
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Navigatsiya (xarita)'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openTaxiChat(t, tr),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(t.chatTitle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () {
                            if (isAccepted) {
                              _runTaxi(tr.id,
                                  () => ref.read(taxiApiProvider).start(tr.id));
                            } else {
                              _completeTaxi(tr);
                            }
                          },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: isAccepted ? null : Colors.green,
                    ),
                    child: busy
                        ? const _Spinner()
                        : Text(isAccepted ? t.taxiStart : t.taxiComplete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openTaxiChat(AppLocalizations t, TaxiTrip tr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaxiChatScreen(
          tripId: tr.id,
          tripTitle: t.taxiTripNo(tr.publicNo.toString()),
        ),
      ),
    );
  }

  void _openTaxiNav(TaxiTrip tr) {
    final pickup = (tr.pickupLat != null && tr.pickupLng != null)
        ? LatLng(tr.pickupLat!, tr.pickupLng!)
        : null;
    final dest = (tr.destLat != null && tr.destLng != null)
        ? LatLng(tr.destLat!, tr.destLng!)
        : null;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DriverNavScreen(
        title: 'Navigatsiya',
        routeText: tr.destinationText.isNotEmpty
            ? '${tr.pickupText} → ${tr.destinationText}'
            : tr.pickupText,
        pickup: pickup,
        destination: dest,
        toDestination: tr.status == 'IN_PROGRESS' && dest != null,
      ),
    ));
  }

  void _openParcelNav(ParcelDelivery p) {
    final pickup = (p.pickupLat != null && p.pickupLng != null)
        ? LatLng(p.pickupLat!, p.pickupLng!)
        : null;
    final dest = (p.destLat != null && p.destLng != null)
        ? LatLng(p.destLat!, p.destLng!)
        : null;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DriverNavScreen(
        title: 'Navigatsiya',
        routeText: '${p.pickupText} → ${p.destinationText}',
        pickup: pickup,
        destination: dest,
        toDestination: p.status == 'PICKED_UP' && dest != null,
        phone: p.recipientPhone,
      ),
    ));
  }

  /// Yakunlash dialogi — metered safarga masofa, hammasiga kutish daqiqasi.
  Future<void> _completeTaxi(TaxiTrip tr) async {
    final t = AppLocalizations.of(context)!;
    final distCtrl = TextEditingController(
        text: tr.distanceKm > 0 ? tr.distanceKm.toStringAsFixed(1) : '');
    final waitCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.taxiCompleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tr.metered) ...[
              TextField(
                controller: distCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: t.taxiDistanceKm,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: waitCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.taxiWaitMinutes,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.taxiComplete),
          ),
        ],
      ),
    );
    final distanceKm = tr.metered
        ? double.tryParse(distCtrl.text.trim().replaceAll(',', '.'))
        : null;
    final waitMinutes = int.tryParse(waitCtrl.text.trim());
    distCtrl.dispose();
    waitCtrl.dispose();
    if (confirmed != true) return;
    await _runTaxi(
      tr.id,
      () => ref
          .read(taxiApiProvider)
          .complete(tr.id, distanceKm: distanceKm, waitMinutes: waitMinutes),
    );
  }

  // ---------- Dostavka tab ----------

  Widget _parcelTab(AppLocalizations t, bool online) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(availableParcelsProvider);
        ref.invalidate(myParcelDeliveriesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionTitle(t.parcelMyTitle),
          _buildMyParcels(t),
          const SizedBox(height: 16),
          _SectionTitle(t.parcelAvailableTitle),
          if (online)
            _buildAvailableParcels(t)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.offlineHint,
                  style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
        ],
      ),
    );
  }

  Future<void> _runParcel(String id, Future<void> Function() action) async {
    setState(() => _busy = id);
    try {
      await action();
      ref.invalidate(availableParcelsProvider);
      ref.invalidate(myParcelDeliveriesProvider);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _buildMyParcels(AppLocalizations t) {
    final async = ref.watch(myParcelDeliveriesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myParcelDeliveriesProvider),
      ),
      data: (parcels) {
        final active = parcels
            .where((p) => p.status == 'ACCEPTED' || p.status == 'PICKED_UP')
            .toList();
        if (active.isEmpty) return _emptyHint(t.parcelNoActive);
        return Column(children: active.map((p) => _parcelActiveCard(t, p)).toList());
      },
    );
  }

  Widget _buildAvailableParcels(AppLocalizations t) {
    final async = ref.watch(availableParcelsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(availableParcelsProvider),
      ),
      data: (parcels) {
        if (parcels.isEmpty) return _emptyHint(t.parcelNoAvailable);
        return Column(
            children: parcels.map((p) => _parcelAvailableCard(t, p)).toList());
      },
    );
  }

  Widget _parcelInfo(AppLocalizations t, ParcelDelivery p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.parcelNo(p.publicNo.toString()),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${p.pickupText} → ${p.destinationText}'),
        Text('${p.recipientName} · ${p.recipientPhone}'),
        Text('${t.taxiKm(p.distanceKm.toStringAsFixed(1))} · '
            '${t.priceSom(groupThousands(p.fare))}'),
        Text('${t.yourEarning}: ${t.priceSom(groupThousands(p.driverEarning))}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }

  Widget _parcelAvailableCard(AppLocalizations t, ParcelDelivery p) {
    final busy = _busy == p.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _parcelInfo(t, p),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      _silenceAlert();
                      _runParcel(p.id, () => ref.read(parcelApiProvider).accept(p.id));
                    },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: busy ? const _Spinner() : Text(t.accept),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parcelActiveCard(AppLocalizations t, ParcelDelivery p) {
    final busy = _busy == p.id;
    final isAccepted = p.status == 'ACCEPTED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _parcelInfo(t, p)),
                Text(
                  isAccepted ? t.taxiStatusAccepted : t.parcelStatusPickedUp,
                  style: TextStyle(
                    color: isAccepted ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (p.pickupLat != null) ...[
              OutlinedButton.icon(
                onPressed: () => _openParcelNav(p),
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Navigatsiya (xarita)'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: busy
                  ? null
                  : () => _runParcel(
                        p.id,
                        () => isAccepted
                            ? ref.read(parcelApiProvider).pickup(p.id)
                            : ref.read(parcelApiProvider).delivered(p.id),
                      ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: isAccepted ? null : Colors.green,
              ),
              child: busy
                  ? const _Spinner()
                  : Text(isAccepted ? t.markPicked : t.markDelivered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnings(AppLocalizations t) {
    final async = ref.watch(earningsProvider);
    return async.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(earningsProvider),
      ),
      data: (e) {
        final scheme = Theme.of(context).colorScheme;
        return Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: scheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      t.earningsTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _earnStat(
                        t.earningsToday,
                        t.priceSom(groupThousands(e.total.todayEarning)),
                        t.deliveriesCount(e.total.count),
                      ),
                    ),
                    Expanded(
                      child: _earnStat(
                        t.earningsTotal,
                        t.priceSom(groupThousands(e.total.earning)),
                        t.deliveriesCount(e.total.count),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                // Vertikal bo'yicha taqsimot (jami daromad)
                _earnBreak(t.deliveryTab, e.food),
                const SizedBox(height: 4),
                _earnBreak(t.taxiTab, e.taxi),
                const SizedBox(height: 4),
                _earnBreak(t.parcelTab, e.parcel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _earnBreak(String label, EarningsPart part) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label · ${t.deliveriesCount(part.count)}',
            style: TextStyle(color: scheme.onPrimaryContainer)),
        Text(t.priceSom(groupThousands(part.earning)),
            style: TextStyle(
                color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _earnStat(String label, String value, String sub) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: scheme.onPrimaryContainer)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(sub,
            style: TextStyle(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontSize: 12)),
      ],
    );
  }

  Widget _buildMyDeliveries(AppLocalizations t) {
    final async = ref.watch(myDeliveriesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myDeliveriesProvider),
      ),
      data: (orders) {
        final active = orders
            .where((o) => o.status == 'ASSIGNED' || o.status == 'PICKED_UP')
            .toList();
        if (active.isEmpty) {
          return _emptyHint(t.noDeliveries);
        }
        return Column(children: active.map((o) => _activeCard(t, o)).toList());
      },
    );
  }

  Widget _buildAvailable(AppLocalizations t) {
    final async = ref.watch(availableOrdersProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(availableOrdersProvider),
      ),
      data: (orders) {
        if (orders.isEmpty) return _emptyHint(t.noAvailable);
        return Column(children: orders.map((o) => _availableCard(t, o)).toList());
      },
    );
  }

  Widget _availableCard(AppLocalizations t, DeliveryOrder o) {
    final busy = _busy == o.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(t, o),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      _silenceAlert();
                      _run(o.id, () => ref.read(deliveryApiProvider).accept(o.id));
                    },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: busy ? const _Spinner() : Text(t.accept),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeCard(AppLocalizations t, DeliveryOrder o) {
    final busy = _busy == o.id;
    final isAssigned = o.status == 'ASSIGNED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.orderNo(o.publicNo.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isAssigned ? t.statusAssigned : t.statusPickedUp,
                  style: TextStyle(
                    color: isAssigned ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${t.deliverTo}: ${o.addressText}'),
            Text(t.priceSom(groupThousands(o.total))),
            _earningChip(t, o),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => _run(
                        o.id,
                        () => isAssigned
                            ? ref.read(deliveryApiProvider).pickup(o.id)
                            : ref.read(deliveryApiProvider).delivered(o.id),
                      ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: isAssigned ? null : Colors.green,
              ),
              child: busy
                  ? const _Spinner()
                  : Text(isAssigned ? t.markPicked : t.markDelivered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(AppLocalizations t, DeliveryOrder o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.orderNo(o.publicNo.toString()),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${t.deliverTo}: ${o.addressText}'),
        Text(t.priceSom(groupThousands(o.total))),
        _earningChip(t, o),
      ],
    );
  }

  Widget _earningChip(AppLocalizations t, DeliveryOrder o) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${t.yourEarning}: ${t.priceSom(groupThousands(o.courierEarning))}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
