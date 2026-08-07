import 'package:flutter/material.dart';

/// Ilova darajasidagi navigatsiya kaliti — push-bildirishnoma handler'i kabi
/// widget daraxti tashqarisidagi kod uchun (masalan `auth_gate.dart`dagi FCM
/// "bosildi" tinglovchisi), `BuildContext`siz sahifaga o'tish imkonini beradi.
final navigatorKey = GlobalKey<NavigatorState>();
