import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة الأسئلة الشائعة للويب
class WebFaqScreen extends StatelessWidget {
  const WebFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildContent(context),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final faqs = [
      {
        'question': 'كيف يمكنني استخدام الكوبونات؟',
        'answer':
            'لاستخدام الكوبونات، قم بتصفح الكوبونات المتاحة، انقر على "نسخ الكود"، ثم انتقل إلى موقع المتجر والصق الكود عند الدفع للحصول على الخصم.',
      },
      {
        'question': 'هل جميع الكوبونات مجانية؟',
        'answer':
            'نعم، جميع الكوبونات المتاحة على منصتنا مجانية تماماً. نهدف إلى مساعدتك في توفير المال دون أي تكلفة إضافية.',
      },
      {
        'question': 'كم مرة يتم تحديث الكوبونات؟',
        'answer':
            'نقوم بتحديث الكوبونات بشكل يومي لضمان توفر أحدث العروض والخصومات. كما نتحقق من صلاحية جميع الكوبونات بانتظام.',
      },
      {
        'question': 'ماذا أفعل إذا لم يعمل الكوبون؟',
        'answer':
            'إذا واجهت مشكلة مع كوبون معين، يرجى التواصل معنا عبر صفحة "اتصل بنا" وسنقوم بالتحقق من الأمر فوراً وتوفير بديل إن أمكن.',
      },
      {
        'question': 'هل يمكنني استخدام أكثر من كوبون في نفس الطلب؟',
        'answer':
            'يعتمد ذلك على سياسة كل متجر. معظم المتاجر تسمح باستخدام كوبون واحد فقط لكل طلب، لكن بعضها قد يسمح بدمج عدة عروض.',
      },
      {
        'question': 'كيف يمكنني حفظ الكوبونات المفضلة؟',
        'answer':
            'يمكنك النقر على أيقونة القلب الموجودة على أي كوبون لإضافته إلى قائمة المفضلة. ستجد جميع الكوبونات المحفوظة في صفحة "المفضلة".',
      },
      {
        'question': 'هل التطبيق متاح على جميع المنصات؟',
        'answer':
            'نعم، نوفر خدماتنا عبر الويب وتطبيقات الهاتف المحمول لأنظمة iOS و Android لتوفير أفضل تجربة ممكنة.',
      },
      {
        'question': 'كيف تربحون المال إذا كانت الكوبونات مجانية؟',
        'answer':
            'نحصل على عمولة صغيرة من المتاجر عندما يتم استخدام الكوبونات، مما يسمح لنا بتقديم الخدمة مجاناً للمستخدمين.',
      },
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      padding: ResponsivePadding.page(context),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: faqs
            .map((faq) => _FaqItem(
                  question: faq['question']!,
                  answer: faq['answer']!,
                ))
            .toList(),
      ),
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
                  color: Constants.primaryColor.withOpacity(0.1),
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
                  color: Constants.primaryColor.withOpacity(0.1),
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
