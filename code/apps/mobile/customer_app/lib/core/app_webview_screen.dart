import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Umumiy WebView ekran — ilova ichida tashqi mini-sayt (Market/Do'konlar/
/// oshxona paneli) ochish uchun. Token URL orqali uzatiladi (?token=...) —
/// sayt uni o'qib avtomatik kiradi (qayta login talab qilinmaydi).
class AppWebViewScreen extends StatefulWidget {
  final String baseUrl; // masalan http://localhost:3300
  final String? token; // bo'lmasa — ko'rish rejimida ochiladi
  final String title;
  final IconData loadingIcon;
  final String loadingLabel;

  const AppWebViewScreen({
    super.key,
    required this.baseUrl,
    required this.title,
    this.token,
    this.loadingIcon = Icons.storefront_rounded,
    this.loadingLabel = 'Yuklanmoqda…',
  });

  /// Sayt bo'yicha keshlangan WebViewController'lar — bir bo'lim (Market/
  /// Do'konlar/Qurilish) qayta ochilganda sahifa noldan yuklanmasin, oldingi
  /// holati (skroll, JS holati, sessionStorage) saqlanib, darhol ko'rinsin.
  /// Kirish o'zgarganda (logout) [clearCache] chaqiriladi.
  static final Map<String, WebViewController> _cache = {};
  static const int _maxCacheEntries = 4;

  /// Foydalanuvchi tizimdan chiqganda chaqiriladi — boshqa hisobning
  /// sessiyasi keshda qolib ketmasligi uchun.
  static void clearCache() => _cache.clear();

  @override
  State<AppWebViewScreen> createState() => _AppWebViewScreenState();
}

class _AppWebViewScreenState extends State<AppWebViewScreen> {
  late final WebViewController _controller;
  late final bool _fromCache;
  int _progress = 0;
  bool _hasError = false;

  String get _cacheKey => widget.baseUrl.replaceAll(RegExp(r'/+$'), '');

  Uri get _url {
    final base = widget.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final token = widget.token;
    if (token == null || token.isEmpty) return Uri.parse('$base/');
    return Uri.parse('$base/?token=${Uri.encodeComponent(token)}');
  }

  @override
  void initState() {
    super.initState();
    final cached = AppWebViewScreen._cache[_cacheKey];
    _fromCache = cached != null;
    if (cached != null) {
      _controller = cached;
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white);
    }
    // Har mount'da delegate qayta ulanadi — eski (dispose bo'lgan) State'ga
    // ishora qilib qolmasin.
    _controller.setNavigationDelegate(NavigationDelegate(
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onPageStarted: (_) {
        if (mounted) setState(() => _hasError = false);
      },
      onWebResourceError: (error) {
        // Faqat asosiy sahifa xatosi — rasm/shrift kabi kichik so'rovlar emas.
        if (mounted && error.isForMainFrame != false) {
          setState(() => _hasError = true);
        }
      },
    ));
    // JS bridge: sayt ichidan (masalan market_web'ning "Uy" tugmasi)
    // `window.NativeApp.postMessage('home')` chaqirib, asosiy ekranga
    // qaytishni so'raydi. Delegate kabi har mount'da qayta ro'yxatdan
    // o'tkaziladi — kesh'dagi controller eski (dispose bo'lgan) State'ga
    // ishora qilib qolmasligi uchun (kanal keshlangan controller'da
    // allaqachon bor bo'lsa, avval olib tashlanadi).
    () async {
      try {
        await _controller.removeJavaScriptChannel('NativeApp');
      } catch (_) {}
      await _controller.addJavaScriptChannel(
        'NativeApp',
        onMessageReceived: (message) {
          if (message.message == 'home' && mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      );
    }();
    if (_fromCache) {
      // Sahifa allaqachon yuklangan — qayta so'rovsiz darhol ko'rsatiladi.
      _progress = 100;
    } else {
      _controller.loadRequest(_url);
      final cache = AppWebViewScreen._cache;
      if (cache.length >= AppWebViewScreen._maxCacheEntries) {
        cache.remove(cache.keys.first);
      }
      cache[_cacheKey] = _controller;
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(_url);
  }

  /// Android tizim orqaga tugmasi: avval saytning o'z ichki tarixi bo'ylab
  /// orqaga qaytadi (masalan mahsulot detali -> ro'yxat); faqat sayt ichida
  /// orqaga borish joyi qolmaganda ekran yopiladi. Shu bilan "orqaga
  /// tugmasi yo'q sahifada bosh ekranga uchib ketish" muammosi tuzatiladi.
  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loading = _progress < 100 && !_hasError;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Orqaga',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          title: Text(widget.title),
          actions: [
            IconButton(
              tooltip: 'Yangilash',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _retry,
            ),
          ],
          bottom: loading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 3,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),

            // Brendlangan yuklanish ekrani — sayt ochilguncha bo'sh oq
            // ekran ko'rinmasin.
            if (loading)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.loadingIcon,
                            color: scheme.primary, size: 32),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation(scheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.loadingLabel,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Ulanish xatosi — bo'sh/buzilgan sahifa o'rniga tushunarli holat.
            if (_hasError)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: scheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.wifi_off_rounded,
                            size: 34, color: scheme.error),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Ulanib bo'lmadi",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sahifaga ulanishda xatolik yuz berdi. Internet aloqasini tekshirib qayta urining.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Qayta urinish'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
