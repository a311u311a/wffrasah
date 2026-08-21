import 'package:flutter/material.dart';

class AppResponsive {
  static const double tabletMinWidth = 600;
  static const double largeTabletMinWidth = 1024;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tabletMinWidth;
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= largeTabletMinWidth) return 980;
    if (isTablet(context)) return 760;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (!isTablet(context)) return EdgeInsets.zero;
    return const EdgeInsets.symmetric(horizontal: 28);
  }

  static int gridColumns(BuildContext context,
      {int phone = 2, int tablet = 3}) {
    return isTablet(context) ? tablet : phone;
  }
}
