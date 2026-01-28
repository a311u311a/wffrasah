import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

class WebTermsScreen extends StatelessWidget {
  const WebTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // F8F9FA
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
                          'شروط الاستخدام',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'باستخدامك لتطبيق (rbhan)، فإنك توافق على الالتزام بشروط الاستخدام التالية. إذا لم توافق على هذه الشروط، يرجى عدم استخدام التطبيق.',
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
                          '1. وصف الخدمة',
                          'يوفر التطبيق منصة لعرض الكوبونات والعروض الترويجية المقدمة من أطراف ثالثة، ولا يضمن توفر أو صلاحية جميع العروض في جميع الأوقات.',
                        ),
                        _buildPolicyPoint(
                          '2. أهلية الاستخدام',
                          '• يجب أن يكون عمرك 13 عامًا على الأقل (أو حسب القوانين المحلية المعمول بها).\n'
                              '• أنت مسؤول عن صحة ودقة المعلومات التي تقدمها عند استخدام التطبيق.',
                        ),
                        _buildPolicyPoint(
                          '3. استخدام الكوبونات والعروض',
                          '• تخضع جميع الكوبونات والعروض لشروط وأحكام الجهة المقدمة لها.\n'
                              '• لا يتحمل التطبيق أي مسؤولية عن إلغاء أو تعديل أو انتهاء صلاحية أي عرض.\n'
                              '• يمنع استخدام الكوبونات بطرق غير قانونية أو مخالفة للأنظمة.',
                        ),
                        _buildPolicyPoint(
                          '4. الملكية الفكرية',
                          'جميع المحتويات داخل التطبيق، بما في ذلك النصوص والتصاميم والشعارات، مملوكة للتطبيق أو للجهات المرخصة له، ويمنع نسخها أو إعادة استخدامها دون إذن مسبق.',
                        ),
                        _buildPolicyPoint(
                          '5. إيقاف أو إنهاء الحساب',
                          'يحق لإدارة التطبيق تعليق أو إنهاء حساب المستخدم في حال مخالفة شروط الاستخدام أو إساءة استخدام التطبيق، دون إشعار مسبق.',
                        ),
                        _buildPolicyPoint(
                          '6. إخلاء المسؤولية',
                          'يتم تقديم التطبيق "كما هي" دون أي ضمانات صريحة أو ضمنية. ولا نتحمل أي مسؤولية عن أي خسائر مباشرة أو غير مباشرة ناتجة عن استخدام العروض أو الكوبونات.',
                        ),
                        _buildPolicyPoint(
                          '7. التعديلات على الشروط',
                          'نحتفظ بالحق في تعديل شروط الاستخدام في أي وقت، ويعد استمرارك في استخدام التطبيق بعد التعديلات موافقة عليها.',
                        ),
                        _buildPolicyPoint(
                          '8. القانون الواجب التطبيق',
                          'تخضع هذه الشروط وتفسر وفقًا لقوانين الدولة التي يتم تشغيل التطبيق منها، ويكون الاختصاص القضائي لمحاكمها.',
                        ),
                        _buildPolicyPoint(
                          '9. التواصل معنا',
                          'لأي استفسارات متعلقة بشروط الاستخدام، يرجى التواصل عبر قنوات الدعم المتاحة داخل التطبيق.',
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
        'شروط الاستخدام',
        style: TextStyle(
          fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
          fontWeight: FontWeight.w900,
          color: Constants.primaryColor,
          fontFamily: 'Tajawal',
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
