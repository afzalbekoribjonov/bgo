import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/alert_sound.dart';
import '../../core/driver_geo.dart';
import '../../core/nav_support.dart';
import '../../core/online_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/driver_colors.dart';
import '../../widgets/car_marker.dart';
import '../../widgets/slide_to_confirm.dart';
import '../auth/auth_api.dart';
import '../auth/driver_profile.dart';
import '../delivery/delivery_api.dart';
import '../messages/messages_api.dart';
import '../messages/messages_screen.dart';
import '../orders/cancel_reason_screen.dart';
import '../orders/offer_api.dart';
import '../orders/pool_screen.dart';
import '../orders/trip_api.dart';
import '../orders/trip_chat_screen.dart';
import '../profile/driver_profile_screen.dart';
import '../stats/today_screen.dart';
import 'balance_screen.dart';
import 'driver_blocked_screen.dart';
import 'home_address_picker_screen.dart';

const _gold = DriverColors.gold;
const _offlineNav = DriverColors.offlineNav;

/// Haydovchi bosh ekrani — xarita + navigator + tortiluvchi panel +
/// yangi buyurtma (taklif) oqimi. plan/06-driver-app.md
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final MapController _map = MapController();
  bool _panelHidden = false; // xarita bosilganda panel pastga yashirinadi
  DriverFix? _fix;
  double _zoom = 16;
  Timer? _gpsTimer;

  // O'z mashinasi belgisining silliq harakati — GPS ping'lari orasida
  // (har 3s) sakramasdan, doim yo'l bo'ylab suzib boruvchi ko'rinish uchun.
  // GPS ba'zan bir necha metr chayqalsa ham, belgi tekis harakat qiladi.
  late final AnimationController _posAnimCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..addListener(_onPosAnimTick);
  LatLng? _animFrom;
  LatLng? _animTo;
  LatLng? _animPos;

  void _onPosAnimTick() {
    final from = _animFrom;
    final to = _animTo;
    if (from == null || to == null) return;
    final v = Curves.easeInOut.transform(_posAnimCtrl.value);
    setState(() => _animPos = LatLng(
          from.latitude + (to.latitude - from.latitude) * v,
          from.longitude + (to.longitude - from.longitude) * v,
        ));
  }
  Timer? _offerTimer;
  Timer? _tick;
  Timer? _msgTimer;

  // Buyurtma taklifi
  DriverOffer? _offer;
  int _offerLeft = 0;
  List<LatLng> _route = const [];
  // Ikkinchi segment (ovqat: oshxona -> mijoz, ko'k) — to'liq yo'l ko'rinadi.
  List<LatLng> _route2 = const [];
  bool _showNotTaken = false;
  bool _accepting = false;

  // Faol safar (qabuldan keyingi oqim — taksi)
  DriverTrip? _activeTrip;
  Timer? _tripTimer;
  bool _tripBusy = false;
  // Amal muvaffaqiyatsiz tugasa oshadi — slayder kalitiga kiritiladi, shunda
  // status o'zgarmagan bo'lsa ham slayder qayta yasaladi va "tasdiqlandi"
  // holatida tiqilib qolmaydi (aks holda keyingi urinish uchun tortib
  // bo'lmay qoladi).
  int _actionFailCount = 0;

  // Suhbat badge'i: suhbatdoshdan kelgan xabarlar soni vs ko'rilgani.
  Timer? _chatTimer;
  int _chatOther = 0;
  int _chatSeen = 0;

  // Ketma-ket poll (taklif/safar) muvaffaqiyatsizliklari — uzoq davom etsa
  // (miltillashning oldini olish uchun bitta xatoda emas) "qayta
  // ulanmoqda" indikatori ko'rsatiladi.
  int _pollFailStreak = 0;
  static const _reconnectThreshold = 3;

  // "Uyga" rejimi — tugma bosilganda server chaqiruvi tugaguncha kichik
  // spinner ko'rsatiladi (haqiqiy holat har doim driverProfileProvider'dan).
  bool _homeModeBusy = false;

  @override
  void initState() {
    super.initState();
    _initOnline();
    _resumeActiveTrip();
    _refreshGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshGps());
    _offerTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _pollOffer());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_offer != null) {
        setState(() => _offerLeft = (_offerLeft - 1).clamp(0, 60));
      } else if (_activeTrip != null) {
        // Jonli kutish taymeri / narxni har soniya yangilab turamiz.
        setState(() {});
      }
    });
    // Xabarlar badge'i — har 20 soniyada yangilanadi.
    _msgTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.invalidate(unreadMessagesProvider);
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _offerTimer?.cancel();
    _tripTimer?.cancel();
    _tick?.cancel();
    _msgTimer?.cancel();
    _chatTimer?.cancel();
    _posAnimCtrl.dispose();
    ref.read(alertSoundProvider).stop();
    _map.dispose();
    super.dispose();
  }

  Future<void> _initOnline() async {
    // Ilova qayta ochilganda AVTOMATIK liniyaga chiqilmaydi — «Liniyaga chiqish»
    // tugmasi bosilishi kerak. Shu sabab oflayn boshlanadi + fon servisi to'xtaydi.
    if (mounted) ref.read(onlineProvider.notifier).state = false;
    OnlineService.stop();
    try {
      await ref.read(authApiProvider).setOnline(false);
    } catch (_) {}
  }

  Future<void> _refreshGps() async {
    final fix = await driverCurrentFix();
    if (!mounted || fix == null) return;
    final prevAnim = _animPos ?? _fix?.pos ?? fix.pos;
    setState(() {
      _fix = fix;
      _animFrom = prevAnim;
      _animTo = fix.pos;
    });
    _posAnimCtrl.forward(from: 0);
    _map.move(fix.pos, _zoom < 11 ? 16 : _zoom);
  }

  // ---------------- Taklif oqimi ----------------

  Future<void> _pollOffer() async {
    // Faol safar paytida yangi taklif so'ralmaydi.
    if (!mounted || _activeTrip != null || !ref.read(onlineProvider) || _accepting) {
      return;
    }
    try {
      final offer = await ref.read(offerApiProvider).current();
      if (!mounted) return;
      if (_pollFailStreak != 0) setState(() => _pollFailStreak = 0);
      if (offer != null) {
        final isNew = _offer?.orderId != offer.orderId;
        setState(() {
          _offer = offer;
          _offerLeft = offer.secondsLeft;
        });
        if (isNew) {
          _alertOn();
          _loadRoute(offer);
        }
      } else if (_offer != null) {
        // Taklif yo'qoldi (qabul qilinmadi / boshqaga o'tdi)
        _clearOffer(notTaken: true);
      }
      ref.invalidate(poolProvider);
    } catch (_) {
      if (mounted) setState(() => _pollFailStreak++);
    }
  }

  void _alertOn() {
    if (ref.read(soundEnabledProvider)) ref.read(alertSoundProvider).start();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
  }

  Future<void> _loadRoute(DriverOffer offer) async {
    final me = _fix?.pos;
    if (me == null) return;
    final dir =
        await ref.read(driverRoutingServiceProvider).directions(me, offer.pickup);
    if (!mounted || _offer?.orderId != offer.orderId) return;
    setState(() => _route = dir?.points ?? [me, offer.pickup]);
  }

  void _clearOffer({bool notTaken = false}) {
    ref.read(alertSoundProvider).stop();
    setState(() {
      _offer = null;
      _route = const [];
      _offerLeft = 0;
    });
    if (notTaken) {
      setState(() => _showNotTaken = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showNotTaken = false);
      });
    }
  }

  Future<void> _skipOffer() async {
    final o = _offer;
    if (o == null) return;
    _clearOffer();
    try {
      await ref.read(offerApiProvider).skip(o.orderId);
    } catch (_) {}
  }

  Future<void> _acceptOffer() async {
    final o = _offer;
    if (o == null || _accepting) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _accepting = true);
    ref.read(alertSoundProvider).stop();
    try {
      await ref.read(offerApiProvider).accept(o.orderId);
      if (!mounted) return;
      setState(() {
        _offer = null;
        _route = const [];
      });
      // Barcha vertikallarda (taksi/dostavka/OVQAT) — faol-ish oynasi majburiy.
      await _enterTrip(o.vertical, o.orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Tarmoq xatosi' : t.homeOrderGone)),
        );
        _clearOffer();
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  // ---------------- Faol ish (taksi / dostavka) ----------------

  /// Ilova qayta ochilganda davom etayotgan faol ishni (taksi yoki dostavka)
  /// tiklaydi — majburiy ochiladi.
  Future<void> _resumeActiveTrip() async {
    try {
      final t = await ref.read(tripApiProvider).activeJob();
      if (t != null && mounted && _activeTrip == null) {
        _enterTrip(t.vertical, t.id);
      }
    } catch (_) {/* tarmoq — keyin */}
  }

  Future<void> _enterTrip(String vertical, String id) async {
    try {
      final trip = await ref.read(tripApiProvider).get(vertical, id);
      if (!mounted) return;
      setState(() {
        _activeTrip = trip;
        _offer = null;
        _route = const [];
      });
      _loadTripRoute(trip);
      _tripTimer?.cancel();
      _tripTimer =
          Timer.periodic(const Duration(seconds: 3), (_) => _pollTrip());
      // Suhbat badge'i — suhbatdosh yozsa qo'ng'iroqcha ostidagi tugmada
      // qizil son ko'rinadi (haydovchi xabarni o'tkazib yubormaydi).
      _chatOther = 0;
      _chatSeen = 0;
      _chatTimer?.cancel();
      _chatTimer =
          Timer.periodic(const Duration(seconds: 6), (_) => _pollChat());
    } catch (_) {/* keyingi urinishda */}
  }

  /// Faol ish suhbatidagi suhbatdosh xabarlari sonini oladi (badge uchun).
  Future<void> _pollChat() async {
    final t = _activeTrip;
    if (!mounted || t == null) return;
    final base = t.isFood
        ? '/courier/orders/${t.id}/messages'
        : '/${t.vertical}/${t.id}/messages';
    try {
      final res = await ref.read(dioProvider).get(base);
      final list = (res.data['data'] as List?) ?? const [];
      final other = list
          .where((e) =>
              ((e as Map<String, dynamic>)['senderRole'] as String?) !=
              'driver')
          .length;
      if (mounted && other != _chatOther) {
        setState(() => _chatOther = other);
      }
    } catch (_) {/* tarmoq — keyingi urinishda */}
  }

  Future<void> _pollTrip() async {
    final t = _activeTrip;
    if (!mounted || t == null) return;
    try {
      final trip = await ref.read(tripApiProvider).get(t.vertical, t.id);
      if (!mounted) return;
      if (_pollFailStreak != 0) setState(() => _pollFailStreak = 0);
      if (trip.status == 'CANCELLED' || trip.status == 'FAILED') {
        _exitTrip();
        final loc = AppLocalizations.of(context)!;
        _toast(loc.homeOrderCancelled);
        return;
      }
      final changedTarget = trip.status != t.status;
      setState(() => _activeTrip = trip);
      if (changedTarget) _loadTripRoute(trip);
    } catch (_) {
      if (mounted) setState(() => _pollFailStreak++);
    }
  }

  /// Marshrut: olib ketishga yo'lda -> pickup; manzilga yo'lda -> dropoff.
  /// Ovqatda olishdan oldin IKKI segment: men->oshxona (yashil) +
  /// oshxona->mijoz (ko'k) — haydovchi to'liq yo'lni oldindan ko'radi.
  Future<void> _loadTripRoute(DriverTrip trip) async {
    final me = _fix?.pos;
    final routing = ref.read(driverRoutingServiceProvider);
    final target =
        trip.goingToDropoff ? (trip.dropoff ?? trip.pickup) : trip.pickup;
    if (me == null) {
      setState(() => _route = [target]);
      return;
    }
    final dir = await routing.directions(me, target);
    if (!mounted || _activeTrip?.id != trip.id) return;
    setState(() => _route = dir?.points ?? [me, target]);
    // Ovqat, hali olinmagan: oshxona -> mijoz segmentini ham chizamiz.
    if (trip.isFood && !trip.goingToDropoff && trip.dropoff != null) {
      final dir2 = await routing.directions(trip.pickup, trip.dropoff!);
      if (!mounted || _activeTrip?.id != trip.id) return;
      setState(() => _route2 = dir2?.points ?? [trip.pickup, trip.dropoff!]);
    } else if (_route2.isNotEmpty) {
      setState(() => _route2 = const []);
    }
  }

  void _exitTrip() {
    _tripTimer?.cancel();
    _chatTimer?.cancel();
    _chatOther = 0;
    _chatSeen = 0;
    if (!mounted) return;
    // Hisobim (balans, komissiya yechilgach) va Bugun (bajarilgan soni) yangilanadi.
    ref.invalidate(driverProfileProvider);
    ref.invalidate(earningsProvider);
    setState(() {
      _activeTrip = null;
      _route = const [];
      _route2 = const [];
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Telefon ilovasini ochadi (qabul qiluvchi/mijoz raqamiga qo'ng'iroq).
  Future<void> _callPhone(String? phone) async {
    final t = AppLocalizations.of(context)!;
    final p = (phone ?? '').trim();
    if (p.isEmpty) {
      _toast(t.homeNoPhone);
      return;
    }
    try {
      await launchUrl(Uri(scheme: 'tel', path: p));
    } catch (_) {
      _toast(t.homeDialerFailed);
    }
  }

  /// Safar amalini bajaradi (arrive/start/wait/complete) + holatni yangilaydi.
  Future<void> _tripAction(Future<DriverTrip> Function() action) async {
    if (_tripBusy) return;
    final t = AppLocalizations.of(context)!;
    setState(() => _tripBusy = true);
    HapticFeedback.mediumImpact();
    try {
      final trip = await action();
      if (!mounted) return;
      final changed = trip.status != _activeTrip?.status;
      setState(() => _activeTrip = trip);
      if (changed) _loadTripRoute(trip);
    } catch (e) {
      if (mounted) setState(() => _actionFailCount++);
      _toast(isNetworkError(e) ? 'Tarmoq xatosi' : t.homeActionFailed);
    } finally {
      if (mounted) setState(() => _tripBusy = false);
    }
  }

  Future<void> _cancelTripConfirm() async {
    if (_tripBusy) return;
    final t = _activeTrip;
    if (t == null) return;
    final loc = AppLocalizations.of(context)!;
    final result = await Navigator.push<CancelReasonResult>(
      context,
      MaterialPageRoute(builder: (_) => CancelReasonScreen(isFood: t.isFood)),
    );
    if (!mounted || result == null) return;
    // Safar shu orada (dialog ochiq turganda) allaqachon yakunlangan/bekor
    // qilingan bo'lishi mumkin (poll orqali) — bunda qayta bekor qilib
    // o'tirmaymiz.
    if (_activeTrip?.id != t.id) return;
    setState(() => _tripBusy = true);
    try {
      await ref.read(tripApiProvider).cancel(
            t.vertical,
            t.id,
            reason: result.reason,
            note: result.note,
          );
    } catch (_) {
      // best-effort — server holatni pollda o'zi to'g'rilaydi
    } finally {
      if (mounted) setState(() => _tripBusy = false);
    }
    if (!mounted) return;
    _exitTrip();
    _toast(t.isFood
        ? loc.homeCancelledOfferedToOther
        : loc.homeOrderCancelled);
  }

  // ---------------- Online ----------------

  Future<void> _setOnline(bool value) async {
    if (value) {
      // GPS'siz onlayn bo'lish — haydovchi tizimga ko'rinmas/topilmas bo'lib
      // qoladi (jim, aniqlanmaydigan xato). Kesh eskirgan bo'lishi mumkin —
      // avval yangi o'qish urinamiz, faqat haqiqatan topilmasa bloklaymiz.
      var fix = _fix;
      fix ??= await driverCurrentFix();
      if (fix == null) {
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.homeGpsRequired)),
        );
        return;
      }
      if (!mounted) return;
      if (_fix == null) setState(() => _fix = fix);
    }
    ref.read(onlineProvider.notifier).state = value;
    if (value) {
      // Fonda online turish: GPS'ni muntazam yuboruvchi foreground service.
      OnlineService.start();
    } else {
      ref.read(alertSoundProvider).stop();
      _clearOffer();
      OnlineService.stop();
      _pollFailStreak = 0;
    }
    HapticFeedback.mediumImpact();
    try {
      await ref.read(authApiProvider).setOnline(value);
    } catch (e) {
      if (!mounted) return;
      // Server liniyaga chiqishni rad etdi (balans 0 yoki bloklangan) — oflayn holatga qaytaramiz.
      final t = AppLocalizations.of(context)!;
      if (value) {
        ref.read(onlineProvider.notifier).state = false;
        OnlineService.stop();
      }
      if (value && errorCode(e) == 'DRIVER_BLOCKED') {
        final data = errorData(e)!;
        final blockedUntilRaw = data['blockedUntil'] as String?;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverBlockedScreen(
              reason: data['reason'] as String?,
              blockedUntil:
                  blockedUntilRaw != null ? DateTime.tryParse(blockedUntilRaw) : null,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNetworkError(e)
              ? 'Tarmoq xatosi'
              : (value ? t.homeZeroBalance : t.homeGenericError)),
        ),
      );
    }
  }

  void _onMoonTap(bool online) {
    // Slider endi doim panelda turadi — oy bosilsa panelni ochib beramiz.
    setState(() => _panelHidden = false);
  }

  // ---------------- "Uyga" rejimi ----------------

  /// Uy tugmasi bosilganda: manzil hali yo'q bo'lsa — avval tanlash ekrani
  /// (rejim manzilsiz yoqilolmaydi, bu ikkinchi himoya qatlami — server ham
  /// tekshiradi). Manzil bor bo'lsa — rejimni yoqadi/o'chiradi.
  Future<void> _onHomeModeTap(DriverProfile? profile) async {
    if (_homeModeBusy) return;
    final t = AppLocalizations.of(context)!;
    if (profile == null) return;
    if (!profile.hasHomeAddress) {
      final picked = await Navigator.of(context).push<PickedHome>(
        MaterialPageRoute(builder: (_) => const HomeAddressPickerScreen()),
      );
      if (picked == null || !mounted) return;
      setState(() => _homeModeBusy = true);
      try {
        await ref.read(authApiProvider).setHome(picked.lat, picked.lng, picked.address);
        ref.invalidate(driverProfileProvider);
      } catch (e) {
        if (mounted) {
          _toast(isNetworkError(e) ? 'Tarmoq xatosi' : t.homeModeToggleFailed);
        }
      } finally {
        if (mounted) setState(() => _homeModeBusy = false);
      }
      return;
    }
    setState(() => _homeModeBusy = true);
    try {
      await ref.read(authApiProvider).setHomeModeActive(!profile.isHomeModeActive);
      ref.invalidate(driverProfileProvider);
    } catch (e) {
      if (mounted) {
        _toast(isNetworkError(e) ? 'Tarmoq xatosi' : t.homeModeToggleFailed);
      }
    } finally {
      if (mounted) setState(() => _homeModeBusy = false);
    }
  }

  /// Uy manzilini o'zgartirish (allaqachon belgilangan bo'lsa) — panel
  /// ichidagi tahrirlash ikonkasi bosilganda ham shu chaqiriladi.
  Future<void> _editHomeAddress(DriverProfile? profile) async {
    if (_homeModeBusy) return;
    final t = AppLocalizations.of(context)!;
    final picked = await Navigator.of(context).push<PickedHome>(
      MaterialPageRoute(
        builder: (_) => HomeAddressPickerScreen(
          initialLat: profile?.homeLat,
          initialLng: profile?.homeLng,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _homeModeBusy = true);
    try {
      await ref.read(authApiProvider).setHome(picked.lat, picked.lng, picked.address);
      ref.invalidate(driverProfileProvider);
    } catch (e) {
      if (mounted) {
        _toast(isNetworkError(e) ? 'Tarmoq xatosi' : t.homeModeToggleFailed);
      }
    } finally {
      if (mounted) setState(() => _homeModeBusy = false);
    }
  }

  Widget _homeModeButton(DriverProfile? profile) {
    final active = profile?.isHomeModeActive ?? false;
    return GestureDetector(
      onTap: () => _onHomeModeTap(profile),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: active ? _gold : Colors.transparent, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Center(
          child: _homeModeBusy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.home_rounded,
                  color: active ? _gold : Colors.grey.shade500, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final online = ref.watch(onlineProvider);
    final top = MediaQuery.of(context).padding.top;
    final hasTrip = _activeTrip != null;
    final hasOffer = _offer != null && !hasTrip;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _mapWidget(online)),
          // Indikatorlar
          Positioned(
            top: top + (hasOffer ? 74 : 10),
            left: 16,
            child: _StatusMoon(online: online, onTap: () => _onMoonTap(online)),
          ),
          Positioned(
            top: top + (hasOffer ? 142 : 84),
            left: 18,
            child: _SpeedBadge(_fix?.speedKmh ?? 0),
          ),
          Positioned(
            top: top + (hasOffer ? 204 : 146),
            left: 20,
            child: _homeModeButton(ref.watch(driverProfileProvider).valueOrNull),
          ),
          Positioned(top: top + 10, right: 16, child: _avatar()),
          Positioned(top: top + 72, right: 20, child: _poolBadge()),
          // Xabarlar (qo'ng'iroqcha) — admin e'lonlari, o'qilmagan soni bilan
          Positioned(top: top + 134, right: 20, child: _bellButton()),
          // Suhbat tugmasi — faol safar/dostavkada, qo'ng'iroqcha ostida
          if (hasTrip)
            Positioned(top: top + 196, right: 20, child: _chatButton(t)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            right: 18,
            bottom: hasTrip ? 270 : (hasOffer ? 200 : (_panelHidden ? 26 : 208)),
            child: _recenter(),
          ),
          // Yangi buyurtma banneri (yuqorida)
          if (hasOffer)
            Positioned(top: 0, left: 0, right: 0, child: _orderBanner(top, t)),
          // Uzoq davom etgan tarmoq uzilishi — bitta xatoda emas, faqat
          // ketma-ket bir necha muvaffaqiyatsizlikdan keyin (miltillamasin).
          if (!hasOffer &&
              (online || hasTrip) &&
              _pollFailStreak >= _reconnectThreshold)
            Positioned(
              top: top + 10,
              left: 0,
              right: 0,
              child: Center(child: _reconnectingPill(t)),
            ),
          // Pastki panel: faol safar > qabul > oddiy
          if (hasTrip)
            _activeTripPanel(t)
          else if (hasOffer)
            _acceptPanel(t)
          else
            _bottomPanel(online, t),
          // Panel yashiringanda — tortib chiqarish uchun kichik tutqich
          if (!hasOffer && !hasTrip && _panelHidden)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _panelHidden = false),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 26,
                  alignment: Alignment.center,
                  child: Container(
                    width: 56, height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          // "Buyurtma olinmadi"
          if (_showNotTaken) _notTakenOverlay(t),
        ],
      ),
    );
  }

  // ---------------- Xarita ----------------

  Widget _mapWidget(bool online) {
    final places = ref.watch(geoPlacesProvider).valueOrNull ?? const <GeoPlace>[];
    final allRoads = ref.watch(geoRoadsProvider).valueOrNull ?? const <GeoRoad>[];
    final geoMarkers =
        ref.watch(geoMarkersProvider).valueOrNull ?? const <GeoMapMarker>[];
    // farmland — chiziq emas, yashil dala poligoni.
    final roads = [
      for (final r in allRoads)
        if (r.kind != 'farmland') r,
    ];
    final farmlands = [
      for (final r in allRoads)
        if (r.kind == 'farmland' && r.points.length >= 3) r,
    ];
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _fix?.pos ?? beshariqCenter,
        initialZoom: 16,
        minZoom: 11,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.contain(bounds: beshariqBounds),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        onPositionChanged: (camera, _) {
          if ((camera.zoom - _zoom).abs() > 0.15) {
            setState(() => _zoom = camera.zoom);
          }
        },
        onTap: (_, __) {
          if (_offer == null && _activeTrip == null) {
            setState(() => _panelHidden = !_panelHidden);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.beshariq.driver_app',
          maxZoom: 19,
        ),
        // Dehqonchilik maydonlari — yashil dalalar (yo'llar ostida)
        if (farmlands.isNotEmpty && _zoom >= 13 && _offer == null)
          PolygonLayer(
            polygons: [
              for (final f in farmlands)
                Polygon(
                  points: f.points,
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.26),
                  borderColor: const Color(0xFF2E7D32),
                  borderStrokeWidth: 1.5,
                ),
            ],
          ),
        if (roads.isNotEmpty && _zoom >= 13 && _offer == null)
          PolylineLayer(
            polylines: [
              // Casing (kontur) qatlami — avval chiziladi (pastda)
              for (final r in roads)
                Polyline(
                  points: r.points,
                  strokeWidth: r.kind == 'center'
                      ? 9.5
                      : (r.kind == 'main' ? 7.0 : 4.5),
                  color: r.kind == 'center'
                      ? const Color(0xFFB76E00)
                      : (r.kind == 'main'
                          ? const Color(0xFFCC9A1F)
                          : const Color(0xFFB9C0CA)),
                ),
              // Fill qatlami — ustida (rangli)
              for (final r in roads)
                Polyline(
                  points: r.points,
                  strokeWidth: r.kind == 'center'
                      ? 7.0
                      : (r.kind == 'main' ? 5.0 : 3.0),
                  color: r.kind == 'center'
                      ? const Color(0xFFF6A623)
                      : (r.kind == 'main'
                          ? const Color(0xFFFFD24D)
                          : const Color(0xFFFFFFFF)),
                ),
            ],
          ),
        // Ikkinchi segment (ovqat: oshxona -> mijoz) — ko'k, asosiydan pastda
        if (_route2.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: _route2,
              strokeWidth: 5,
              color: const Color(0xFF1E88E5),
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ]),
        // Yangi buyurtma marshruti (yashil)
        if (_route.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: _route,
              strokeWidth: 6,
              color: const Color(0xFF2E7D32),
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ]),
        if (places.isNotEmpty && _zoom >= 14 && _offer == null)
          MarkerLayer(markers: [for (final p in places) _placeMarker(p)]),
        // Admin xarita belgilari (do'kon/fermer/svetofor/...)
        if (geoMarkers.isNotEmpty && _zoom >= 14 && _offer == null)
          MarkerLayer(
              markers: [for (final m in geoMarkers) _geoMarker(m)]),
        // Olib ketish nuqtasi — bayroq (taklif paytida)
        if (_offer != null)
          MarkerLayer(markers: [
            Marker(
              point: _offer!.pickup,
              width: 40,
              height: 44,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.flag_rounded, color: Color(0xFF2E7D32), size: 38, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
            ),
          ]),
        // Faol safar nishoni — maqsad nuqtasi (vertikalga mos ikonka)
        if (_activeTrip != null && _route.isNotEmpty)
          MarkerLayer(markers: [
            Marker(
              point: _route.last,
              width: 44,
              height: 48,
              alignment: Alignment.topCenter,
              child: Icon(
                _tripTargetIcon(_activeTrip!),
                color: const Color(0xFF2E7D32),
                size: 40,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
            // Ovqat: ikkinchi segment oxiri — mijoz manzili (ko'k uycha)
            if (_route2.isNotEmpty)
              Marker(
                point: _route2.last,
                width: 40,
                height: 44,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF1E88E5),
                  size: 34,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
          ]),
        if (_fix != null)
          MarkerLayer(markers: [_driverMarker(_fix!, online)]),
      ],
    );
  }

  /// Faol ish maqsad nuqtasi ikonkasi: ovqat olishdan oldin — oshxona,
  /// mijozga yo'lda — bayroq; taksi kutish — yo'lovchi.
  IconData _tripTargetIcon(DriverTrip t) {
    if (t.isFood) {
      return t.goingToDropoff ? Icons.flag_rounded : Icons.storefront_rounded;
    }
    return t.status == 'IN_PROGRESS' || t.status == 'IN_TRANSIT'
        ? Icons.flag_rounded
        : Icons.person_pin_circle_rounded;
  }

  Marker _driverMarker(DriverFix fix, bool online) {
    // Ihcham o'lcham — xaritani bosib qo'ymaydi, zoom bilan yumshoq o'sadi.
    final size = (30 + (_zoom - 16) * 5).clamp(24.0, 44.0);
    return Marker(
      point: _animPos ?? fix.pos,
      width: size + 14,
      height: size + 14,
      alignment: Alignment.center,
      child: CarMarker(
        size: size,
        color: online ? _gold : _offlineNav,
        heading: fix.heading,
        glow: online,
      ),
    );
  }

  /// Admin belgisi turi → (rang, ikonka) — customer ilovasi bilan mos.
  static (Color, IconData) _markerStyle(String kind) {
    switch (kind) {
      case 'shop':
        return (const Color(0xFF1971C2), Icons.storefront_rounded);
      case 'construction':
        return (const Color(0xFFE8590C), Icons.engineering_rounded);
      case 'traffic_light':
        return (const Color(0xFF2F9E44), Icons.traffic_rounded);
      case 'restriction':
        return (const Color(0xFFE03131), Icons.block_rounded);
      case 'farm':
        return (const Color(0xFF2E7D32), Icons.agriculture_rounded);
      default:
        return (const Color(0xFF7048E8), Icons.push_pin_rounded);
    }
  }

  /// Admin xarita belgisi — kichik kvadratik chip (haydovchiga mo'ljal).
  Marker _geoMarker(GeoMapMarker m) {
    final (color, icon) = _markerStyle(m.kind);
    final hasLabel = (m.label ?? '').isNotEmpty;
    return Marker(
      point: LatLng(m.lat, m.lng),
      width: 110,
      height: hasLabel ? 42 : 26,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white, width: 1.6),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 3),
                ],
              ),
              child: Icon(icon, size: 13, color: Colors.white),
            ),
            if (hasLabel)
              Container(
                margin: const EdgeInsets.only(top: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(m.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF37474F))),
              ),
          ],
        ),
      ),
    );
  }

  Marker _placeMarker(GeoPlace p) {
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: 110,
      height: 36,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 14, color: Color(0xFF6D4C41)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF455A64))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reconnectingPill(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Text(t.homeReconnecting,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _avatar() {
    final initial = ref.watch(driverProfileProvider).valueOrNull?.initial ?? '?';
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
      ),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, const Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.85), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _poolBadge() {
    final count = ref.watch(poolProvider).valueOrNull?.length ?? 0;
    return _MapButton(
      icon: Icons.list_alt_rounded,
      badge: count,
      onTap: () async {
        final taken = await Navigator.of(context).push<DriverOffer>(
          MaterialPageRoute(builder: (_) => const PoolScreen()),
        );
        // Pool'dan olingan HAR QANDAY buyurtma (taksi/dostavka/ovqat) —
        // faol-ish oynasi majburiy ochiladi.
        if (taken != null) {
          await _enterTrip(taken.vertical, taken.orderId);
        }
      },
    );
  }

  /// Qo'ng'iroqcha — admin xabarlari. O'qilmagan bo'lsa qizil sonli badge.
  Widget _bellButton() {
    final unread = ref.watch(unreadMessagesProvider).valueOrNull ?? 0;
    return _MapButton(
      icon: unread > 0
          ? Icons.notifications_active_rounded
          : Icons.notifications_rounded,
      iconColor: unread > 0 ? const Color(0xFFB8860B) : null,
      badge: unread,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MessagesScreen()),
        );
        // Qaytganda badge yangilansin (ekran ochilishi o'qilgan deb belgilaydi).
        if (mounted) ref.invalidate(unreadMessagesProvider);
      },
    );
  }

  Widget _recenter() {
    return _MapButton(
      icon: Icons.my_location_rounded,
      onTap: () {
        if (_fix != null) _map.move(_fix!.pos, 16.5);
      },
    );
  }

  // ---------------- Yangi buyurtma banneri ----------------

  Widget _orderBanner(double topPad, AppLocalizations t) {
    final progress = (_offerLeft / 20).clamp(0.0, 1.0);
    final o = _offer!;
    final (_, vIcon, vColor) = _verticalInfo(o.vertical, t);
    return GestureDetector(
      onTap: _skipOffer,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: topPad + 70,
            color: Colors.black.withValues(alpha: 0.78),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: topPad + 10, left: 18, right: 18, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: vColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: vColor.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Icon(vIcon, color: vColor, size: 21),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(t.homeNewOrder,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Text(t.homeTapToDismiss,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 44, height: 44,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.5,
                                backgroundColor: Colors.white.withValues(alpha: 0.18),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                              ),
                              Center(
                                child: Text('$_offerLeft',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pastdan yashil — qolgan vaqt
                FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(height: 2, color: const Color(0xFF66BB6A)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Qabul paneli ----------------

  Widget _acceptPanel(AppLocalizations t) {
    final o = _offer!;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(alignment: Alignment.centerLeft, child: _verticalBadge(o.vertical, t)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _infoChip(Icons.route_rounded, t.homeDistance, '${o.distanceKm.toStringAsFixed(2)} km', const Color(0xFF1565C0))),
                const SizedBox(width: 12),
                Expanded(child: _infoChip(Icons.payments_rounded, t.homePrice, groupThousands(o.amount), const Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.homePickupEarningLine(o.pickupName, groupThousands(o.earning)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.outline, fontSize: 12.5)),
            if (o.isFood) ...[
              const SizedBox(height: 12),
              _foodCashCard(o, t),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _accepting ? null : _acceptOffer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              child: _accepting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(t.homeTakeOrder),
            ),
          ],
        ),
      ),
    );
  }

  /// Ovqat qabul oynasidagi naqd taqsimot — qabuldan oldin haydovchiga ko'rinadi.
  /// Naqd to'lov: mijozdan umumiy summani olasiz, oshxonaga taom narxini
  /// to'laysiz; daromad = yetkazish; xizmat haqi balansdan yechiladi.
  Widget _foodCashCard(DriverOffer o, AppLocalizations t) {
    const gold = Color(0xFF8A6D1B);
    Widget row(IconData icon, String label, int value, Color c,
        {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 17, color: c),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
            Text("${groupThousands(value)} so'm",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                    color: c)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, size: 16, color: gold),
              const SizedBox(width: 6),
              Text(t.homeCashPayment,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: gold)),
            ],
          ),
          const SizedBox(height: 6),
          row(Icons.account_balance_wallet_rounded, t.homeCollectFromCustomer,
              o.amount, const Color(0xFF2E7D32), bold: true),
          row(Icons.storefront_rounded, t.homePayKitchen,
              o.foodItemsTotal, const Color(0xFFC62828)),
          row(Icons.trending_up_rounded, t.homeYourEarning, o.earning,
              const Color(0xFF1565C0)),
          if (o.foodServiceFee > 0)
            row(Icons.receipt_long_rounded, t.homeServiceFeeBalance,
                o.foodServiceFee, gold),
        ],
      ),
    );
  }

  /// Vertikal -> (yorliq, ikonka, rang): Taksi / Taom kuryeri / Yetgazish.
  (String, IconData, Color) _verticalInfo(String v, AppLocalizations t) {
    switch (v) {
      case 'taxi':
        return (t.taxiTab, Icons.local_taxi_rounded, const Color(0xFF8A6D1B));
      case 'parcel':
        return (t.deliveryTab, Icons.local_shipping_rounded, const Color(0xFF1565C0));
      default:
        return (t.vertFood, Icons.restaurant_rounded, const Color(0xFFEF6C00));
    }
  }

  Widget _verticalBadge(String vertical, AppLocalizations t) {
    final (label, icon, color) = _verticalInfo(vertical, t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notTakenOverlay(AppLocalizations t) {
    return IgnorePointer(
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_rounded, color: Colors.white70, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(t.homeOrderNotTaken,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Pastki panel (taklif yo'q payti) ----------------

  /// Pastki panel — kontent o'lchamida (bo'sh joy yo'q). Xarita bosilsa
  /// pastga yashirinadi (AnimatedSlide).
  Widget _bottomPanel(bool online, AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(driverProfileProvider).valueOrNull;
    final homeActive = profile?.isHomeModeActive ?? false;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        offset: _panelHidden ? const Offset(0, 1) : Offset.zero,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.surface, scheme.surfaceContainerLow],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _panelHidden = true),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: 46, height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              homeActive ? _homeModeCard(t, profile!) : Row(
                children: [
                  Expanded(child: _walletCard(t)),
                  const SizedBox(width: 12),
                  Expanded(child: _todayCard(t)),
                ],
              ),
              // Liniyaga chiqish / Ishni yakunlash — DOIM ko'rinadi.
              if (homeActive) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_rounded, size: 14, color: _gold),
                    const SizedBox(width: 5),
                    Text(t.homeModeLabel,
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700, color: _gold)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SlideToConfirm(
                key: ValueKey('slider_$online'),
                reverse: online,
                glow: !online,
                label: online ? t.homeFinishWork : t.homeGoOnline,
                icon: online
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                fillColor: online ? const Color(0xFFC62828) : _gold,
                onConfirmed: () => _setOnline(!online),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletCard(AppLocalizations t) {
    final balance = ref.watch(driverProfileProvider).valueOrNull?.balance ?? 0;
    return _PremiumCard(
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF2E7D32),
      title: t.walletTitle,
      value: t.priceSom(groupThousands(balance)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BalanceScreen()),
      ),
    );
  }

  Widget _todayCard(AppLocalizations t) {
    final todayCount = ref.watch(earningsProvider).valueOrNull?.total.todayCount ?? 0;
    return _PremiumCard(
      icon: Icons.insights_rounded,
      color: const Color(0xFF1565C0),
      title: t.homeTodayCard,
      value: t.homeTodayCount(todayCount),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TodayScreen()),
      ),
    );
  }

  /// "Uyga" rejimi faol bo'lganda Hisobim/Bugun o'rniga: uy manzili +
  /// tahrirlash + "Yo'l-yo'lakay buyurtma olish" (pool, uyga mos buyurtmalar
  /// tepada belgilangan).
  Widget _homeModeCard(AppLocalizations t, DriverProfile profile) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_rounded, size: 18, color: _gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.homeAddress ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () => _editHomeAddress(profile),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_rounded, size: 18, color: scheme.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final taken = await Navigator.of(context).push<DriverOffer>(
                  MaterialPageRoute(builder: (_) => const PoolScreen()),
                );
                if (taken != null) await _enterTrip(taken.vertical, taken.orderId);
              },
              icon: const Icon(Icons.route_rounded, size: 19),
              label: Text(t.homeModePoolButton,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Faol safar (qabuldan keyin) ----------------

  Widget _chatButton(AppLocalizations loc) {
    final t = _activeTrip;
    if (t == null) return const SizedBox.shrink();
    final unreadChat = (_chatOther - _chatSeen).clamp(0, 99);
    return _MapButton(
      icon: Icons.chat_bubble_rounded,
      iconColor: const Color(0xFF2E7D32),
      badge: unreadChat,
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripChatScreen(
                tripId: t.id,
                vertical: t.vertical,
                title: t.isTaxi
                    ? loc.labelPassenger
                    : (t.isFood ? loc.labelKitchen : loc.labelCustomer),
                phone: t.isFood ? null : t.customerPhone)));
        // Chat ochildi — hozirgi xabarlar ko'rilgan hisoblanadi.
        if (mounted) setState(() => _chatSeen = _chatOther);
      },
    );
  }

  Widget _activeTripPanel(AppLocalizations loc) {
    final t = _activeTrip!;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 14 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surface, scheme.surfaceContainerLow],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: t.isDone
              ? _tripSummary(t, scheme, loc)
              : _tripControls(t, scheme, loc),
        ),
      ),
    );
  }

  /// Vertikal + holatga qarab asosiy tugma (yorliq, amal, qizilmi).
  ({String label, String action, bool red}) _mainAction(
      DriverTrip t, AppLocalizations loc) {
    if (t.isTaxi) {
      switch (t.status) {
        case 'ACCEPTED':
          return (label: loc.actionArrived, action: 'arrive', red: false);
        case 'ARRIVED':
          return (label: loc.actionSetOff, action: 'start', red: false);
        default:
          return (label: loc.actionFinishTrip, action: 'complete', red: true);
      }
    }
    if (t.isFood) {
      switch (t.status) {
        case 'READY':
          return (label: loc.actionPickedOrder, action: 'pickup', red: false);
        case 'PICKED_UP':
          return (label: loc.actionDelivered, action: 'delivered', red: true);
        default:
          return (label: loc.actionPreparing, action: 'pickup', red: false);
      }
    }
    // Dostavka — qo'shimcha "oldim" qadami bilan.
    switch (t.status) {
      case 'ACCEPTED':
        return (label: loc.actionArrived, action: 'arrive', red: false);
      case 'ARRIVED':
        return (label: loc.actionPickedParcel, action: 'pickup', red: false);
      case 'PICKED_UP':
        return (label: loc.actionSetOff, action: 'transit', red: false);
      default:
        return (label: loc.actionFinishTrip, action: 'delivered', red: true);
    }
  }

  List<Widget> _tripControls(
      DriverTrip t, ColorScheme scheme, AppLocalizations loc) {
    final (vLabel, vIcon, vColor) = _verticalInfo(t.vertical, loc);
    final cfg = _mainAction(t, loc);
    final earlyState = t.isFood
        ? t.status != 'PICKED_UP'
        : (t.status == 'ACCEPTED' || t.status == 'ARRIVED');
    // Ovqat: oshxona tayyor deb belgilamaguncha (READY) olib bo'lmaydi.
    final foodWaiting =
        t.isFood && t.status != 'READY' && t.status != 'PICKED_UP';
    return [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: vColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(vIcon, size: 14, color: vColor),
                const SizedBox(width: 5),
                Text(vLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: vColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_tripStatusText(t, loc),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: scheme.onSurface)),
          ),
          if (earlyState)
            TextButton.icon(
              onPressed: _tripBusy ? null : _cancelTripConfirm,
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(loc.homeCancelShort),
            ),
        ],
      ),
      const SizedBox(height: 10),
      // Ovqat: to'liq yo'nalish — oshxona -> mijoz manzili (+ qo'ng'iroq).
      if (t.isFood) ...[
        _foodRouteBlock(t, loc),
        const SizedBox(height: 10),
      ],
      Row(
        children: [
          Expanded(child: _leftCard(t, loc)),
          const SizedBox(width: 12),
          Expanded(child: _priceCard(t, loc)),
        ],
      ),
      const SizedBox(height: 14),
      if (foodWaiting)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFEF6C00).withValues(alpha: 0.4)),
          ),
          child: Text(loc.homePreparingBanner,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFFEF6C00))),
        )
      else
        SlideToConfirm(
          // Amal muvaffaqiyatsiz bo'lsa status o'zgarmaydi, lekin
          // _actionFailCount oshadi — shu bilan slayder qayta yasaladi va
          // "tasdiqlandi" holatida tiqilib qolmasdan yana tortish mumkin.
          key: ValueKey('trip_${t.status}_$_actionFailCount'),
          glow: true,
          label: cfg.label,
          icon: cfg.red ? Icons.flag_rounded : Icons.arrow_forward_rounded,
          fillColor: cfg.red ? const Color(0xFFC62828) : _gold,
          onConfirmed: () => _tripAction(
              () => ref.read(tripApiProvider).act(t.vertical, t.id, cfg.action)),
        ),
    ];
  }

  /// Ovqat yo'nalish bloki — FAQAT joriy bosqich ko'rsatiladi (oshxonaga
  /// YOKI mijozga, ikkalasi birga emas). Xarita ko'proq joy egallashi uchun
  /// panel balandligi qisqartirilgan; kichik "1/2"/"2/2" belgisi keyingi
  /// bosqich borligini eslatadi.
  Widget _foodRouteBlock(DriverTrip t, AppLocalizations loc) {
    final scheme = Theme.of(context).colorScheme;
    final pickedUp = t.goingToDropoff;
    final icon = pickedUp ? Icons.home_rounded : Icons.storefront_rounded;
    final color =
        pickedUp ? const Color(0xFF1E88E5) : const Color(0xFFEF6C00);
    final label = pickedUp ? loc.homeCustomerAddress : loc.homeKitchenToPickup;
    final value = pickedUp ? (t.dropoffText ?? '—') : t.pickupText;
    final onCall = pickedUp && (t.customerPhone ?? '').isNotEmpty
        ? () => _callPhone(t.customerPhone)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.outline)),
                    const SizedBox(width: 6),
                    Text(pickedUp ? '2/2' : '1/2',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.outline.withValues(alpha: 0.6))),
                  ],
                ),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (onCall != null)
            IconButton.filledTonal(
              onPressed: onCall,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.call_rounded, size: 18),
            ),
        ],
      ),
    );
  }

  /// Chap karta — taksi: Kutish/masofa; dostavka: jo'natuvchigacha/qabul qiluvchi.
  Widget _leftCard(DriverTrip t, AppLocalizations loc) {
    if (t.isTaxi) return _waitCard(t, loc);
    if (t.isFood) {
      // Ovqat: oshxonaga to'lanadigan naqd summa (eng muhim).
      return _tripCard(
        icon: Icons.storefront_rounded,
        color: const Color(0xFFEF6C00),
        title: loc.homeCashToKitchen,
        value: "${groupThousands(t.foodItemsTotal)} so'm",
      );
    }
    if (t.status == 'ACCEPTED') {
      final me = _fix?.pos;
      final km = me != null
          ? const Distance().as(LengthUnit.Kilometer, me, t.pickup)
          : null;
      return _tripCard(
        icon: Icons.route_rounded,
        color: const Color(0xFF1565C0),
        title: loc.homeToSender,
        value: km != null ? '${km.toStringAsFixed(2)} km' : '—',
      );
    }
    // Qabul qiluvchi — ustiga bosilsa telefon ilovasi ochiladi (qo'ng'iroq).
    final hasPhone = (t.recipientPhone ?? '').isNotEmpty;
    return _tripCard(
      icon: hasPhone ? Icons.call_rounded : Icons.person_pin_circle_rounded,
      color: const Color(0xFF2E7D32),
      title: hasPhone ? loc.homeRecipientCall : loc.homeRecipient,
      value: (t.recipientName ?? '').isNotEmpty ? t.recipientName! : '—',
      onTap: hasPhone ? () => _callPhone(t.recipientPhone) : null,
    );
  }

  String _tripStatusText(DriverTrip t, AppLocalizations loc) {
    if (t.isTaxi) {
      switch (t.status) {
        case 'ACCEPTED':
          return loc.statusTaxiAccepted;
        case 'ARRIVED':
          return loc.statusTaxiArrived;
        case 'IN_PROGRESS':
          return loc.statusTaxiInProgress;
      }
      return '';
    }
    if (t.isFood) {
      switch (t.status) {
        case 'PENDING':
          return loc.statusFoodPending;
        case 'ACCEPTED':
        case 'PREPARING':
          return loc.statusFoodAccepted;
        case 'READY':
          return loc.statusFoodReady;
        case 'PICKED_UP':
          return loc.statusFoodPicked;
      }
      return '';
    }
    switch (t.status) {
      case 'ACCEPTED':
        return loc.statusParcelAccepted;
      case 'ARRIVED':
        return loc.statusParcelArrived;
      case 'PICKED_UP':
        return loc.statusParcelPicked;
      case 'IN_TRANSIT':
        return loc.statusParcelTransit;
    }
    return '';
  }

  /// Chap karta — Hisobim o'rnida: ACCEPTED=masofa, ARRIVED=avtomatik kutish,
  /// IN_PROGRESS=Kutish tugmasi (to'xtaganda ishlaydi).
  Widget _waitCard(DriverTrip t, AppLocalizations loc) {
    if (t.status == 'ACCEPTED') {
      return _tripCard(
        icon: Icons.route_rounded,
        color: const Color(0xFF1565C0),
        title: loc.homeToCustomer,
        value: '${t.pickupDistanceKm.toStringAsFixed(2)} km',
      );
    }
    // ARRIVED — kutish AVTOMATIK; jonli mm:ss taymer (bosilmaydi).
    if (t.status == 'ARRIVED') return _waitTimerCard(t, loc);
    // IN_PROGRESS — kutyaptan to'xtatish (jonli taymer) yoki to'xtaganda boshlash.
    if (t.waiting) {
      return _waitTimerCard(t, loc,
          onTap: _tripBusy
              ? null
              : () => _tripAction(() =>
                  ref.read(tripApiProvider).act(t.vertical, t.id, 'wait')));
    }
    final stopped = (_fix?.speedKmh ?? 0) < 5;
    return _tripCard(
      icon: Icons.timer_outlined,
      color: const Color(0xFFEF6C00),
      title: loc.homeWaiting,
      value: stopped ? loc.homeStart : '—',
      onTap: (!_tripBusy && stopped)
          ? () => _tripAction(
              () => ref.read(tripApiProvider).act(t.vertical, t.id, 'wait'))
          : null,
    );
  }

  /// Jonli kutish taymeri (mm:ss). 2 daqiqa bepul; keyin tillo + porlab turadi.
  /// `_tick` (1s) har soniya rebuild qiladi → taymer real-time sanaydi.
  Widget _waitTimerCard(DriverTrip t, AppLocalizations loc,
      {VoidCallback? onTap}) {
    final paid = t.waitPaidStarted;
    final accent = paid ? const Color(0xFFB8860B) : const Color(0xFFEF6C00);
    // Har soniya tebranuvchi porlash (≈1 Hz) — "porlab turgan" effekt.
    final pulse = t.liveWaitSeconds.isEven;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 650),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: paid
            ? const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: paid ? null : accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: paid ? const Color(0xFF9C6F00) : accent.withValues(alpha: 0.4),
            width: paid ? 1.4 : 1),
        boxShadow: paid
            ? [
                BoxShadow(
                    color: const Color(0xFFFFC107)
                        .withValues(alpha: pulse ? 0.60 : 0.28),
                    blurRadius: pulse ? 22 : 11,
                    spreadRadius: pulse ? 1.5 : 0.3),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(paid ? Icons.timer_rounded : Icons.hourglass_top_rounded,
              color: paid ? const Color(0xFF6D4C00) : accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    onTap != null
                        ? loc.homeWaitingStop
                        : (paid ? loc.homePaidWait : loc.homeFreeWait),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: paid ? const Color(0xFF6D4C00) : accent,
                        fontWeight: FontWeight.w700)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(t.waitClock,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: paid
                                ? const Color(0xFF3E2C00)
                                : Colors.black87)),
                    if (t.currentWaitFee > 0) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('+${groupThousands(t.currentWaitFee)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D4C00))),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(16), onTap: onTap, child: card),
    );
  }

  Widget _priceCard(DriverTrip t, AppLocalizations loc) {
    if (t.isFood) {
      // Ovqat: haydovchi sof daromadi (yetkazish). Xizmat haqi balansdan.
      return _tripCard(
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF2E7D32),
        title: loc.homeYourEarning,
        value: "${groupThousands(t.foodIncome)} so'm",
      );
    }
    return _tripCard(
      icon: Icons.payments_rounded,
      color: const Color(0xFF2E7D32),
      title: loc.homePrice,
      value: "${groupThousands(t.currentFare)} so'm",
    );
  }

  Widget _tripCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: onTap != null ? 0.5 : 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: color,
                        fontWeight: FontWeight.w600)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(16), onTap: onTap, child: card),
    );
  }

  String _sizeLabel(String s, AppLocalizations loc) => s == 'SMALL'
      ? loc.sizeSmall
      : (s == 'LARGE' ? loc.sizeLarge : loc.sizeMedium);

  List<Widget> _tripSummary(
      DriverTrip t, ColorScheme scheme, AppLocalizations loc) {
    final isTaxi = t.isTaxi;
    final waitFee = t.currentWaitFee;
    final surcharge = t.pickupSurcharge;
    final base = (t.fare - surcharge - waitFee).clamp(0, t.fare).toInt();
    return [
      const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 44),
      const SizedBox(height: 6),
      Text(
          t.isFood
              ? loc.summaryFoodTitle
              : (isTaxi ? loc.summaryTaxiTitle : loc.summaryParcelTitle),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      if (t.isFood) ...[
        _sumRow(loc.sumKitchenCash,
            "${groupThousands(t.foodItemsTotal)} so'm"),
        _sumRow(loc.sumDeliveryEarning,
            "${groupThousands(t.foodIncome)} so'm"),
        if (t.foodServiceFee > 0)
          _sumRow(loc.homeServiceFeeBalance,
              "${groupThousands(t.foodServiceFee)} so'm"),
      ] else if (isTaxi) ...[
        _sumRow(loc.sumTaxiFare, "${groupThousands(base)} so'm"),
        if (surcharge > 0)
          _sumRow(loc.sumPickupSurcharge, "${groupThousands(surcharge)} so'm"),
        if (waitFee > 0)
          _sumRow(loc.homePaidWait, "${groupThousands(waitFee)} so'm"),
        if (t.distanceKm > 0)
          _sumRow(loc.sumDistance, '${t.distanceKm.toStringAsFixed(1)} km'),
        _sumRow(loc.sumTripTime, loc.minutesValue(t.durationMinutes)),
      ] else ...[
        _sumRow(loc.sumParcelFare, "${groupThousands(t.fare)} so'm"),
        if ((t.size ?? '').isNotEmpty)
          _sumRow(loc.sumSize, _sizeLabel(t.size!, loc)),
        if ((t.recipientName ?? '').isNotEmpty)
          _sumRow(loc.homeRecipient, t.recipientName!),
        if (t.distanceKm > 0)
          _sumRow(loc.homeDistance, '${t.distanceKm.toStringAsFixed(1)} km'),
        _sumRow(loc.sumTimeLabel, loc.minutesValue(t.durationMinutes)),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: scheme.outlineVariant, height: 1),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isTaxi ? loc.collectFromPassenger : loc.collectFromCustomer,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text("${groupThousands(t.fare)} so'm",
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E7D32))),
        ],
      ),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: _exitTrip,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: const Color(0xFF2E7D32),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        child: Text(loc.doneButton),
      ),
    ];
  }

  Widget _sumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ================= Xarita tugmasi (yagona zamonaviy uslub) =================

/// Xarita ustidagi boshqaruv tugmasi: yumaloq kvadrat (squircle), yumshoq
/// soya + nozik chegara, ixtiyoriy qizil sonli badge. Barcha suzuvchi
/// tugmalar (pool/xabar/suhbat/markazlash) bitta tilda gaplashadi.
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final int badge;

  const _MapButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14000000)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(icon, color: iconColor ?? _offlineNav, size: 23),
              ),
            ),
          ),
        ),
        if (badge > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(4.5),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.6),
              ),
              child: Text(badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      height: 1)),
            ),
          ),
      ],
    );
  }
}

// ================= Premium karta =================

class _PremiumCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _PremiumCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Status oy =================

class _StatusMoon extends StatelessWidget {
  final bool online;
  final VoidCallback onTap;
  const _StatusMoon({required this.online, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62, height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (online) BoxShadow(color: _gold.withValues(alpha: 0.65), blurRadius: 20, spreadRadius: 2),
            const BoxShadow(color: Colors.black38, blurRadius: 6),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(size: const Size.square(62), painter: _MoonPainter(online)),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final bool online;
  _MoonPainter(this.online);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final base = online ? const Color(0xFFD4AF37) : const Color(0xFF9AA3A8);
    final light = online ? const Color(0xFFF4D469) : const Color(0xFFBCC3C7);
    final dark = online ? const Color(0xFFA8842A) : const Color(0xFF7E888E);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    final crater = Paint()..color = dark.withValues(alpha: 0.65);
    final craters = <(Offset, double)>[
      (Offset(r * 0.75, r * 0.7), r * 0.2),
      (Offset(r * 1.4, r * 0.95), r * 0.14),
      (Offset(r * 0.95, r * 1.45), r * 0.17),
      (Offset(r * 1.5, r * 1.45), r * 0.1),
      (Offset(r * 1.25, r * 0.5), r * 0.08),
    ];
    for (final (o, rad) in craters) {
      canvas.drawCircle(o, rad, crater);
      canvas.drawCircle(o.translate(-rad * 0.25, -rad * 0.25), rad * 0.7,
          Paint()..color = light.withValues(alpha: 0.25));
    }
    canvas.drawCircle(Offset(r * 0.6, r * 0.55), r * 0.35,
        Paint()..color = Colors.white.withValues(alpha: online ? 0.28 : 0.18));
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.online != online;
}

// ================= Tezlik =================

class _SpeedBadge extends StatelessWidget {
  final double speedKmh;
  const _SpeedBadge(this.speedKmh);

  @override
  Widget build(BuildContext context) {
    final over = speedKmh > 70;
    final color = over ? const Color(0xFFD32F2F) : _offlineNav;
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: over ? const Color(0xFFD32F2F) : Colors.transparent, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${speedKmh.round()}',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color, height: 1)),
          Text('km/s', style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}
