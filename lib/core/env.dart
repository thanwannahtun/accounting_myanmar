import 'package:flutter/foundation.dart';

class Env {
  // ─── Token keys ───────────────────────────────────────────────
  static const String refreshToken = 'refreshToken';
  static const String accessToken = 'accessToken';

  // ─── Backend base URLs ────────────────────────────────────────
  // static const String baseUrlDev = 'http://localhost:3500/api/v1';
  static const String baseUrlDev = 'http://192.168.0.143:3500/api/v1';

  /// Production backend.
  static const String baseUrlProd =
      'https://chey-ngar-backend.onrender.com/api/v1';

  /// The active base URL (switches based on build mode).
  static String get baseUrl => kDebugMode ? baseUrlDev : baseUrlProd;
}
