import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

String handleErrorMessage(dynamic e) {
  if (e is DioException) {
    debugPrint("✔️ This IS a DioException ➡️ Type: ${e.type}");
  } else {
    debugPrint("❌ NOT a DioException. Got: ${e.runtimeType}");
  }
  return ApiErrorHandler.handle(e).message;
}

class ApiErrorHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          return ApiException(
            message:
                error.response?.data['message'] ??
                "Request to API was cancelled",
          );
        case DioExceptionType.connectionTimeout:
          return _TimeoutException(
            error.response?.data['message'] ??
                "Connection timeout with API server",
          );
        case DioExceptionType.sendTimeout:
          return _TimeoutException(
            error.response?.data['message'] ??
                "Send timeout in connection with API server",
          );
        case DioExceptionType.receiveTimeout:
          return _TimeoutException(
            error.response?.data['message'] ??
                "Receive timeout in connection with API server",
          );
        case DioExceptionType.connectionError:
          return _NetworkException(
            error.response?.data['message'] ??
                "Failed to connect to the API server. Please check your internet connection.",
          );
        case DioExceptionType.badResponse:
          return _handleHttpResponse(error);
        case DioExceptionType.unknown:
          if (error.message?.contains("SocketException") ?? false) {
            return _NetworkException("No Internet connection");
          }
          return ApiException(message: error.toString());
        default:
          return ApiException(message: "Unexpected error occurred : $error");
      }
    } else {
      return ApiException(message: "(⊙ˍ⊙) ${error.toString()}");
    }
  }

  static ApiException _handleHttpResponse(Exception error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 400:
          return _BadRequestException(
            "${error.response?.data['message'] ?? 'Invalid request'}",
          );
        case 401:
          return ApiException(
            message:
                "${error.response?.data['message'] ?? 'Please check your API key or login credentials.'}",
          );
        case 403:
          return _AuthenticationException(
            "${error.response?.data['message'] ?? 'Access denied'}",
          );
        case 429:
          return _AuthenticationException(
            "${error.response?.data['message'] ?? 'Rate limited!'}",
          );
        case 404:
          return _NotFoundException(
            "${error.response?.data['message'] ?? 'Resource not found'}",
          );
        case 500:
          return ApiException(
            message:
                error.response?.data['message'] ??
                "Internal server error. Please try again later.",
          );

        case 504:
          return ApiException(
            message:
                "${error.response?.data['message'] ?? 'The server is not responding.'}",
          );

        default:
          return _ServerException(
            "${error.response?.data['message'] ?? 'Internal server error'}",
            error.response?.statusCode,
          );
      }
    } else {
      return ApiException(message: "Raw : ${error.toString()}");
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class _NetworkException extends ApiException {
  _NetworkException(String message) : super(message: message);
}

class _TimeoutException extends ApiException {
  _TimeoutException(String message) : super(message: message);
}

class _ServerException extends ApiException {
  _ServerException(String message, int? statusCode)
    : super(message: message, statusCode: statusCode);
}

class _AuthenticationException extends ApiException {
  _AuthenticationException(String message) : super(message: message);
}

class _BadRequestException extends ApiException {
  _BadRequestException(String message) : super(message: message);
}

class _NotFoundException extends ApiException {
  _NotFoundException(String message) : super(message: message);
}
