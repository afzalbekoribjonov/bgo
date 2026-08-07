import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'panel_token_cache.dart';
import 'token_storage.dart';

/// Joriy til (UI + Accept-Language header). plan/13-localization.md
final localeProvider = StateProvider<Locale>((ref) => const Locale('uz'));

/// Locale -> backend "Accept-Language" qiymati.
String localeToHeader(Locale locale) {
  if (locale.scriptCode == 'Cyrl') return 'uz-Cyrl';
  return locale.languageCode; // uz | ru
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Sozlangan Dio: base URL, timeout, har so'rovga token va til qo'shadi.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccess();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept-Language'] = localeToHeader(ref.read(localeProvider));
        handler.next(options);
      },
    ),
  );
  return dio;
});

/// "Mening oshxonam" (hamkor) paneli uchun Dio — `restaurant` rolli, alohida
/// (mijoz sessiya tokenidan farqli) JWT bilan ishlaydi.
final kitchenDioProvider = Provider<Dio>(
  (ref) => _panelDio(ref, panelType: 'kitchen', mintPath: '/restaurants/my-kitchen'),
);

/// "Mening do'konim" (hamkor) paneli uchun Dio — `seller` rolli, alohida JWT.
final sellerDioProvider = Provider<Dio>(
  (ref) => _panelDio(ref, panelType: 'seller', mintPath: '/marketplace/my-shop'),
);

/// Hamkor panellari (kitchen/seller) uchun umumiy Dio quruvchisi. Token
/// mavjud/amal qilayotgan bo'lsa keshdan, aks holda `mintPath`ni mijozning
/// o'z sessiyasi bilan chaqirib SOKIN yangi token oladi (foydalanuvchi
/// hech qachon buni sezmaydi — qayta login/tekshirish so'ralmaydi).
/// 401 kelsa BIR MARTA qayta urinadi (token muddati kutilganidan oldin
/// tugagan holatlar uchun himoya).
Dio _panelDio(Ref ref, {required String panelType, required String mintPath}) {
  final cache = PanelTokenCache(panelType);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
    ),
  );

  Future<String?> mintToken() async {
    try {
      final res = await ref.read(dioProvider).get(mintPath);
      final data = res.data['data'] as Map<String, dynamic>?;
      final token = data?['accessToken'] as String?;
      if (token != null) await cache.save(token);
      return token;
    } catch (_) {
      return null;
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        var token = await cache.readToken();
        token ??= await mintToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        options.headers['Accept-Language'] = localeToHeader(ref.read(localeProvider));
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final fresh = await mintToken();
          if (fresh != null) {
            final req = error.requestOptions;
            req.headers['Authorization'] = 'Bearer $fresh';
            try {
              final retried = await dio.fetch(req);
              return handler.resolve(retried);
            } catch (_) {
              // retry ham muvaffaqiyatsiz — asl xatoni davom ettiramiz
            }
          }
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}
