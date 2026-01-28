import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '';
  final String _appName = 'Rbhan';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          localizations?.translate('about_app') ?? 'About App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: Image.asset('assets/image/Rbhan.png',
                    errorBuilder: (c, e, s) => Icon(Icons.shopping_bag,
                        size: 40, color: Constants.primaryColor)),
              ),
              const SizedBox(height: 15),

              Text(
                _appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
              Text(
                'Version $_version',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Tajawal'),
              ),

              const SizedBox(height: 30),

              // Intro Section
              _buildSectionContainer(
                child: Column(
                  children: [
                    Text(
                      localizations?.translate('about_app_intro_title') ??
                          'Your primery destination for smart shopping and real savings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      localizations?.translate('about_app_intro_body') ??
                          'At Rbhan, we believe that fun shopping shouldn\'t be expensive...',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                          fontFamily: 'Tajawal'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Why Us Section
              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        localizations?.translate('why_us_title') ??
                            'Why Us? (What makes us special?)',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColor,
                            fontFamily: 'Tajawal'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      localizations?.translate('why_us_intro') ??
                          'Because we ensure you get a discount code that works from the first time...',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          fontSize: 14, height: 1.5, fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                        localizations
                                ?.translate('feature_daily_update_title') ??
                            'Daily Update',
                        localizations?.translate('feature_daily_update_desc') ??
                            'We manually check and test all coupons daily...'),
                    _buildFeatureItem(
                        localizations
                                ?.translate('feature_exclusive_offers_title') ??
                            'Exclusive Offers',
                        localizations
                                ?.translate('feature_exclusive_offers_desc') ??
                            'Special discount codes for Rbhan users only...'),
                    _buildFeatureItem(
                        localizations
                                ?.translate('feature_smart_alerts_title') ??
                            'Smart Alerts',
                        localizations?.translate('feature_smart_alerts_desc') ??
                            'Never miss a chance! We will send you instant notifications...'),
                    _buildFeatureItem(
                        localizations
                                ?.translate('feature_transparency_title') ??
                            'Total Transparency',
                        localizations?.translate('feature_transparency_desc') ??
                            'Clarifying all coupon usage conditions clearly before use.'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Social Media Section
              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      localizations?.translate('follow_us_text') ??
                          'Follow us and share your experience...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 15),
                    _buildSocialRow('assets/icon/x.png', 'X (تويتر سابقاً)',
                        '@rbhanco'), // استبدل @CouponApp بالحساب الفعلي
                    _buildSocialRow(
                        'assets/icon/instagram.png', 'إنستغرام', '@rbhan.co'),
                    _buildSocialRow(
                        'assets/icon/tiktok.png', 'تيك توك', '@rbhan.co'),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                '© ${DateTime.now().year} ${localizations?.translate('rights_reserved_rbhan') ?? "All rights reserved. Rbhan App & Website"}',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black87, fontFamily: 'Tajawal', height: 1.5),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String iconPath, String platform, String handle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // عرض أيقونة الصورة إذا كانت متوفرة، وإلا عرض أيقونة رابط
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
