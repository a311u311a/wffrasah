import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rbhan/providers/theme_provider.dart';
import 'package:rbhan/providers/favorites_provider.dart';
import 'package:rbhan/providers/locale_provider.dart';
import 'package:rbhan/providers/user_provider.dart';
import 'package:rbhan/providers/notification_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'web_app.dart'; // تطبيق الويب
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/change_password_screen.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // For PathUrlStrategy

/// ضع بيانات Supabase هنا (Project Settings -> API)
const supabaseUrl = 'https://ilfbqykxkjructxunuxm.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZmJxeWt4a2pydWN0eHVudXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MTkyODMsImV4cCI6MjA4MzI5NTI4M30.b3_5GkLGUlQCQI_B8XOhLUoK4YboPNn-FyhQCInZpxo';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // تفعيل Path Url Strategy للويب (لإزالة # من الرابط)
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // فقط للموبايل - لا تعمل على الويب
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // ✅ الاستماع لأحداث المصادقة بشكل عام (Global Listener)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // نستخدم navigatorKey للوصول للنافجيتور حتى لو لم نكن في كونتكست مناسب
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✨ تحديد المنصة: إذا كان ويب، استخدم WebApp
    if (kIsWeb) {
      return const WebApp();
    }

    // للموبايل: استخدم التطبيق الحالي
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Rbhan',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getTheme,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        return const SplashScreen();
      }),
    );
  }
}
