import 'package:accountingmyanmar/core/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LogoutInterceptor extends Interceptor {
  const LogoutInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    /// interceptor for Logging out the user when another user is logging with the same credentials
    debugPrint('Unauthorized  : ${err.response?.statusCode}');
    debugPrint('Message       : ${err.message}');
    if (err.response?.statusCode == 401) {
      _logoutUserAndDeleteCredential();
    }
    handler.next(err);
  }
}

Future<void> _logoutUserAndDeleteCredential() async {
  // navigatorKey.currentState?.pushAndRemoveUntil(
  //   MaterialPageRoute(builder: (context) => AuthScreen()),
  //   (route) => false,
  // );
  await SecureStorageService.instance.deleteAll();
}
