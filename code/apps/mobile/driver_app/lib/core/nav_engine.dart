import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'nav_support.dart';

/// Turn-by-turn navigatsiya "miyasi" — SOF Dart (Flutter/Riverpod importsiz),
/// shuning uchun qurilmasiz unit-test qilinadi.
///
/// Vazifasi: marshrut geometriyasi + burilishlar (steps) + jonli GPS nuqtasi
/// asosida quyidagilarni hisoblash:
///  - haydovchining marshrutdagi proyeksiyasi (eng yaqin nuqta) va marshrut
///    bo'ylab bosib o'tilgan masofa;
///  - keyingi burilishgacha qolgan masofa (200m ogohlantirish uchun);
///  - marshrutning shu nuqtadagi yo'nalishi (xaritani burish uchun);
///  - marshrutdan chetlanish masofasi (qayta marshrutlash uchun);
///  - oldinda turgan eng yaqin svetofor belgisigacha masofa.

/// Ikki nuqta orasidagi masofa (metr) — bir joyda, izchil hisoblansin uchun.
const Distance _distance = Distance();

double _metersBetween(LatLng a, LatLng b) =>
    _distance.as(LengthUnit.Meter, a, b).toDouble();

/// `from` nuqtadan `to` nuqtaga yo'nalish (gradus, 0 = shimol, soat yo'nalishi).
double bearingDegrees(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLng = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final deg = math.atan2(y, x) * 180 / math.pi;
  return (deg + 360) % 360;
}

/// Ikki burchak orasidagi ENG QISQA farq (-180..180]. Silliq aylantirish
/// uchun — 359°→1° o'tishda uzun yo'ldan aylanib ketmasligi uchun shart.
double shortestAngleDelta(double from, double to) {
  return ((to - from + 540) % 360) - 180;
}

/// Burchaklar orasida eng qisqa yo'l bo'yicha interpolyatsiya.
double lerpAngle(double from, double to, double t) {
  return (from + shortestAngleDelta(from, to) * t) % 360;
}

/// Bitta segmentga proyeksiya natijasi.
class _Projection {
  final LatLng point;
  final double distanceToPointM; // haydovchidan proyeksiyagacha (chetlanish)
  final double alongSegmentM; // segment boshidan proyeksiyagacha
  const _Projection(this.point, this.distanceToPointM, this.alongSegmentM);
}

/// Nuqtaning [a]-[b] segmentga proyeksiyasi. Kichik masofalarda (bir necha km)
/// tekis (planar) yaqinlashtirish yetarli aniq — longitude kenglik bo'yicha
/// siqiladi.
_Projection _projectOnSegment(LatLng p, LatLng a, LatLng b) {
  final latRad = a.latitude * math.pi / 180;
  final kx = math.cos(latRad); // longitude masshtabi
  final ax = a.longitude * kx, ay = a.latitude;
  final bx = b.longitude * kx, by = b.latitude;
  final px = p.longitude * kx, py = p.latitude;

  final dx = bx - ax, dy = by - ay;
  final segLenSq = dx * dx + dy * dy;
  double t = 0;
  if (segLenSq > 0) {
    t = ((px - ax) * dx + (py - ay) * dy) / segLenSq;
    t = t.clamp(0.0, 1.0);
  }
  final proj = LatLng(ay + dy * t, (ax + dx * t) / kx);
  return _Projection(
    proj,
    _metersBetween(p, proj),
    _metersBetween(a, proj),
  );
}

/// Marshrut bo'ylab joriy holat.
class NavProgress {
  /// Marshrut boshidan hisoblangan bosib o'tilgan masofa (metr).
  final double cumulativeM;

  /// Marshrutdagi eng yaqin nuqta (yo'lga "yopishtirilgan" joylashuv).
  final LatLng projectedPoint;

  /// Haydovchidan marshrutgacha perpendikulyar masofa (metr).
  /// Katta bo'lsa — haydovchi marshrutdan chiqib ketgan.
  final double offRouteM;

  /// Marshrutning shu nuqtadagi yo'nalishi (gradus) — xaritani burish uchun.
  final double bearing;

  /// Marshrut oxirigacha qolgan masofa (metr).
  final double remainingM;

  /// Joriy qadam (step) indeksi; steps bo'lmasa -1.
  final int stepIndex;

  /// Keyingi burilishgacha qolgan masofa (metr); steps bo'lmasa null.
  final double? distanceToManeuverM;

  /// Keyingi burilish (steps bo'lmasa yoki oxirgi bo'lsa null).
  final RouteStep? nextStep;

  const NavProgress({
    required this.cumulativeM,
    required this.projectedPoint,
    required this.offRouteM,
    required this.bearing,
    required this.remainingM,
    required this.stepIndex,
    required this.distanceToManeuverM,
    required this.nextStep,
  });
}

/// Marshrut + burilishlar ustida hisob-kitob qiluvchi dvigatel.
/// [load] bilan marshrut yuklanadi, so'ng har GPS o'qishida [progress].
class NavEngine {
  /// Marshrutga "tegishli" deb hisoblanadigan maksimal chetlanish (metr).
  /// Bundan uzoqda — marshrut yo'nalishiga ishonmaymiz (xom GPS heading'ga
  /// tushamiz) va qayta marshrutlash kerakligini bildiramiz.
  static const double onRouteToleranceM = 30;

  /// Svetofor belgisi marshrutga shu masofadan yaqin bo'lsa — "shu yo'lda"
  /// deb hisoblanadi (Beshariq ko'chalari tor — qo'shni ko'chadagi svetofor
  /// chalg'itmasligi uchun ataylab tor tanlangan).
  static const double markerOnRouteToleranceM = 28;

  /// Svetoforlarni faqat shuncha masofa oldinda qidiramiz (metr) — butun
  /// tuman bo'ylab har GPS tikida skanerlamaslik uchun.
  static const double markerLookaheadM = 2000;

  List<LatLng> _points = const [];
  List<double> _cumulative = const []; // _cumulative[i] = boshdan i-nuqtagacha
  List<RouteStep> _steps = const [];

  /// Har bir qadam TUGAYDIGAN (burilish sodir bo'ladigan) joyning marshrut
  /// bo'ylab kumulyativ masofasi.
  List<double> _stepEnds = const [];

  List<LatLng> get points => _points;
  List<RouteStep> get steps => _steps;
  bool get hasRoute => _points.length >= 2;
  bool get hasSteps => _steps.isNotEmpty;
  double get totalDistanceM => _cumulative.isEmpty ? 0 : _cumulative.last;

  /// Yangi marshrut yuklash. Kumulyativ masofalar BIR MARTA hisoblanadi.
  void load(List<LatLng> points, List<RouteStep> steps) {
    _points = points;
    _steps = steps;
    if (points.length < 2) {
      _cumulative = points.isEmpty ? const [] : [0];
      _stepEnds = const [];
      return;
    }
    final cum = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      cum[i] = cum[i - 1] + _metersBetween(points[i - 1], points[i]);
    }
    _cumulative = cum;
    // Qadam chegaralari: har bir qadam o'z uzunligi bilan tugaydi.
    final ends = <double>[];
    var acc = 0.0;
    for (final s in steps) {
      acc += s.distanceMeters;
      ends.add(acc);
    }
    _stepEnds = ends;
  }

  void clear() {
    _points = const [];
    _cumulative = const [];
    _steps = const [];
    _stepEnds = const [];
  }

  /// Joriy GPS nuqtasi bo'yicha marshrutdagi holatni hisoblaydi.
  /// Marshrut yo'q bo'lsa — null.
  NavProgress? progress(LatLng fix) {
    if (!hasRoute) return null;

    // Barcha segmentlar bo'ylab eng yaqin proyeksiyani topamiz. Marshrutlar
    // tuman miqyosida (yuzlab nuqta) — O(n) yetarli tez. Agar kelajakda ancha
    // uzun marshrutlar paydo bo'lsa, oxirgi topilgan segment atrofidagi
    // oynani skanerlash bilan optimallashtirish mumkin (harakat monoton).
    var bestIdx = 0;
    _Projection? best;
    for (var i = 0; i < _points.length - 1; i++) {
      final pr = _projectOnSegment(fix, _points[i], _points[i + 1]);
      if (best == null || pr.distanceToPointM < best.distanceToPointM) {
        best = pr;
        bestIdx = i;
      }
    }
    if (best == null) return null;

    final cumulative = _cumulative[bestIdx] + best.alongSegmentM;
    final remaining = (totalDistanceM - cumulative).clamp(0.0, double.infinity);

    // Yo'nalish: joriy segmentning yo'nalishi (yo'lga yopishtirilgani uchun
    // xom GPS heading'dan ancha barqaror).
    final bearing = bearingDegrees(_points[bestIdx], _points[bestIdx + 1]);

    // Keyingi burilish: kumulyativ masofa qaysi qadam ichida ekanini topamiz.
    int stepIndex = -1;
    double? toManeuver;
    RouteStep? next;
    if (_stepEnds.isNotEmpty) {
      stepIndex = _stepEnds.indexWhere((end) => end > cumulative);
      if (stepIndex < 0) {
        stepIndex = _stepEnds.length - 1; // oxirgi qadam ichidamiz
      }
      toManeuver =
          (_stepEnds[stepIndex] - cumulative).clamp(0.0, double.infinity);
      // Burilish — SHU qadam tugaganda sodir bo'ladi, ya'ni KEYINGI qadam
      // boshlanishidagi manevr. OSRM'da har bir step o'z boshidagi manevrni
      // saqlaydi, shuning uchun keyingisini olamiz.
      if (stepIndex + 1 < _steps.length) {
        next = _steps[stepIndex + 1];
      }
    }

    return NavProgress(
      cumulativeM: cumulative,
      projectedPoint: best.point,
      offRouteM: best.distanceToPointM,
      bearing: bearing,
      remainingM: remaining,
      stepIndex: stepIndex,
      distanceToManeuverM: toManeuver,
      nextStep: next,
    );
  }

  /// Oldinda (orqada emas) turgan, marshrutga yaqin belgilar — har biri uchun
  /// marshrut bo'ylab qolgan masofa. Svetofor ogohlantirishi uchun.
  ///
  /// [markers] — (id, joylashuv) juftliklari; id ogohlantirish bir marta
  /// berilishini ta'minlash uchun ishlatiladi.
  List<MarkerAhead> markersAhead(
    List<({String id, LatLng pos})> markers,
    NavProgress progress,
  ) {
    if (!hasRoute || markers.isEmpty) return const [];
    final out = <MarkerAhead>[];
    for (final m in markers) {
      // Belgining marshrutdagi proyeksiyasi.
      var bestIdx = 0;
      _Projection? best;
      for (var i = 0; i < _points.length - 1; i++) {
        final pr = _projectOnSegment(m.pos, _points[i], _points[i + 1]);
        if (best == null || pr.distanceToPointM < best.distanceToPointM) {
          best = pr;
          bestIdx = i;
        }
      }
      if (best == null) continue;
      // Marshrutdan uzoq — boshqa ko'chadagi belgi, e'tiborga olinmaydi.
      if (best.distanceToPointM > markerOnRouteToleranceM) continue;
      final markerCum = _cumulative[bestIdx] + best.alongSegmentM;
      final ahead = markerCum - progress.cumulativeM;
      // Orqada qolган yoki juda uzoq — o'tkazib yuboramiz.
      if (ahead <= 0 || ahead > markerLookaheadM) continue;
      out.add(MarkerAhead(m.id, ahead));
    }
    out.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return out;
  }
}

/// Oldinda turgan belgi + unga qolgan masofa (marshrut bo'ylab).
class MarkerAhead {
  final String id;
  final double distanceM;
  const MarkerAhead(this.id, this.distanceM);
}
