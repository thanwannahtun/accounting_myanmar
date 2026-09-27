import '../../ui/screens/dashboard/cash_flow_activity_screen.dart';
import '../../ui/screens/shell/main_shell_screen.dart';
import '../../ui/screens/splash/splash_screen.dart';
import 'route_names.dart';

import 'package:flutter/material.dart';

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
      case RouteNames.cashFlowActivity:
        return _navigateRoute(
          settings: settings,
          builder: (context) => const CashFlowActivityScreen(),
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
