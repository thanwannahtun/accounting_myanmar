import 'package:flutter/material.dart';
import '../../ui/screens/shell/main_shell_screen.dart';
import '../../ui/screens/splash/splash_screen.dart';
import 'route_names.dart';

class RouteGenerator {
  static Route<T>? onGenerateRoute<T>(RouteSettings settings) {
    debugPrint("🟢 navigate To -> ${settings.name}");
    switch (settings.name) {
      case RouteNames.splashScreen:
      case "/splash":
        return _navigateRoute(
          settings: settings,
          builder: (context) => const SplashScreen(),
        );
      case RouteNames.app:
        return _navigateRoute(
          settings: settings,
          builder: (context) => const MainShellScreen(),
        );
      default:
        return _navigateRoute(
          settings: settings,
          builder: (context) => const MainShellScreen(),
        );
    }
  }

  static Route<T>? _navigateRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
