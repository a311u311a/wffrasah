import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة الشروط والأحكام للويب
class WebTermsScreen extends StatelessWidget {
  const WebTermsScreen({super.key});

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
            'الشروط والأحكام',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'آخر تحديث: ${DateTime.now().year}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      padding: ResponsivePadding.page(context),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'القبول بالشروط',
            'باستخدامك لمنصة الكوبونات، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي جزء من هذه الشروط، يجب عليك عدم استخدام المنصة.',
          ),
          _buildSection(
            'استخدام الخدمة',
            '''عند استخدام منصتنا، أنت توافق على:

• استخدام الكوبونات بطريقة قانونية وأخلاقية
• عدم محاولة اختراق أو تعطيل المنصة
• عدم استخدام الكوبونات بطرق احتيالية
• توفير معلومات دقيقة وصحيحة عند إنشاء حساب
• الحفاظ على سرية معلومات حسابك''',
          ),
          _buildSection(
            'الكوبونات والعروض',
            '''فيما يتعلق بالكوبونات المتوفرة على المنصة:

• جميع الكوبونات مقدمة من المتاجر الشريكة وليس من منصتنا مباشرة
• نبذل قصارى جهدنا لضمان صحة الكوبونات، لكننا لا نضمن نجاح جميع الكوبونات
• قد تكون الكوبونات خاضعة لشروط وقيود من المتاجر
• المتاجر لها الحق في إلغاء أو تعديل العروض في أي وقت
• نحن غير مسؤولين عن أي نزاعات بينك وبين المتاجر''',
          ),
          _buildSection(
            'حساب المستخدم',
            '''عند إنشاء حساب:

• أنت مسؤول عن الحفاظ على أمان حسابك
• يجب أن يكون عمرك 18 عاماً على الأقل أو لديك موافقة ولي الأمر
• حساب واحد لكل شخص
• نحتفظ بالحق في تعليق أو إنهاء الحسابات المخالفة
• يجب إخطارنا فوراً بأي استخدام غير مصرح به لحسابك''',
          ),
          _buildSection(
            'الملكية الفكرية',
            'جميع المحتويات على المنصة، بما في ذلك النصوص والصور والشعارات والرموز، هي ملك لمنصة الكوبونات أو مرخصة لنا. لا يجوز استخدام أي محتوى دون إذن كتابي مسبق.',
          ),
          _buildSection(
            'إخلاء المسؤولية',
            '''المنصة متاحة "كما هي" دون أي ضمانات:

• لا نضمن دقة أو اكتمال المعلومات
• لا نضمن توفر الخدمة بشكل متواصل
• لا نتحمل المسؤولية عن أي خسائر ناتجة عن استخدام المنصة
• نحن لسنا مسؤولين عن محتوى المواقع الخارجية التي نرتبط بها''',
          ),
          _buildSection(
            'حدود المسؤولية',
            'في أي حال من الأحوال، لن نكون مسؤولين عن أي أضرار مباشرة أو غير مباشرة أو عرضية أو خاصة أو تبعية ناشئة عن استخدام أو عدم القدرة على استخدام المنصة.',
          ),
          _buildSection(
            'التعديلات',
            'نحتفظ بالحق في تعديل هذه الشروط والأحكام في أي وقت. التعديلات الجوهرية سيتم إخطارك بها عبر البريد الإلكتروني أو إشعار على المنصة. استمرارك في استخدام المنصة بعد التعديلات يعني قبولك لها.',
          ),
          _buildSection(
            'الإنهاء',
            'يمكننا إنهاء أو تعليق وصولك إلى المنصة فوراً، دون إشعار مسبق أو مسؤولية، لأي سبب كان، بما في ذلك دون حصر إذا خالفت هذه الشروط.',
          ),
          _buildSection(
            'القانون الحاكم',
            'تخضع هذه الشروط والأحكام وتفسر وفقاً لقوانين المملكة العربية السعودية. أي نزاع ينشأ عن هذه الشروط سيخضع للاختصاص القضائي الحصري للمحاكم في المملكة.',
          ),
          _buildSection(
            'اتصل بنا',
            'إذا كان لديك أي أسئلة حول هذه الشروط والأحكام، يرجى التواصل معنا عبر صفحة "اتصل بنا" أو عبر البريد الإلكتروني: legal@coupons.com',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.8,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}
