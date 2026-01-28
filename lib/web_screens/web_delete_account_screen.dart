import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

class WebDeleteAccountScreen extends StatelessWidget {
  const WebDeleteAccountScreen({super.key});

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
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب حذف الحساب',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'نحن في تطبيق ربحان نلتزم بحماية بياناتك وخصوصيتك. وفقاً لسياسات Google Play وتشريعات حماية البيانات، لديك الحق الكامل في طلب حذف حسابك وجميع البيانات المرتبطة به نهائياً من أنظمتنا.',
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
                          'ماذا يحدث عند حذف الحساب؟',
                          'عند إتمام عملية حذف الحساب، سيتم إزالة جميع بياناتك بشكل دائم ولا يمكن استرجاعها، ويشمل ذلك:\n\n'
                              '• الملف الشخصي (الاسم، الصورة، البريد الإلكتروني).\n'
                              '• سجل العروض والكوبونات المستخدمة.\n'
                              '• أي نقاط أو مكافآت مكتسبة في محفظتك.\n'
                              '• قائمة المفضلة والمتاجر المتابعة.\n'
                              '\n'
                              'يرجى الملاحظة أننا قد نحتفظ ببعض السجلات المالية أو سجلات المعاملات القديمة لفترة محددة إذا كان القانون يتطلب ذلك لأغراض التدقيق والمحاسبة.',
                        ),
                        _buildPolicyPoint(
                          'كيفية طلب حذف الحساب',
                          'يمكنك تقديم طلب لحذف حسابك بإحدى الطرق التالية:\n\n'
                              '1. من داخل التطبيق:\n'
                              '   اذهب إلى "القائمة" > "تعديل الملف" > "حذف الحساب" واتبع التعليمات.\n\n'
                              '2. عبر البريد الإلكتروني (إذا لم تتمكن من الدخول للتطبيق):\n'
                              '   أرسل رسالة إلى بريد الدعم الفني: admin@rbhan.co\n'
                              '   - عنوان الرسالة: "طلب حذف حساب"\n'
                              '   - محتوى الرسالة: يرجى كتابة البريد الإلكتروني والاسم المسجله في التطبيق  .\n\n'
                              'سيقوم فريق الدعم بمراجعة طلبك والتحقق من ملكيتك للحساب، ومن ثم تنفيذ الحذف خلال مدة أقصاها 7 أيام عمل.',
                        ),
                        _buildPolicyPoint(
                          'تواصل معنا',
                          'إذا كان لديك أي استفسار حول بياناتك أو عملية الحذف، لا تتردد في التواصل معنا عبر صفحة "اتصل بنا" أو عبر البريد الإلكتروني الموضح أعلاه.',
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

  Widget _buildHeader(BuildContext context) {
    return Center(
        child: Text(
      'حذف الحساب',
      style: TextStyle(
        fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
        fontWeight: FontWeight.w900,
        color: Constants.primaryColor,
        fontFamily: 'Tajawal',
      ),
    ));
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
