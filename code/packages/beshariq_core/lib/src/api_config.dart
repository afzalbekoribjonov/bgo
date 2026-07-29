/// Backend manzili. plan/14-api-design.md
///
/// Android emulyatorida `10.0.2.2` — host kompyuterning `localhost`i.
/// Haqiqiy qurilmada (telefon) bu serverning IP/domeniga o'zgaradi.
/// Build vaqtida override: `flutter run --dart-define=API_BASE_URL=https://...`
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api/v1',
  );

  static const Duration timeout = Duration(seconds: 12);

  /// Oshxona paneli (restaurant_web) manzili — "Mening oshxonam" WebView uchun.
  /// Override: `--dart-define=PANEL_BASE_URL=https://panel.beshariq.uz`.
  /// Aks holda API bazasidan hosil qilinadi (`:4000/api/v1` -> `:3100`).
  static String get panelBaseUrl {
    const override =
        String.fromEnvironment('PANEL_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    var s = baseUrl;
    final api = s.indexOf('/api');
    if (api >= 0) s = s.substring(0, api);
    return s.replaceFirst(':4000', ':3100');
  }

  /// Beshariq Market saytining manzili (market_web) — "Beshariq Market"
  /// WebView tugmasi uchun. Override: `--dart-define=MARKET_BASE_URL=...`.
  static String get marketBaseUrl {
    const override =
        String.fromEnvironment('MARKET_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    var s = baseUrl;
    final api = s.indexOf('/api');
    if (api >= 0) s = s.substring(0, api);
    return s.replaceFirst(':4000', ':3300');
  }

  /// Do'konlar/Qurilishda foydali saytining manzili (shops_web) — Faza B.
  /// Override: `--dart-define=SHOPS_BASE_URL=...`.
  static String get shopsBaseUrl {
    const override =
        String.fromEnvironment('SHOPS_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;
    var s = baseUrl;
    final api = s.indexOf('/api');
    if (api >= 0) s = s.substring(0, api);
    return s.replaceFirst(':4000', ':3400');
  }
}
