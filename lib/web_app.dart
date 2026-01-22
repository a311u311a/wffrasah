import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'localization/app_localizations.dart';
import 'web_screens/web_home_screen.dart';
import 'web_screens/web_stores_screen.dart';
import 'web_screens/web_offers_screen.dart';
import 'web_screens/web_favorites_screen.dart';
import 'web_screens/web_about_screen.dart';
import 'web_screens/web_contact_screen.dart';
import 'web_screens/web_faq_screen.dart';
import 'web_screens/web_privacy_screen.dart';
import 'web_screens/web_terms_screen.dart';
import 'web_screens/web_admin_screen.dart';
import 'web_screens/web_signin_screen.dart';
import 'web_screens/web_signup_screen.dart';
import 'web_screens/web_coupons_screen.dart';

/// التطبيق الرئيسي للويب
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كوبونات - أفضل العروض والخصومات',
      theme: themeProvider.getTheme.copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Constants.primaryColor,
          brightness: Brightness.light,
        ),
      ),
      locale: localeProvider.locale,

      // ✨ دعم RTL
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      // ✨ فرض اللغة العربية كافتراضية
      localeResolutionCallback: (locale, supportedLocales) {
        // إذا كانت لغة الجهاز عربية، استخدمها
        if (locale?.languageCode == 'ar') {
          return const Locale('ar');
        }
        // وإلا استخدم العربية كافتراضي
        return const Locale('ar');
      },

      // Initial Route
      initialRoute: '/',

      // Routes
      routes: {
        '/': (context) => const WebHomeScreen(),
        '/stores': (context) => const WebStoresScreen(),
        '/coupons': (context) => const WebCouponsScreen(),
        '/offers': (context) => const WebOffersScreen(),
        '/favorites': (context) => const WebFavoritesScreen(),
        '/about': (context) => const WebAboutScreen(),
        '/contact': (context) => const WebContactScreen(),
        '/faq': (context) => const WebFaqScreen(),
        '/privacy': (context) => const WebPrivacyScreen(),
        '/terms': (context) => const WebTermsScreen(),
        '/admin': (context) => const WebAdminScreen(),
        '/signin': (context) => const WebSignInScreen(),
        '/signup': (context) => const WebSignUpScreen(),
      },

      // Unknown Route
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const WebHomeScreen(),
        );
      },
    );
  }
}
