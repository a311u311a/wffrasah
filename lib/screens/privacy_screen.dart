import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(t?.translate('privacy_title') ?? 'Privacy Policy',
            style: TextStyle(
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
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
                    t?.translate('privacy_title') ?? 'Privacy Policy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Constants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t?.translate('privacy_intro') ??
                        'We respect the privacy...',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPolicyPoint(
                    t?.translate('privacy_point1_title') ?? 'Privacy Policy',
                    t?.translate('privacy_point1_body') ??
                        'This document aims to...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point2_title') ?? 'Personal Data',
                    t?.translate('privacy_point2_body') ??
                        'The term "personal data"...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point3_title') ??
                        'Collection of Personal Data',
                    t?.translate('privacy_point3_body') ??
                        'The data that Rbhan may collect...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point4_title') ??
                        'Collected Data May Include',
                    t?.translate('privacy_point4_body') ??
                        'Identity: Full name...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point5_title') ??
                        'Security of Personal Data',
                    t?.translate('privacy_point5_body') ??
                        'We implement strict measures...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point6_title') ??
                        'Use of Personal Data',
                    t?.translate('privacy_point6_body') ??
                        'We do not sell or trade...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point7_title') ??
                        'Sharing Personal Data',
                    t?.translate('privacy_point7_body') ??
                        'We may share your data with...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point8_title') ?? 'Newsletters',
                    t?.translate('privacy_point8_body') ??
                        'We may send you promotional...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point9_title') ??
                        'Disclosure to Digital Ad Providers',
                    t?.translate('privacy_point9_body') ??
                        'Rbhan may cooperate with...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point10_title') ??
                        'Update Personal Data',
                    t?.translate('privacy_point10_body') ??
                        'You can update your data...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point11_title') ??
                        'Your Rights to Access and Withdraw Consent',
                    t?.translate('privacy_point11_body') ??
                        'You can request access...',
                  ),
                  _buildPolicyPoint(
                    t?.translate('privacy_point12_title') ??
                        'Deletion of Personal Data',
                    t?.translate('privacy_point12_body') ??
                        'To request deletion...',
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
