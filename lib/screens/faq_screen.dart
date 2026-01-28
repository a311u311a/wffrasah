import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          t?.translate('faq_title') ?? 'FAQ',
          style: TextStyle(
            fontSize: 18,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Constants.primaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                const SizedBox(height: 10),
                FaqItem(
                  question: t?.translate('faq_q1') ?? 'Is the app free?',
                  answer: t?.translate('faq_a1') ??
                      'Yes, the app is completely free...',
                ),
                FaqItem(
                  question:
                      t?.translate('faq_q2') ?? 'How do I use a discount code?',
                  answer: t?.translate('faq_a2') ??
                      'Simply click on the "Copy Code" button...',
                ),
                FaqItem(
                  question: t?.translate('faq_q3') ??
                      'The code doesn\'t work, what should I do?',
                  answer: t?.translate('faq_a3') ??
                      'Make sure to read the coupon usage conditions...',
                ),
                FaqItem(
                  question: t?.translate('faq_q4') ??
                      'Can I use the discount code more than once?',
                  answer: t?.translate('faq_a4') ??
                      'Yes. This varies from one store to another...',
                ),
                FaqItem(
                  question: t?.translate('faq_q5') ??
                      'Are discount codes updated in the app?',
                  answer: t?.translate('faq_a5') ??
                      'Yes. Discount codes are constantly updated...',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© ${DateTime.now().year} ${t?.translate('rights_reserved_rbhan') ?? "All rights reserved. Rbhan App & Website"}',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[400], fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const FaqItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: Constants
                  .primaryColor, // Changed to primaryColor for consistency
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                answer,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'Tajawal',
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
