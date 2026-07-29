import 'package:dio/dio.dart';

/// Tarmoq (internet yo'q / timeout) xatosimi?
bool isNetworkError(Object error) {
  return error is DioException &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout);
}

/// HTTP status kodi (bo'lsa).
int? httpStatus(Object error) =>
    error is DioException ? error.response?.statusCode : null;

/// Backend `{code, message, ...}` shaklidagi strukturaviy xato yuborsa —
/// `code` maydonini qaytaradi (masalan 'DRIVER_BLOCKED'). Aks holda null.
String? errorCode(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is Map && data['code'] is String) return data['code'] as String;
  return null;
}

/// Strukturaviy xato javobining to'liq map'i (bo'lsa).
Map<String, dynamic>? errorData(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  return data is Map ? Map<String, dynamic>.from(data) : null;
}
