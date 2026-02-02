import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../services/notification_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initFirebase();
    });

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
    return Scaffold(
      body: Container(
        width: double.infinity,
        // إضافة تدرج لوني ناعم يعطي فخامة للخلفية
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Constants.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // حاوية الأنيميشن مع ظل ناعم خلف الـ Lottie
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset(
                  'assets/animations/coupon_animation.json',
                  controller: _controller,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..forward();
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // نص العنوان بأنيميشن ظهور تدريجي واستخدام خط Tajawal
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _opacity,
              child: Column(
                children: [
                  Text(
                    'كوبونات وعروض',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Constants.primaryColor,
                      fontFamily: 'Tajawal',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'مع تطبيق ربحان الكل ربحان',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // مؤشر تحميل بسيط وأنيق في الأسفل
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _opacity,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Constants.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
