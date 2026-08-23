import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة الأسئلة الشائعة للويب - محدثة بمحتوى التطبيق
class WebFaqScreen extends StatelessWidget {
  const WebFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                    _buildHeader(context),
                    const SizedBox(height: 40),
                    _buildContent(context),
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
      child: Column(
        children: [
          Text(
            _t(context, 'faq_title'),
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t(context, 'faq_subtitle'),
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

  Widget _buildContent(BuildContext context) {
    final faqs = [
      {
        'question': _t(context, 'faq_q1'),
        'answer': _t(context, 'faq_a1'),
      },
      {
        'question': _t(context, 'faq_q2'),
        'answer': _t(context, 'faq_a2'),
      },
      {
        'question': _t(context, 'faq_q3'),
        'answer': _t(context, 'faq_a3'),
      },
      {
        'question': _t(context, 'faq_q4'),
        'answer': _t(context, 'faq_a4'),
      },
      {
        'question': _t(context, 'faq_q5'),
        'answer': _t(context, 'faq_a5'),
      },
    ];

    return Column(
      children: faqs
          .map((faq) => _FaqItem(
                question: faq['question']!,
                answer: faq['answer']!,
              ))
          .toList(),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? Constants.primaryColor : Colors.grey[200]!,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Constants.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.help_rounded,
                  color: Constants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isExpanded ? Constants.primaryColor : Colors.black87,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          trailing: Icon(
            isExpanded ? Icons.remove : Icons.add,
            color: Constants.primaryColor,
          ),
          onExpansionChanged: (value) {
            setState(() => isExpanded = value);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                widget.answer,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.6,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
