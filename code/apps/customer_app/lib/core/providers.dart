import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
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
