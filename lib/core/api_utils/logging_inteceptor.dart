import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LoggingInterceptor extends Interceptor {
  LoggingInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log the error
    debugPrint('Request URL: ➡️ ${err.requestOptions.uri}');
    debugPrint('statusCode: ➡️ ${err.response?.statusCode}');

    debugPrint('Error Data: ➡️ ${err.response?.data}');
    debugPrint('Error Message: ➡️ ${err.response?.data["message"]}');
    debugPrint('Error Type: ➡️ ${err.type}');

    handler.next(err);
  }
}
