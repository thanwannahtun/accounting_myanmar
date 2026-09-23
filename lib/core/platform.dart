import 'package:flutter/material.dart';

/**
 *
 * Breakpoint Reference :: ✅
    if (width < 600) {
    // Phone layout
    } else if (width < 840) {
    // Tablet layout
    } else if (width < 1200) {
    // Small desktop / laptop layout
    } else {
    // Full desktop / ultrawide layout
    }

 */

///
enum PlatformType {
  mobile(600),
  tablet(840),
  laptop(1200),
  desktop(1440);

  final int minWidth;

  const PlatformType(this.minWidth);

  bool operator >(PlatformType other) => minWidth > other.minWidth;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < PlatformType.mobile.minWidth;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= PlatformType.mobile.minWidth &&
      screenWidth(context) < PlatformType.tablet.minWidth;

  static bool isLaptop(BuildContext context) =>
      screenWidth(context) >= PlatformType.tablet.minWidth &&
      screenWidth(context) < PlatformType.laptop.minWidth;

  static bool isDesktop(BuildContext context) =>
      screenWidth(context) >= PlatformType.laptop.minWidth;

  static PlatformType currentPlatform(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobile.minWidth) return PlatformType.mobile;
    if (width < tablet.minWidth) return PlatformType.tablet;
    if (width < laptop.minWidth) return PlatformType.laptop;
    return PlatformType.desktop;
  }
}

/**
 * 🔥 Example Usage:
 * final platform = PlatformType.currentPlatform(context);

    if (PlatformType.isMobile(context)) {
    // mobile layout
    } else if (PlatformType.isTablet(context)) {
    // tablet layout
    }

 */
