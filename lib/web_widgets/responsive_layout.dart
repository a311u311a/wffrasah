import 'package:flutter/material.dart';

/// مكون متجاوب يحدد نوع الجهاز ويعرض التخطيط المناسب
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// نقاط القطع للشاشات
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  /// تحديد ما إذا كانت الشاشة موبايل
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  /// تحديد ما إذا كانت الشاشة تابلت
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMaxWidth &&
      MediaQuery.of(context).size.width < tabletMaxWidth;

  /// تحديد ما إذا كانت الشاشة ديسكتوب
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletMaxWidth) {
          return desktop;
        } else if (constraints.maxWidth >= mobileMaxWidth) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Padding متجاوب حسب حجم الشاشة
class ResponsivePadding {
  static EdgeInsets page(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 40);
    } else if (ResponsiveLayout.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 30);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    }
  }

  static EdgeInsets section(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return const EdgeInsets.symmetric(vertical: 60);
    } else if (ResponsiveLayout.isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 40);
    } else {
      return const EdgeInsets.symmetric(vertical: 30);
    }
  }
}

/// عدد الأعمدة المناسب حسب حجم الشاشة
class ResponsiveGrid {
  static int columns(BuildContext context, {int max = 4}) {
    if (ResponsiveLayout.isDesktop(context)) {
      return max;
    } else if (ResponsiveLayout.isTablet(context)) {
      return max > 2 ? 3 : 2;
    } else {
      return 2;
    }
  }

  static double spacing(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return 24;
    } else if (ResponsiveLayout.isTablet(context)) {
      return 16;
    } else {
      return 12;
    }
  }
}
