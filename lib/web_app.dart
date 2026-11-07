import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'models/store.dart';
import 'services/home_data_service.dart';
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
import 'web_screens/web_admin_stores_screen.dart';
import 'web_screens/web_admin_coupons_screen.dart';
import 'web_screens/web_admin_offers_screen.dart';
import 'web_screens/web_admin_carousel_screen.dart';
import 'web_screens/web_admin_notifications_screen.dart';

/// التطبيق الرئيسي للويب
class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'وفرها صح - كوبونات وعروض',
      theme: themeProvider.getTheme,
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

      // Keep Arabic as the default, but allow the web language switcher to use English.
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
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
          // Opened from a shared link or a page refresh: load the store by key.
          final key = Uri.decodeComponent(
            settings.name!.substring('/store/'.length).split('?').first,
          ).trim();
          if (key.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => _StoreRouteLoader(storeKey: key),
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
          case '/admin/stores':
            screen = const WebAdminStoresScreen();
            break;
          case '/admin/coupons':
            screen = const WebAdminCouponsScreen();
            break;
          case '/admin/offers':
            screen = const WebAdminOffersScreen();
            break;
          case '/admin/carousel':
            screen = const WebAdminCarouselScreen();
            break;
          case '/admin/notifications':
            screen = const WebAdminNotificationsScreen();
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

/// Loads a store by slug or id for `/store/<key>` URLs opened directly.
class _StoreRouteLoader extends StatefulWidget {
  final String storeKey;

  const _StoreRouteLoader({required this.storeKey});

  @override
  State<_StoreRouteLoader> createState() => _StoreRouteLoaderState();
}

class _StoreRouteLoaderState extends State<_StoreRouteLoader> {
  late final Future<Store?> _storeFuture = _loadStore();

  Future<Store?> _loadStore() async {
    final langCode =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    final key = widget.storeKey.toLowerCase();
    final rows = await HomeDataService.fetchStores();
    for (final row in rows) {
      final slug = (row['slug'] ?? '').toString().trim().toLowerCase();
      final id = (row['id'] ?? '').toString().trim().toLowerCase();
      if (slug == key || id == key) {
        return Store.fromSupabase(row, langCode);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Store?>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final store = snapshot.data;
        if (store != null) return WebStoreDetailScreen(store: store);
        return const WebStoresScreen();
      },
    );
  }
}
