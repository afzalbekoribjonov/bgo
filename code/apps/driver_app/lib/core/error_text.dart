import 'package:dio/dio.dart';

bool isNetworkError(Object error) {
  return error is DioException &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout);
}

int? httpStatus(Object error) =>
    error is DioException ? error.response?.statusCode : null;
