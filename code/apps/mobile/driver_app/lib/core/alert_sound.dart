import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yangi buyurtma signali — takrorlanuvchi ovoz. plan/06-driver-app.md
/// Haydovchi qabul qilguncha (yoki oflayn/bo'sh bo'lguncha) takrorlanadi.
class AlertSound {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  bool get isPlaying => _playing;

  Future<void> start() async {
    if (_playing) return;
    _playing = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/alert.wav'));
    } catch (_) {
      // Ovoz qurilmasi mavjud bo'lmasa — jim o'tkazib yuboramiz.
      _playing = false;
    }
  }

  Future<void> stop() async {
    if (!_playing) return;
    _playing = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Bir martalik qisqa signal (navigatsiya ogohlantirishlari uchun).
  ///
  /// ALOHIDA, qisqa umrli `AudioPlayer` ishlatiladi — yangi buyurtma
  /// signalini (tsiklli `_player`) hech qachon to'xtatib/rejimini buzib
  /// qo'ymasligi uchun. Ovoz tugagach o'zi tozalanadi.
  Future<void> playOnce([String asset = 'sounds/alert.wav']) async {
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      p.onPlayerComplete.first.then((_) => p.dispose()).catchError((_) {});
      await p.play(AssetSource(asset));
    } catch (_) {
      // Ovoz qurilmasi yo'q/band — jim o'tkazamiz (navigatsiya buzilmaydi).
    }
  }

  void dispose() {
    _player.dispose();
  }
}

final alertSoundProvider = Provider<AlertSound>((ref) {
  final sound = AlertSound();
  ref.onDispose(sound.dispose);
  return sound;
});

/// Ovoz signali yoqilganmi (Ovoz va til sozlamasidan boshqariladi).
final soundEnabledProvider = StateProvider<bool>((ref) => true);
