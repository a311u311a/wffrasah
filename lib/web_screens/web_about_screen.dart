import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة من نحن للويب - محدثة
class WebAboutScreen extends StatefulWidget {
  const WebAboutScreen({super.key});

  @override
  State<WebAboutScreen> createState() => _WebAboutScreenState();
}

class _WebAboutScreenState extends State<WebAboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final appName = _t('app_name');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // مطابق للموبايل F8F9FA تقريباً
        appBar: const WebNavigationBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // المحتوى الرئيسي
              Container(
                padding: ResponsivePadding.page(context),
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(context),
                    const SizedBox(height: 60),

                    // Logo & Version
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Constants.primaryColor
                                      .withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Image.asset('assets/image/coupon.png',
                                errorBuilder: (c, e, s) => Icon(
                                    Icons.shopping_bag,
                                    size: 50,
                                    color: Constants.primaryColor)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            appName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Constants.primaryColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          Text(
                            '${_t('version')} $_version',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Tajawal'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Intro Section
                    _buildSectionContainer(
                      child: Column(
                        children: [
                          Text(
                            _t('about_app_intro_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Tajawal'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _t('about_app_intro_body')
                                .replaceAll('{appName}', appName),
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: Colors.black87,
                                fontFamily: 'Tajawal'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Why Us Section
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              _t('about_app_why_title'),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Constants.primaryColor,
                                  fontFamily: 'Tajawal'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _t('about_app_why_body')
                                .replaceAll('{appName}', appName),
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                fontFamily: 'Tajawal'),
                          ),
                          const SizedBox(height: 20),
                          _buildFeatureItem(
                            _t('about_feature_daily_updates_title'),
                            _t('about_feature_daily_updates_body'),
                          ),
                          _buildFeatureItem(
                            _t('about_feature_exclusive_offers_title'),
                            _t('about_feature_exclusive_offers_body')
                                .replaceAll('{appName}', appName),
                          ),
                          _buildFeatureItem(
                            _t('about_feature_smart_alerts_title'),
                            _t('about_feature_smart_alerts_body'),
                          ),
                          _buildFeatureItem(
                            _t('about_feature_transparency_title'),
                            _t('about_feature_transparency_body'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Social Media Section
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _t('about_social_text'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                fontFamily: 'Tajawal'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialRow('assets/icon/x.png',
                                    _t('x_platform'), '@rbhanco'),
                                const SizedBox(width: 20),
                                _buildSocialRow('assets/icon/instagram.png',
                                    _t('instagram_platform'), '@rbhan.co'),
                                const SizedBox(width: 20),
                                _buildSocialRow('assets/icon/tiktok.png',
                                    _t('tiktok_platform'), '@rbhan.co'),
                              ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              const WebFooter(),
            ],
          ),
        ),
      ),
    );
  }

  String _t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Column(
        // Added Column to contain text widgets
        children: [
          Text(
            _t('about'),
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t('about_app_subtitle'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black87,
                    fontFamily: 'Tajawal',
                    height: 1.6,
                    fontSize: 15),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String iconPath, String platform, String handle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(iconPath,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.link, color: Colors.grey[400], size: 20))),
          const SizedBox(width: 10),
          Text('$platform: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          Text(handle,
              style:
                  const TextStyle(color: Colors.blue, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }
}
