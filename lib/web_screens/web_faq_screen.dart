import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة الأسئلة الشائعة للويب - محدثة بمحتوى التطبيق
class WebFaqScreen extends StatelessWidget {
  const WebFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'الأسئلة الشائعة',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'إجابات على الأسئلة الأكثر شيوعاً',
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
    // قائمة الأسئلة من faq_screen.dart
    final faqs = [
      {
        'question': 'هل التطبيق مجاني؟',
        'answer':
            'نعم، التطبيق مجاني بالكامل. نحن نحصل على عمولة بسيطة من المتاجر عند استخدامك للكوبونات عبر تطبيقنا، وهذا لا يؤثر على السعر الذي تدفعه.',
      },
      {
        'question': 'كيف أستخدم كود الخصم؟',
        'answer':
            'ببساطة، اضغط على زر "نسخ الكود" ثم ألصقه في خانة الكوبون في صفحة الدفع بالمتجر.',
      },
      {
        'question': 'الكود لا يعمل، ماذا أفعل؟',
        'answer':
            'تأكد من قراءة شروط استخدام الكوبون (مثل الحد الأدنى للطلب والمنتجات المشمولة). إذا استمرت المشكلة، فهذا يعني أن صلاحية الكود قد انتهت.',
      },
      {
        'question': 'هل يمكن استخدام كود الخصم أكثر من مرة؟',
        'answer':
            'نعم. يختلف ذلك من متجر لآخر، ولكن في كثير من الحالات يمكن استخدام كود الخصم عدة مرات.',
      },
      {
        'question': 'هل يتم تحديث أكواد الخصم في التطبيق؟',
        'answer':
            'نعم. يتم تحديث أكواد الخصم باستمرار لضمان توفر أحدث وأفضل العروض للمستخدمين.',
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
