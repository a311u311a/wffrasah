import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // أنيميشن إضافي للنصوص لتظهر بسلاسة (Fade In)
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _controller = AnimationController(vsync: this);

    // Initialize Firebase (System/Background only)
    NotificationService.initFirebase();

    // تفعيل ظهور النص بعد نصف ثانية من بدء الأنميشن
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _opacity = 1.0);
    });

    // إظهار رمز الـ FCM للتجربة
    // Future.delayed(const Duration(seconds: 1), () {
    //  if (mounted) {
    //     NotificationService.showTokenDialog(context);
    //   }
    //  });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      // 🔍 نتحقق مما إذا كنا قد انتقلنا بالفعل (بسبب استعادة كلمة المرور مثلاً)
      // ولكن الطريقة الأحدث والأضمن هي التحقق من حالة الـ Recovery في الـ Session
      // حالياً Supabase لا يعطي flag مباشر في الـ Session، لكن الحدث أعلاه هو الأهم.

      // نتحقق إذا كان هناك "dialog" أو "route" جديد تم فتحه فوق الـ Splash
      // ولكن للتبسيط: سنفحص إذا كان هناك "recovery" event وصل للتو.
      // المشكلة أن الـ Listen stream يعمل بشكل غير متزامن.

      // الحل العملي:
      // ببساطة، نقوم بالتحقق من الـ Session العادي.
      // إذا كان المستخدم قادماً من رابط Recovery، فإن الحدث passwordRecovery سيُطلق
      // وغالباً سيسبق هذا الـ Future أو يأتي معه.

      // لتجنب التعارض، يمكننا التحقق: هل المستخدم logged in "و" هل الـ link type هو recovery؟
      // للأسف الـ Link type غير متاح بسهولة هنا.

      // سنعتمد على أن `pushAndRemoveUntil` في الـ listener سيلغي أي navigation آخر
      // ولكن إذا سبق الـ Future الـ Listener، فإن الـ Listener سيعمل "بعد" الانتقال للصفحة الرئيسية.
      // لذا سننتقل للصفحة الرئيسية، والـ Listener (بما أنه Global أو مستمر) يجب أن يكون في مكان لا يموت.
      // ⚠️ ولكن لحظة: الـ Splash سيموت (dispose) عند الانتقال!
      // إذن الـ listener سيموت ولن يعمل إذا تأخر الحدث.

      // ✅ الحل الصحيح: نقل الـ Listener إلى الـ `main.dart` أو `MyApp` ليكون Global
      // أو جعل الـ Splash ينتظر قليلاً للتأكد.

      // بما أننا في Splash، سنقوم بالتوجيه العادي، ولكن سنستخدم `pushReplacement`
      // إذا وصل حدث Recovery "بعد" الانتقال، فلن يتم التقاطه لأن الـ Splash disposed.

      // لذلك: أفضل مكان لمعالجة الـ Deep Links هو في الـ root widget أو استخدام `go_router`.
      // لكن بما أننا نستخدم Navigator عادي:

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // المستخدم مسجل دخول
        // هل يمكننا معرفة هل هو recovery session؟
        // ليس بسهولة، ولكن الـ listener المفروض التقطه.

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const BottomNavBar(initialIndex: 2)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const BottomNavBar(initialIndex: 2),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
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
              Constants.primaryColor
                  .withValues(alpha: 0.05), // لمحة خفيفة من لون هويتك
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2), // دفع المحتوى للمنتصف بتوازن

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
                      fontWeight: FontWeight.w900, // خط سميك جداً للفخامة
                      color: Constants.primaryColor,
                      fontFamily: 'Tajawal', // استخدام الخط الذي أضفته
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
