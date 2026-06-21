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

  void dispose() {
    _player.dispose();
  }
}

final alertSoundProvider = Provider<AlertSound>((ref) {
  final sound = AlertSound();
  ref.onDispose(sound.dispose);
  return sound;
});
