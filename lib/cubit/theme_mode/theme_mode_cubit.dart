import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/secure_storage_service.dart';

// 1. Add WidgetsBindingObserver to listen to system hardware events
class ThemeModeCubit extends Cubit<ThemeMode> with WidgetsBindingObserver {
  ThemeModeCubit(super.initialState) {
    // 2. Register this cubit as a listener to system changes
    WidgetsBinding.instance.addObserver(this);
  }

  static const String _themeKey = 'app_theme_mode';
  final SecureStorageService _storage = SecureStorageService.instance;

  Future<void> init() async {
    final cachedTheme = await _storage.read(_themeKey);
    if (cachedTheme != null) {
      final mode = _parseThemeMode(cachedTheme);
      emit(mode);
    }
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    emit(mode);
    await _storage.write(_themeKey, mode.name);
  }

  // 3. This fires automatically whenever the user changes their phone-level theme
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Only force a rebuild if the app is currently relying on the system theme
    if (state == ThemeMode.system) {
      emit(ThemeMode.system);
    }
  }

  bool get isDarkModeActive {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;

    final systemBrightness = PlatformDispatcher.instance.platformBrightness;
    return systemBrightness == Brightness.dark;
  }

  ThemeMode _parseThemeMode(String name) {
    return ThemeMode.values.firstWhere(
          (e) => e.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  // 4. Clean up the observer when the cubit is closed
  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}
