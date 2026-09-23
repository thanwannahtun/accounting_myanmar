import 'package:dio/dio.dart';

import '../env.dart';

class BaseUrlInterceptor extends Interceptor {
  const BaseUrlInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    /// interceptor for adding baseurl in the request's base url
    options.baseUrl = Env.baseUrl;
    return handler.next(options);
  }
}
