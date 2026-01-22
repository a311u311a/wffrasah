import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة سياسة الخصوصية للويب
class WebPrivacyScreen extends StatelessWidget {
  const WebPrivacyScreen({super.key});

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
            'سياسة الخصوصية',
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
            'المقدمة',
            'نحن في منصة الكوبونات نلتزم بحماية خصوصيتك. توضح سياسة الخصوصية هذه كيفية جمعنا واستخدامنا وحمايتنا للمعلومات التي تقدمها عند استخدام موقعنا وتطبيقاتنا.',
          ),
          _buildSection(
            'المعلومات التي نجمعها',
            '''نقوم بجمع الأنواع التالية من المعلومات:

• معلومات الحساب: الاسم، البريد الإلكتروني، وكلمة المرور عند إنشاء حساب.
• معلومات الاستخدام: تفاصيل حول كيفية استخدامك للمنصة، مثل الكوبونات التي تشاهدها أو تستخدمها.
• المعلومات التقنية: عنوان IP، نوع المتصفح، ونظام التشغيل.
• ملفات تعريف الارتباط: نستخدم ملفات تعريف الارتباط لتحسين تجربتك وتذكر تفضيلاتك.''',
          ),
          _buildSection(
            'كيفية استخدام المعلومات',
            '''نستخدم المعلومات التي نجمعها للأغراض التالية:

• تقديم وتحسين خدماتنا
• تخصيص المحتوى والعروض بناءً على اهتماماتك
• التواصل معك بشأن التحديثات والعروض الجديدة
• حماية المنصة من الاحتيال والإساءة
• تحليل استخدام المنصة لتحسين الأداء''',
          ),
          _buildSection(
            'مشاركة المعلومات',
            '''نحن لا نبيع أو نؤجر معلوماتك الشخصية لأطراف ثالثة. قد نشارك المعلومات في الحالات التالية:

• مع المتاجر الشريكة: لتتبع استخدام الكوبونات (بطريقة مجهولة الهوية)
• مع مزودي الخدمة: الذين يساعدوننا في تشغيل المنصة
• للامتثال القانوني: عند الطلب بموجب القانون''',
          ),
          _buildSection(
            'أمان البيانات',
            'نستخدم تدابير أمنية متقدمة لحماية معلوماتك من الوصول غير المصرح به أو التغيير أو الإفصاح أو الإتلاف. ومع ذلك، لا يمكن ضمان أمان الإنترنت بنسبة 100%.',
          ),
          _buildSection(
            'حقوقك',
            '''لديك الحق في:

• الوصول إلى معلوماتك الشخصية
• تصحيح أو تحديث معلوماتك
• حذف حسابك وبياناتك
• إلغاء الاشتراك في الرسائل التسويقية
• طلب نسخة من بياناتك''',
          ),
          _buildSection(
            'ملفات تعريف الارتباط',
            'نستخدم ملفات تعريف الارتباط لتحسين تجربتك على المنصة. يمكنك تعطيل ملفات تعريف الارتباط من إعدادات المتصفح، لكن هذا قد يؤثر على بعض الوظائف.',
          ),
          _buildSection(
            'التغييرات على سياسة الخصوصية',
            'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سنقوم بإخطارك بأي تغييرات جوهرية عبر البريد الإلكتروني أو من خلال إشعار على المنصة.',
          ),
          _buildSection(
            'اتصل بنا',
            'إذا كان لديك أي أسئلة حول سياسة الخصوصية هذه، يرجى التواصل معنا عبر صفحة "اتصل بنا" أو عبر البريد الإلكتروني: privacy@coupons.com',
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
