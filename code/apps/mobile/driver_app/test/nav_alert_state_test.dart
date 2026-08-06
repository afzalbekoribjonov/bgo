import 'package:driver_app/core/nav_alert_state.dart';
import 'package:driver_app/core/nav_engine.dart';
import 'package:driver_app/core/nav_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Ogohlantirish holat mashinasi — eng nozik joyi "bir marta beriladi"
/// mantig'i. Bu testlar takrorlanish/bosib ketish holatlarini qamrab oladi.
void main() {
  const p0 = LatLng(40.42, 70.60);

  NavProgress prog({
    required int stepIndex,
    double? toManeuver,
    RouteStep? next,
    double cumulative = 0,
  }) =>
      NavProgress(
        cumulativeM: cumulative,
        projectedPoint: p0,
        offRouteM: 2,
        bearing: 90,
        remainingM: 1000,
        stepIndex: stepIndex,
        distanceToManeuverM: toManeuver,
        nextStep: next,
      );

  RouteStep step({
    String type = 'turn',
    String? modifier = 'right',
    double distance = 300,
  }) =>
      RouteStep(
        type: type,
        modifier: modifier,
        distanceMeters: distance,
        durationSeconds: 30,
        location: p0,
      );

  group('burilish ogohlantirishi', () {
    test('200 m dan uzoqda ogohlantirish yo\'q', () {
      final t = NavAlertTracker();
      final e = t.tick(
        prog(stepIndex: 0, toManeuver: 400, next: step()),
        [step(), step()],
        const [],
        now: DateTime(2026),
      );
      expect(e, isNull);
    });

    test('200 m ga yetganda bir marta beriladi', () {
      final t = NavAlertTracker();
      final e = t.tick(
        prog(stepIndex: 0, toManeuver: 190, next: step()),
        [step(), step()],
        const [],
        now: DateTime(2026),
      );
      expect(e, isNotNull);
      expect(e!.kind, NavAlertKind.turn);
      expect(e.modifier, 'right');
    });

    test('keyingi tiklarda TAKRORLANMAYDI (edge-triggered)', () {
      final t = NavAlertTracker();
      final steps = [step(), step()];
      final first = t.tick(prog(stepIndex: 0, toManeuver: 190, next: step()),
          steps, const [], now: DateTime(2026));
      expect(first, isNotNull);
      // Sovutishdan keyin ham qayta berilmasligi kerak.
      final second = t.tick(prog(stepIndex: 0, toManeuver: 150, next: step()),
          steps, const [], now: DateTime(2026, 1, 1, 0, 1));
      final third = t.tick(prog(stepIndex: 0, toManeuver: 90, next: step()),
          steps, const [], now: DateTime(2026, 1, 1, 0, 2));
      expect(second, isNull);
      expect(third, isNull);
    });

    test('"arrive"/"depart" uchun burilish ogohlantirishi berilmaydi', () {
      final t = NavAlertTracker();
      final arrive = step(type: 'arrive', modifier: null);
      final e = t.tick(prog(stepIndex: 0, toManeuver: 100, next: arrive),
          [step(), arrive], const [], now: DateTime(2026));
      expect(e, isNull);
    });

    test('modifier "straight" bo\'lsa burilish deb hisoblanmaydi', () {
      final t = NavAlertTracker();
      final s = step(modifier: 'straight');
      final e = t.tick(prog(stepIndex: 0, toManeuver: 100, next: s),
          [step(), s], const [], now: DateTime(2026));
      expect(e, isNull);
    });
  });

  group('uzoq to\'g\'ri yo\'l ogohlantirishi', () {
    test('2 km dan uzun qadam boshlanganda beriladi', () {
      final t = NavAlertTracker();
      final long = step(distance: 3000, modifier: null, type: 'continue');
      final e = t.tick(prog(stepIndex: 0), [long], const [],
          now: DateTime(2026));
      expect(e, isNotNull);
      expect(e!.kind, NavAlertKind.straight);
      expect(e.distanceKmRounded, 3);
    });

    test('qisqa qadamda berilmaydi', () {
      final t = NavAlertTracker();
      final short = step(distance: 500, modifier: null, type: 'continue');
      final e = t.tick(prog(stepIndex: 0), [short], const [],
          now: DateTime(2026));
      expect(e, isNull);
    });

    test('bir xil qadam ichida takrorlanmaydi', () {
      final t = NavAlertTracker();
      final long = step(distance: 3000, modifier: null, type: 'continue');
      final first =
          t.tick(prog(stepIndex: 0), [long], const [], now: DateTime(2026));
      final second = t.tick(prog(stepIndex: 0, cumulative: 500), [long],
          const [], now: DateTime(2026, 1, 1, 0, 5));
      expect(first, isNotNull);
      expect(second, isNull);
    });
  });

  group('svetofor ogohlantirishi', () {
    test('yaqinlashganda bir marta beriladi', () {
      final t = NavAlertTracker();
      final e = t.tick(prog(stepIndex: -1), const [],
          [const MarkerAhead('tl-1', 120)], now: DateTime(2026));
      expect(e, isNotNull);
      expect(e!.kind, NavAlertKind.trafficLight);
    });

    test('uzoqda bo\'lsa berilmaydi', () {
      final t = NavAlertTracker();
      final e = t.tick(prog(stepIndex: -1), const [],
          [const MarkerAhead('tl-1', 900)], now: DateTime(2026));
      expect(e, isNull);
    });

    test('bir xil belgi uchun takrorlanmaydi', () {
      final t = NavAlertTracker();
      final first = t.tick(prog(stepIndex: -1), const [],
          [const MarkerAhead('tl-1', 120)], now: DateTime(2026));
      final second = t.tick(prog(stepIndex: -1), const [],
          [const MarkerAhead('tl-1', 60)], now: DateTime(2026, 1, 1, 0, 1));
      expect(first, isNotNull);
      expect(second, isNull);
    });
  });

  group('sovutish (cooldown) va navbat', () {
    test('ketma-ket ikki ogohlantirish bir vaqtda berilmaydi', () {
      final t = NavAlertTracker();
      final long = step(distance: 3000, modifier: null, type: 'continue');
      // Bir tikda ham "uzoq to'g'ri yo'l", ham svetofor paydo bo'ladi.
      final first = t.tick(prog(stepIndex: 0), [long],
          [const MarkerAhead('tl-1', 100)], now: DateTime(2026));
      expect(first, isNotNull);
      // Darhol keyingi tik — sovutish tufayli hali null.
      final immediate = t.tick(prog(stepIndex: 0), [long], const [],
          now: DateTime(2026, 1, 1, 0, 0, 1));
      expect(immediate, isNull);
    });

    test('sovutishdan keyin navbatdagisi beriladi (yo\'qolmaydi)', () {
      final t = NavAlertTracker();
      final long = step(distance: 3000, modifier: null, type: 'continue');
      t.tick(prog(stepIndex: 0), [long], [const MarkerAhead('tl-1', 100)],
          now: DateTime(2026));
      // 6 soniyadan keyin — navbatdagi ikkinchisi chiqadi.
      final later = t.tick(prog(stepIndex: 0), [long], const [],
          now: DateTime(2026, 1, 1, 0, 0, 6));
      expect(later, isNotNull);
    });
  });

  group('reset', () {
    test('yangi marshrutda ogohlantirishlar qaytadan beriladi', () {
      final t = NavAlertTracker();
      final steps = [step(), step()];
      final first = t.tick(prog(stepIndex: 0, toManeuver: 190, next: step()),
          steps, const [], now: DateTime(2026));
      expect(first, isNotNull);
      t.reset();
      final afterReset = t.tick(
          prog(stepIndex: 0, toManeuver: 190, next: step()), steps, const [],
          now: DateTime(2026, 1, 1, 0, 1));
      expect(afterReset, isNotNull);
    });
  });
}
