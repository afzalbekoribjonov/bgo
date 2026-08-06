import 'nav_engine.dart';
import 'nav_support.dart';

/// Navigatsiya ogohlantirishi turi.
enum NavAlertKind {
  /// Burilishgacha 200 metr qoldi.
  turn,

  /// Uzoq to'g'ri yo'l boshlandi (2 km dan ortiq).
  straight,

  /// Oldinda admin belgilagan svetofor.
  trafficLight,
}

/// Bitta ogohlantirish hodisasi — banner + ovoz + TTS uchun.
class NavAlertEvent {
  final NavAlertKind kind;

  /// Burilish turi (OSRM modifier: left|right|slight left|uturn|...).
  /// Faqat [NavAlertKind.turn] uchun.
  final String? modifier;

  /// Ko'rsatiladigan masofa (metr) — turn uchun ~200, svetofor uchun qolgan.
  final double distanceM;

  /// Ko'cha nomi (bo'lsa) — bannerda qo'shimcha ma'lumot sifatida.
  final String? streetName;

  const NavAlertEvent({
    required this.kind,
    required this.distanceM,
    this.modifier,
    this.streetName,
  });

  /// Uzoq to'g'ri yo'l uchun masofa km'da (yaxlitlangan).
  int get distanceKmRounded => (distanceM / 1000).round();
}

/// Ogohlantirishlarni CHEGARADAN O'TISHDA BIR MARTA (edge-triggered) beruvchi
/// holat mashinasi — har GPS tikida qayta-qayta emas.
///
/// Qo'shimcha himoya: turlar orasida umumiy "sovutish" oynasi + kichik navbat,
/// shunda aylanma yo'l yoki ketma-ket burilishlarda ovozlar bir-birini bosib
/// ketmaydi, lekin yo'qolib ham ketmaydi (biroz kechikadi, xolos).
class NavAlertTracker {
  /// Burilish ogohlantirishi shu masofadan yaqin bo'lganda beriladi (metr).
  static const double turnAlertM = 200;

  /// Shu masofadan uzun qadam "uzoq to'g'ri yo'l" hisoblanadi (metr).
  static const double straightMinM = 2000;

  /// Svetoforga shu masofa qolganda ogohlantiriladi (metr).
  static const double trafficLightM = 180;

  /// Ikki ogohlantirish orasidagi minimal tanaffus.
  static const Duration cooldown = Duration(seconds: 5);

  /// Navbatda ko'pi bilan shuncha ogohlantirish saqlanadi (eskisi tashlanadi).
  static const int maxQueue = 2;

  /// Qaysi qadam uchun burilish ogohlantirishi berilgan.
  final Set<int> _turnFired = {};

  /// Qaysi qadam uchun "uzoq to'g'ri yo'l" ogohlantirishi berilgan.
  final Set<int> _straightFired = {};

  /// Qaysi svetofor belgisi uchun ogohlantirish berilgan (marshrut davomida).
  final Set<String> _markerFired = {};

  /// Oxirgi kuzatilgan qadam indeksi — qadam almashganini aniqlash uchun.
  int _lastStepIndex = -1;

  DateTime? _lastAlertAt;
  final List<NavAlertEvent> _queue = [];

  /// Yangi marshrut yuklanganda / navigatsiya tugaganda — hammasini tozalash.
  /// Aks holda eski marshrutning "berilgan" belgilari yangisini bo'g'ib qo'yadi.
  void reset() {
    _turnFired.clear();
    _straightFired.clear();
    _markerFired.clear();
    _lastStepIndex = -1;
    _lastAlertAt = null;
    _queue.clear();
  }

  /// Har GPS o'qishida chaqiriladi. Ogohlantirish vaqti kelgan bo'lsa — uni
  /// qaytaradi, aks holda `null`.
  ///
  /// [markersAhead] — oldinda turgan svetofor belgilari (NavEngine'dan).
  NavAlertEvent? tick(
    NavProgress progress,
    List<RouteStep> steps,
    List<MarkerAhead> markersAhead, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    _collect(progress, steps, markersAhead);
    return _dequeue(t);
  }

  /// Yangi ogohlantirishlarni aniqlab navbatga qo'yadi.
  void _collect(
    NavProgress progress,
    List<RouteStep> steps,
    List<MarkerAhead> markersAhead,
  ) {
    final stepIndex = progress.stepIndex;

    // 1) Burilishgacha 200 metr — har qadam uchun bir marta.
    final toManeuver = progress.distanceToManeuverM;
    final next = progress.nextStep;
    if (toManeuver != null &&
        next != null &&
        stepIndex >= 0 &&
        toManeuver <= turnAlertM &&
        !_turnFired.contains(stepIndex) &&
        _isTurnLike(next)) {
      _turnFired.add(stepIndex);
      _push(NavAlertEvent(
        kind: NavAlertKind.turn,
        distanceM: turnAlertM,
        modifier: next.modifier,
        streetName: next.streetName,
      ));
    }

    // 2) Yangi qadam boshlandi VA u uzun to'g'ri yo'l — bir marta.
    if (stepIndex >= 0 && stepIndex != _lastStepIndex) {
      _lastStepIndex = stepIndex;
      if (stepIndex < steps.length) {
        final cur = steps[stepIndex];
        if (cur.distanceMeters >= straightMinM &&
            !_straightFired.contains(stepIndex)) {
          _straightFired.add(stepIndex);
          _push(NavAlertEvent(
            kind: NavAlertKind.straight,
            distanceM: cur.distanceMeters,
            streetName: cur.streetName,
          ));
        }
      }
    }

    // 3) Oldindagi svetofor — har belgi uchun bir marta.
    for (final m in markersAhead) {
      if (m.distanceM > trafficLightM) continue;
      if (_markerFired.contains(m.id)) continue;
      _markerFired.add(m.id);
      _push(NavAlertEvent(
        kind: NavAlertKind.trafficLight,
        distanceM: m.distanceM,
      ));
    }
  }

  /// Burilish deb hisoblanadigan manevrmi? (`depart`/`arrive`/`continue` —
  /// yo'q; ular uchun "o'ngga/chapga" deyish mantiqsiz.)
  bool _isTurnLike(RouteStep s) {
    const skip = {'depart', 'arrive', 'continue', 'notification', 'new name'};
    if (skip.contains(s.type)) return false;
    final mod = s.modifier;
    if (mod == null || mod == 'straight') return false;
    return true;
  }

  void _push(NavAlertEvent e) {
    _queue.add(e);
    while (_queue.length > maxQueue) {
      _queue.removeAt(0); // eng eskisi — endi ahamiyatsiz
    }
  }

  /// Sovutish oynasi ruxsat bersa — navbatdan bittasini beradi.
  NavAlertEvent? _dequeue(DateTime now) {
    if (_queue.isEmpty) return null;
    final last = _lastAlertAt;
    if (last != null && now.difference(last) < cooldown) return null;
    _lastAlertAt = now;
    return _queue.removeAt(0);
  }
}
