import 'package:flutter/material.dart';

import '../core/nav_alert_state.dart';
import '../l10n/generated/app_localizations.dart';

/// OSRM burilish turiga mos ikonka.
IconData maneuverIcon(NavAlertEvent e) {
  switch (e.kind) {
    case NavAlertKind.trafficLight:
      return Icons.traffic_rounded;
    case NavAlertKind.straight:
      return Icons.straight_rounded;
    case NavAlertKind.turn:
      switch (e.modifier) {
        case 'left':
          return Icons.turn_left_rounded;
        case 'right':
          return Icons.turn_right_rounded;
        case 'sharp left':
          return Icons.turn_sharp_left_rounded;
        case 'sharp right':
          return Icons.turn_sharp_right_rounded;
        case 'slight left':
          return Icons.turn_slight_left_rounded;
        case 'slight right':
          return Icons.turn_slight_right_rounded;
        case 'uturn':
          return Icons.u_turn_left_rounded;
        default:
          return Icons.roundabout_left_rounded;
      }
  }
}

/// Burilish yo'nalishining tarjimasi ("O'ngga", "Chapga", ...).
String maneuverDirectionText(AppLocalizations t, String? modifier) {
  switch (modifier) {
    case 'left':
      return t.navTurnLeft;
    case 'right':
      return t.navTurnRight;
    case 'sharp left':
      return t.navTurnSharpLeft;
    case 'sharp right':
      return t.navTurnSharpRight;
    case 'slight left':
      return t.navTurnSlightLeft;
    case 'slight right':
      return t.navTurnSlightRight;
    case 'uturn':
      return t.navTurnUturn;
    default:
      return t.navTurnRoundabout;
  }
}

/// Bannerda ko'rinadigan matn.
String maneuverBannerText(AppLocalizations t, NavAlertEvent e) {
  switch (e.kind) {
    case NavAlertKind.turn:
      return t.navTurnBanner(
        e.distanceM.round(),
        maneuverDirectionText(t, e.modifier),
      );
    case NavAlertKind.straight:
      return t.navStraightBanner(e.distanceKmRounded);
    case NavAlertKind.trafficLight:
      return t.navTrafficLightBanner;
  }
}

/// TTS uchun aytiladigan matn. [t] — TTS dvigatelining TILIGA mos
/// lokalizatsiya (ilova interfeysi tilidan mustaqil: dvigatel `ru-RU`da
/// ishlayotgan bo'lsa, ruscha matn aytiladi).
String maneuverSpeechText(AppLocalizations t, NavAlertEvent e) {
  switch (e.kind) {
    case NavAlertKind.turn:
      return t.navSpeakTurn(
        e.distanceM.round(),
        maneuverDirectionText(t, e.modifier),
      );
    case NavAlertKind.straight:
      return t.navSpeakStraight(e.distanceKmRounded);
    case NavAlertKind.trafficLight:
      return t.navSpeakTrafficLight;
  }
}

/// Xarita yuqorisida, o'rtada chiqadigan navigatsiya ogohlantirishi.
///
/// Ataylab KICHIK va o'tkinchi: yangi buyurtma banneri (`_orderBanner`) yoki
/// faol safar paneli bilan raqobatlashmasligi kerak. Bosishni ushlamaydi
/// (`IgnorePointer`) — xaritaga tegishli teginishlar to'sib qolmaydi.
class ManeuverBanner extends StatelessWidget {
  final NavAlertEvent event;
  const ManeuverBanner({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isTrafficLight = event.kind == NavAlertKind.trafficLight;
    final accent =
        isTrafficLight ? const Color(0xFF2F9E44) : const Color(0xFFFFC107);

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(maneuverIcon(event), size: 22, color: accent),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                maneuverBannerText(t, event),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
