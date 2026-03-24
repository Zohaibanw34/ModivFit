import 'package:flutter/material.dart';

class AppResponsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopMaxContentWidth = 980;
  static const double tabletMaxContentWidth = 720;
  static const double mobileMaxContentWidth = 520;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return desktopMaxContentWidth;
    if (isTablet(context)) return tabletMaxContentWidth;
    return mobileMaxContentWidth;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    if (width >= mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  }
}
