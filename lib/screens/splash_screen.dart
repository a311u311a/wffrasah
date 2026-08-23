import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../widgets/bottom_navigation_bar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // أنيميشن إضافي للنصوص لتظهر بسلاسة (Fade In)
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    // ✅ شغّل تهيئة Firebase بعد أول فريم لتقليل التقطيع (Skipped frames)
    // تفعيل ظهور النص بعد نصف ثانية من بدء الأنميشن
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _opacity = 1.0);
    });

    // الانتقال بعد 4 ثواني
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const BottomNavBar(initialIndex: 2),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      // ignore: unused_local_variable
      final _ = session;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = (size.shortestSide * 0.44).clamp(150.0, 220.0);
    final animationSize = (size.shortestSide * 0.36).clamp(130.0, 190.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // إضافة تدرج لوني ناعم يعطي فخامة للخلفية
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withValues(alpha: 0.08),
              Colors.white,
              Constants.primaryColor.withValues(alpha: 0.05),
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.2),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 900),
                  opacity: _opacity,
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.primaryColor.withValues(alpha: 0.18),
                          blurRadius: 36,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/image/wffrhasah.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // نص العنوان بأنيميشن ظهور تدريجي واستخدام خط Tajawal
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _opacity,
                  child: Column(
                    children: [
                      Text(
                        'وفرها صح',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSplashResponsive.titleSize(context),
                          fontWeight: FontWeight.w900,
                          color: Constants.primaryColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'كوبونات وعروض ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSplashResponsive.subtitleSize(context),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 100),
                      SizedBox(
                        width: animationSize,
                        height: animationSize,
                        child: Lottie.asset(
                          'assets/animations/coupon_animation.json',
                          controller: _controller,
                          fit: BoxFit.contain,
                          onLoaded: (composition) {
                            _controller
                              ..duration = composition.duration
                              ..repeat();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // مؤشر تحميل بسيط وأنيق في الأسفل
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _opacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 34),
                    child: Column(
                      children: [
                        
                        const SizedBox(height: 14),
                        Text(
                          'جاري التحميل...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSplashResponsive {
  static double titleSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 700) return 40;
    return 34;
  }

  static double subtitleSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 700) return 20;
    return 17;
  }
}

Future<void> debugFetch() async {
  try {
    final res = await Supabase.instance.client
        .from('stores')
        .select('id,name')
        .limit(5);

    debugPrint('stores res: $res');
  } catch (e) {
    debugPrint('stores error: $e');
  }
}
