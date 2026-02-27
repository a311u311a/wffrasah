import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../localization/app_localizations.dart';

class WebPrivacyScreen extends StatelessWidget {
  const WebPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                  // Header
                  Center(
                    child: Text(
                      l10n?.translate('privacy_title') ?? 'Privacy Policy',
                      style: TextStyle(
                        fontSize: isDesktop ? 42 : 32,
                        fontWeight: FontWeight.w900,
                        color: Constants.primaryColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n?.translate('privacy_top_note') ??
                            'Privacy Policy - wffrasah  سياسة الخصوصية . موقع وتطبيق وفرها صح This Privacy Policy explains how wffrasah collects, uses. and protects your personal information when you use our website and services',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Tajawal',
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        Text(
                          l10n?.translate('privacy_subtitle') ??
                              'Privacy Policy – wffrasah',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Intro Text
                        Text(
                          l10n?.translate('privacy_intro') ?? '',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Policy Points
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point1_title') ??
                              'Privacy Policy',
                          l10n?.translate('privacy_point1_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point2_title') ??
                              'Personal Data',
                          l10n?.translate('privacy_point2_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point3_title') ??
                              'Collecting Personal Data',
                          l10n?.translate('privacy_point3_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point4_title') ??
                              'Data We May Collect',
                          l10n?.translate('privacy_point4_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point5_title') ?? 'Security',
                          l10n?.translate('privacy_point5_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point6_title') ??
                              'How We Use Data',
                          l10n?.translate('privacy_point6_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point7_title') ?? 'Sharing',
                          l10n?.translate('privacy_point7_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point8_title') ?? 'Emails',
                          l10n?.translate('privacy_point8_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point9_title') ??
                              'Advertising Partners',
                          l10n?.translate('privacy_point9_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point10_title') ??
                              'Update Your Data',
                          l10n?.translate('privacy_point10_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point11_title') ??
                              'Your Rights',
                          l10n?.translate('privacy_point11_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point12_title') ??
                              'Delete Account',
                          l10n?.translate('privacy_point12_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point13_title') ?? 'Changes',
                          l10n?.translate('privacy_point13_body') ?? '',
                        ),
                        _buildPolicyPoint(
                          l10n?.translate('privacy_point14_title') ??
                              'Governing Law',
                          l10n?.translate('privacy_point14_body') ?? '',
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPolicyPoint(String title, String body) {
    if (body.isEmpty) return const SizedBox.shrink();
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
