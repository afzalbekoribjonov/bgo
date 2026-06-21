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
