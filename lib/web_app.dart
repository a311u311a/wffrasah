import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'models/store.dart';
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
import 'web_screens/web_store_detail_screen.dart';
import 'web_screens/web_menu_screen.dart';
import 'web_screens/web_change_password_screen.dart';
import 'web_screens/web_edit_profile_screen.dart';
import 'web_screens/web_notifications_history_screen.dart';
import 'web_screens/web_delete_account_screen.dart';

/// التطبيق الرئيسي للويب
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ربحان - أفضل العروض والخصومات',
      theme: themeProvider.getTheme.copyWith(
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

      // Dynamic Route Generation
      onGenerateRoute: (settings) {
        // Handle store detail pages
        if (settings.name != null && settings.name!.startsWith('/store/')) {
          final store = settings.arguments;
          if (store != null && store is Store) {
            return MaterialPageRoute(
              builder: (context) => WebStoreDetailScreen(store: store),
              settings: settings,
            );
          }
        }

        // Handle static routes
        Widget screen;
        switch (settings.name) {
          case '/':
            screen = const WebHomeScreen();
            break;
          case '/stores':
            screen = const WebStoresScreen();
            break;
          case '/coupons':
            screen = const WebCouponsScreen();
            break;
          case '/offers':
            screen = const WebOffersScreen();
            break;
          case '/favorites':
            screen = const WebFavoritesScreen();
            break;
          case '/about':
            screen = const WebAboutScreen();
            break;
          case '/contact':
            screen = const WebContactScreen();
            break;
          case '/faq':
            screen = const WebFaqScreen();
            break;
          case '/privacy':
            screen = const WebPrivacyScreen();
            break;
          case '/terms':
            screen = const WebTermsScreen();
            break;
          case '/admin':
            screen = const WebAdminScreen();
            break;
          case '/signin':
            screen = const WebSignInScreen();
            break;
          case '/signup':
            screen = const WebSignUpScreen();
            break;
          case '/menu':
            screen = const WebMenuScreen();
            break;
          case '/change-password':
            screen = const WebChangePasswordScreen();
            break;
          case '/edit-profile':
            screen = const WebEditProfileScreen();
            break;
          case '/notifications':
            screen = const WebNotificationsHistoryScreen();
            break;
          case '/delete-account':
            screen = const WebDeleteAccountScreen();
            break;
          default:
            screen = const WebHomeScreen();
        }

        return MaterialPageRoute(
          builder: (context) => screen,
          settings: settings,
        );
      },
    );
  }
}
