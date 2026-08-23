import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

class WebTermsScreen extends StatelessWidget {
  const WebTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // F8F9FA
        appBar: const WebNavigationBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: ResponsivePadding.page(context),
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(context),
                    const SizedBox(height: 40),
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t(context, 'terms_title'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                              color: Constants.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _t(context, 'terms_intro'),
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Tajawal',
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildPolicyPoint(
                            _t(context, 'terms_point1_title'),
                            _t(context, 'terms_point1_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point2_title'),
                            _t(context, 'terms_point2_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point3_title'),
                            _t(context, 'terms_point3_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point4_title'),
                            _t(context, 'terms_point4_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point5_title'),
                            _t(context, 'terms_point5_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point6_title'),
                            _t(context, 'terms_point6_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point7_title'),
                            _t(context, 'terms_point7_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point8_title'),
                            _t(context, 'terms_point8_body'),
                          ),
                          _buildPolicyPoint(
                            _t(context, 'terms_point9_title'),
                            _t(context, 'terms_point9_body'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
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

  String _t(BuildContext context, String key) =>
      AppLocalizations.of(context)?.translate(key) ?? key;

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Text(
        _t(context, 'terms_title'),
        style: TextStyle(
          fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
          fontWeight: FontWeight.w900,
          color: Constants.primaryColor,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
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

  Widget _buildPolicyPoint(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            color: Constants.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Tajawal',
            height: 1.8,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
