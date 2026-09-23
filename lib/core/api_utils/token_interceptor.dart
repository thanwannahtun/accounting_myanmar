import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/secure_storage_service.dart';
class TokenInterceptor extends Interceptor {
  TokenInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    /// interceptor for adding token in the request's header
    String? accessToken = await SecureStorageService.instance.getAccessToken();

    if (kDebugMode) {
      print("Token ---> $accessToken");
    }

    if (accessToken == null) {
      if (kDebugMode) {
        print("AccessToken Missing in Request header!");
      }
    }
    options.headers['Authorization'] = 'Token $accessToken';
    return handler.next(options);
  }
}
