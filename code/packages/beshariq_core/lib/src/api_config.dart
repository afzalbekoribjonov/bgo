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
}
