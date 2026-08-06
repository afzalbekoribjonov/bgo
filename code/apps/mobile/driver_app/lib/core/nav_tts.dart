import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Navigatsiya uchun ovozli yo'l-yo'riq (TTS).
///
/// MUHIM: aksariyat Android/iOS TTS dvigatellari `uz-UZ` tilini QO'LLAMAYDI.
/// Shuning uchun zanjir: uz-UZ → ru-RU → (umuman gapirmaydi, faqat tovushli
/// signal qoladi). Hech qanday holatda XATO BERMAYDI va navigatsiyani
/// to'xtatmaydi — ovoz shunchaki qo'shimcha qulaylik.
class NavTts {
  final FlutterTts _tts = FlutterTts();

  bool _initTried = false;

  /// Qaysi til muvaffaqiyatli o'rnatildi: 'uz' | 'ru' | null (ovoz yo'q).
  String? _lang;

  String? get language => _lang;
  bool get usable => _lang != null;

  /// Dvigatelni tayyorlaydi. Bir marta, birinchi navigatsiya boshlanganда
  /// chaqiriladi (ilova ochilishida emas — sovuq start sekinlashmasin).
  Future<void> init() async {
    if (_initTried) return;
    _initTried = true;
    try {
      // Ovoz o'ynayotganda kutib turmaymiz — ogohlantirishlar navbat bilan
      // emas, "aytdi-ketdi" tarzda berilishi kerak.
      await _tts.setSpeechRate(0.48); // sekinroq — yo'lda tushunarli bo'lsin
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      for (final candidate in const ['uz-UZ', 'ru-RU']) {
        try {
          final ok = await _tts.isLanguageAvailable(candidate);
          if (ok == true) {
            await _tts.setLanguage(candidate);
            _lang = candidate.startsWith('uz') ? 'uz' : 'ru';
            return;
          }
        } catch (_) {
          // Bu til bilan muammo — keyingisini sinaymiz.
        }
      }
      _lang = null; // mos til yo'q — jim rejim
    } catch (_) {
      _lang = null;
    }
  }

  /// Matnni ovozli aytadi. Dvigatel yo'q/til topilmagan bo'lsa — jim o'tadi.
  ///
  /// Matn TTS dvigateli TILIGA mos tayyorlangan bo'lishi kerak
  /// ([language] qiymatiga qarab) — ingliz tiliga tushib qolmaymiz,
  /// haydovchiga tushunarsiz tilda gapirgandan ko'ra jim turgan afzal.
  Future<void> speak(String text) async {
    if (!_initTried) await init();
    if (_lang == null || text.isEmpty) return;
    try {
      await _tts.stop(); // oldingi (eskirgan) ogohlantirishni uzamiz
      await _tts.speak(text);
    } catch (_) {
      // Ovoz chiqmadi — navigatsiya davom etaveradi.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

final navTtsProvider = Provider<NavTts>((ref) {
  final tts = NavTts();
  ref.onDispose(tts.stop);
  return tts;
});
