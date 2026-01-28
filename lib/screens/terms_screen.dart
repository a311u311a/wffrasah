import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          t?.translate('terms_title') ?? 'Terms of Use',
          style: TextStyle(
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.translate('terms_title') ?? 'Terms of Use',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Constants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t?.translate('terms_intro') ??
                        'By using the app, you agree...',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPolicyPoint(
                    t?.translate('terms_point1_title') ??
                        '1. Service Description',
                    t?.translate('terms_point1_body') ??
                        'The application provides...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point2_title') ??
                        '2. Eligibility for Use',
                    t?.translate('terms_point2_body') ??
                        'You must be at least...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point3_title') ??
                        '3. Use of Coupons and Offers',
                    t?.translate('terms_point3_body') ??
                        'All coupons and offers...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point4_title') ??
                        '4. Intellectual Property',
                    t?.translate('terms_point4_body') ??
                        'All content within the app...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point5_title') ??
                        '5. Account Suspension or Termination',
                    t?.translate('terms_point5_body') ??
                        'The application administration...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point6_title') ?? '6. Disclaimer',
                    t?.translate('terms_point6_body') ??
                        'The application is provided "as is"...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point7_title') ??
                        '7. Amendments to Terms',
                    t?.translate('terms_point7_body') ??
                        'We reserve the right to amend...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point8_title') ?? '8. Applicable Law',
                    t?.translate('terms_point8_body') ??
                        'These terms are governed...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('terms_point9_title') ?? '9. Contact Us',
                    t?.translate('terms_point9_body') ?? 'For any inquiries...',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '© ${DateTime.now().year} ${t?.translate('rights_reserved_rbhan') ?? "All rights reserved. Rbhan App & Website"}',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[400], fontFamily: 'Tajawal'),
            ),
          ],
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

  Widget _buildPolicyPoint(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            color: Constants.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Tajawal',
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
