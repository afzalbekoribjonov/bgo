import 'package:driver_app/core/nav_engine.dart';
import 'package:driver_app/core/nav_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// NavEngine — sof Dart, shuning uchun qurilmasiz/emulyatorsiz sinaladi.
/// Bu testlar navigatsiyaning eng nozik matematikasini qamrab oladi:
/// proyeksiya, marshrut bo'ylab masofa, burilishgacha qolgan masofa va
/// svetofor belgilarini oldinda/orqada ajratish.
void main() {
  // Beshariq atrofidagi taxminiy koordinatalar. Kenglik ~40.42° —
  // 1 daraja longitude ≈ 84.8 km, 1 daraja latitude ≈ 111.3 km.
  const start = LatLng(40.4200, 70.6000);

  /// Sharqqa qarab to'g'ri chiziq (longitude bo'yicha) yasaydi.
  List<LatLng> eastLine(int count, double stepDeg) => [
        for (var i = 0; i < count; i++)
          LatLng(start.latitude, start.longitude + stepDeg * i),
      ];

  group('bearing va burchak yordamchilari', () {
    test('sharqqa yo\'nalish ~90 gradus', () {
      final b = bearingDegrees(start, LatLng(start.latitude, start.longitude + 0.01));
      expect(b, closeTo(90, 1));
    });

    test('shimolga yo\'nalish ~0 gradus', () {
      final b = bearingDegrees(start, LatLng(start.latitude + 0.01, start.longitude));
      expect(b, closeTo(0, 1));
    });

    test('shortestAngleDelta 350->10 orasida +20 (qisqa yo\'l)', () {
      expect(shortestAngleDelta(350, 10), closeTo(20, 0.001));
    });

    test('shortestAngleDelta 10->350 orasida -20 (qisqa yo\'l)', () {
      expect(shortestAngleDelta(10, 350), closeTo(-20, 0.001));
    });

    test('lerpAngle 0/360 chegarasidan qisqa yo\'l bilan o\'tadi', () {
      // 350 dan 10 ga yarim yo'l = 0 (yoki 360) — 180 EMAS.
      final mid = lerpAngle(350, 10, 0.5);
      final distTo0 = shortestAngleDelta(mid, 0).abs();
      expect(distTo0, lessThan(0.001));
    });
  });

  group('NavEngine — proyeksiya va marshrut bo\'ylab masofa', () {
    test('marshrutsiz progress null qaytaradi', () {
      final e = NavEngine();
      expect(e.progress(start), isNull);
      expect(e.hasRoute, isFalse);
    });

    test('marshrut ustidagi nuqta uchun chetlanish ~0', () {
      final e = NavEngine()..load(eastLine(5, 0.001), const []);
      final onRoute = LatLng(start.latitude, start.longitude + 0.0015);
      final p = e.progress(onRoute)!;
      expect(p.offRouteM, lessThan(5));
    });

    test('kumulyativ masofa marshrut bo\'ylab o\'sadi', () {
      final e = NavEngine()..load(eastLine(5, 0.001), const []);
      final near = e.progress(LatLng(start.latitude, start.longitude + 0.0005))!;
      final far = e.progress(LatLng(start.latitude, start.longitude + 0.0035))!;
      expect(far.cumulativeM, greaterThan(near.cumulativeM));
      // 0.003 daraja longitude ≈ 254 m shu kenglikda.
      expect(far.cumulativeM - near.cumulativeM, closeTo(254, 30));
    });

    test('marshrutdan yon tomonga chiqqan nuqtada offRouteM katta', () {
      final e = NavEngine()..load(eastLine(5, 0.001), const []);
      // ~0.001 daraja latitude ≈ 111 m shimolga.
      final off = LatLng(start.latitude + 0.001, start.longitude + 0.002);
      final p = e.progress(off)!;
      expect(p.offRouteM, greaterThan(NavEngine.onRouteToleranceM));
      expect(p.offRouteM, closeTo(111, 15));
    });

    test('sharqqa yo\'nalgan marshrutda bearing ~90', () {
      final e = NavEngine()..load(eastLine(5, 0.001), const []);
      final p = e.progress(LatLng(start.latitude, start.longitude + 0.002))!;
      expect(p.bearing, closeTo(90, 2));
    });

    test('qolgan masofa marshrut oxiriga yaqinlashganda kamayadi', () {
      final pts = eastLine(5, 0.001);
      final e = NavEngine()..load(pts, const []);
      final atStart = e.progress(pts.first)!;
      final atEnd = e.progress(pts.last)!;
      expect(atStart.remainingM, greaterThan(atEnd.remainingM));
      expect(atEnd.remainingM, lessThan(5));
    });

    test('clear() marshrutni tozalaydi', () {
      final e = NavEngine()..load(eastLine(3, 0.001), const []);
      expect(e.hasRoute, isTrue);
      e.clear();
      expect(e.hasRoute, isFalse);
      expect(e.progress(start), isNull);
    });
  });

  group('NavEngine — burilishlar (steps)', () {
    // Ikkita qadam: 200 m to'g'ri, so'ng o'ngga burilib yana 200 m.
    List<RouteStep> twoSteps() => [
          RouteStep(
            type: 'depart',
            modifier: null,
            distanceMeters: 200,
            durationSeconds: 30,
            location: start,
          ),
          RouteStep(
            type: 'turn',
            modifier: 'right',
            distanceMeters: 200,
            durationSeconds: 30,
            location: LatLng(start.latitude, start.longitude + 0.00236),
          ),
        ];

    test('steps bo\'lmasa distanceToManeuverM null', () {
      final e = NavEngine()..load(eastLine(6, 0.001), const []);
      final p = e.progress(start)!;
      expect(p.distanceToManeuverM, isNull);
      expect(p.nextStep, isNull);
      expect(e.hasSteps, isFalse);
    });

    test('boshda birinchi burilishgacha ~200 m qoladi', () {
      final e = NavEngine()..load(eastLine(6, 0.001), twoSteps());
      final p = e.progress(start)!;
      expect(p.stepIndex, 0);
      expect(p.distanceToManeuverM, closeTo(200, 20));
      // Keyingi manevr — o'ngga burilish.
      expect(p.nextStep?.modifier, 'right');
    });

    test('oldinga siljiganda burilishgacha masofa kamayadi', () {
      final pts = eastLine(6, 0.001);
      final e = NavEngine()..load(pts, twoSteps());
      final early = e.progress(pts[0])!;
      final later = e.progress(pts[2])!;
      expect(later.distanceToManeuverM!, lessThan(early.distanceToManeuverM!));
    });

    test('burilishdan o\'tgach keyingi qadamga o\'tadi', () {
      final pts = eastLine(6, 0.001);
      final e = NavEngine()..load(pts, twoSteps());
      // ~340 m — birinchi qadam (200 m) tugagan.
      final p = e.progress(pts[4])!;
      expect(p.stepIndex, 1);
    });
  });

  group('NavEngine — oldindagi svetofor belgilari', () {
    test('marshrutdagi oldingi belgi topiladi, orqadagisi yo\'q', () {
      final pts = eastLine(11, 0.001); // ~850 m sharqqa
      final e = NavEngine()..load(pts, const []);
      // Haydovchi ~4-nuqtada.
      final p = e.progress(pts[4])!;
      final markers = <({String id, LatLng pos})>[
        // Oldinda, marshrut ustida (7-nuqta).
        (id: 'ahead', pos: pts[7]),
        // Orqada, marshrut ustida (1-nuqta).
        (id: 'behind', pos: pts[1]),
      ];
      final res = e.markersAhead(markers, p);
      expect(res.map((m) => m.id), contains('ahead'));
      expect(res.map((m) => m.id), isNot(contains('behind')));
    });

    test('marshrutdan uzoq (qo\'shni ko\'chadagi) belgi e\'tiborga olinmaydi', () {
      final pts = eastLine(11, 0.001);
      final e = NavEngine()..load(pts, const []);
      final p = e.progress(pts[2])!;
      // ~111 m shimolda — tolerantlikdan (28 m) ancha uzoq.
      final far = LatLng(pts[6].latitude + 0.001, pts[6].longitude);
      final res = e.markersAhead([(id: 'parallel', pos: far)], p);
      expect(res, isEmpty);
    });

    test('juda uzoqdagi (lookahead tashqarisidagi) belgi qaytarilmaydi', () {
      // ~4.2 km sharqqa cho'zilgan marshrut.
      final pts = eastLine(51, 0.001);
      final e = NavEngine()..load(pts, const []);
      final p = e.progress(pts[0])!;
      // Oxirgi nuqta ~4.2 km — 2 km lookahead'dan tashqarida.
      final res = e.markersAhead([(id: 'faraway', pos: pts[50])], p);
      expect(res, isEmpty);
    });

    test('bir nechta belgi masofa bo\'yicha saralanadi (yaqini birinchi)', () {
      final pts = eastLine(21, 0.001);
      final e = NavEngine()..load(pts, const []);
      final p = e.progress(pts[1])!;
      final res = e.markersAhead([
        (id: 'far', pos: pts[15]),
        (id: 'near', pos: pts[5]),
      ], p);
      expect(res.first.id, 'near');
      expect(res.last.id, 'far');
      expect(res.first.distanceM, lessThan(res.last.distanceM));
    });
  });
}
