import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

class WebPrivacyScreen extends StatelessWidget {
  const WebPrivacyScreen({super.key});

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
                        // ✅ عنوان واضح للـ Google Bot
                        Text(
                          'Privacy Policy – Rbhan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'سياسة الخصوصية – موقع وتطبيقربحان',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ✅ فقرة إنجليزية قصيرة (مهمة للتحقق)
                        const Text(
                          'This Privacy Policy explains how Rbhan collects, uses, and protects your personal information when you use our website and services.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Tajawal',
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // محتواك العربي
                        const Text(
                          'نحن نحترم خصوصية وسرية البيانات الشخصية لعملائنا وزبائننا وزوارنا وجميع الأشخاص الذين نتعامل معهم أثناء تقديم خدماتنا. وبينما نسعى لتقديم تجربة تسوق محسّنة لعملائنا، فإننا ندرك أن من أهم مخاوفهم سلامة معلوماتهم الشخصية، ولذلك نلتزم بضمان بقاء جميع البيانات الشخصية المقدمة لنا آمنة وعدم استخدامها إلا للأغراض التي وافق عليها العميل.\n\nفي البداية، نقوم بجمع المعلومات الشخصية الضرورية فقط لتقديم الخدمات التي طلبتها، وفهم احتياجاتك، وخدمتك بشكل أفضل. كما أننا نزود شركاءنا من التجار فقط بالمعلومات اللازمة للتحقق من مكافآتك وتتبعها.\n\nنحن لا نبيع معلوماتك تحت أي ظرف.',
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
                          'Privacy Policy (السياسة)',
                          'يهدف هذا المستند إلى توضيح كيفية قيام Rbhan بإدارة وجمع واستخدام والإفصاح عن البيانات الشخصية الخاصة بك وبمستخدمي موقعنا الإلكتروني وتطبيقاتنا وبرامجنا ومنصاتنا الأخرى.\n\nنحن نزاول أعمالنا وفقًا لقوانين حماية البيانات المعمول بها، وقد قمنا بتطبيق تدابير إضافية لحماية معلوماتك الشخصية. ويُعد استمرار استخدامك لخدماتنا موافقة منك على الالتزام بسياسة الخصوصية هذه كما يتم تحديثها من وقت لآخر.',
                        ),
                        _buildPolicyPoint(
                          'Personal Data (البيانات الشخصية)',
                          'يقصد بمصطلح "البيانات الشخصية" أي بيانات تتعلق بشخص يمكن التعرف عليه من خلالها، سواء بشكل مباشر أو غير مباشر، بما في ذلك البيانات الموجودة في سجلاتنا.',
                        ),
                        _buildPolicyPoint(
                          'Collecting Personal Data (جمع البيانات)',
                          'تعتمد البيانات التي قد تجمعها Rbhan على المنتجات والخدمات والعروض التي تستخدمها أو تشترك فيها. ويتم جمع هذه البيانات لتمكين المنصات من العمل بشكل صحيح ولمعرفة كيفية استخدامها على مختلف الأجهزة والمتصفحات.\n\nعادةً نقوم بجمع بياناتك عندما تقوم بما يلي:\n\nتزويدنا بمعلومات الاتصال بعد زيارة أو استخدام أو تثبيت مواقعنا أو تطبيقاتنا.\nالتسجيل في خدماتنا أو تعبئة أي نماذج.\nالاشتراك في التنبيهات أو النشرات البريدية.\nالتواصل معنا للاستفسار أو طلب المساعدة.\nالمشاركة في المسابقات أو الاستبيانات.\nتقديم السيرة الذاتية أو طلبات التوظيف.\nإحالتك إلينا من شركاء أو أطراف ثالثة.',
                        ),
                        _buildPolicyPoint(
                          'Data We May Collect (قد تشمل البيانات)',
                          'الهوية: الاسم الكامل، البريد الإلكتروني، تاريخ الميلاد، رقم الهاتف، الصور، عنوان IP، معرف الجهاز، ومعلومات الدفع.\nالتفاعلات معنا: تسجيلات المكالمات والبريد الإلكتروني والمراسلات.\nالحساب: معلومات حساب Rbhan الخاص بك.\nاستخدام الخدمات: بيانات التصفح وملفات تعريف الارتباط (Cookies).\nالتفضيلات: المنتجات والعلامات التجارية المفضلة وطرق التواصل.',
                        ),
                        _buildPolicyPoint(
                          'Security (أمان البيانات)',
                          'نطبق إجراءات صارمة لحماية بياناتك، ومنها:\n\nاستخدام اتصال SSL مشفّر 128-bit.\nتخزين البيانات على خوادم آمنة.\nتقييد الوصول للمعلومات.\nتطبيق آليات تحقق صارمة.\nإتلاف البيانات عند عدم الحاجة إليها.',
                        ),
                        _buildPolicyPoint(
                          'How We Use Data (استخدام البيانات)',
                          'لا نقوم ببيع أو المتاجرة ببياناتك الشخصية. ونستخدمها من أجل:\n\n1) إدارة الخدمات\nلتنفيذ الطلبات، تتبع المعاملات، إضافة الكاش باك، وتقديم العروض والمكافآت.\n\n2) تحسين الخدمات\nتحليل الشكاوى، تحسين الأداء، تخصيص المحتوى، وإرسال الإعلانات ذات الصلة.\n\n3) خدمة العملاء\nالرد على الاستفسارات وتقديم الدعم.\n\n4) الأمان والامتثال\nمنع الاحتيال والالتزام بالأنظمة والقوانين.\n\n5) طلبات التوظيف\nمعالجة طلبات التوظيف وإدارة السجلات الوظيفية.\n\nنحتفظ بالبيانات فقط للمدة اللازمة قانونيًا أو تشغيليًا.',
                        ),
                        _buildPolicyPoint(
                          'Sharing (مشاركة البيانات)',
                          'قد نشارك بياناتك مع:\n\nشركائنا ومقدمي الخدمات.\nالمستثمرين أو الأطراف المشاركة في صفقات استحواذ أو اندماج.\nالجهات الحكومية أو التنظيمية عند الطلب.',
                        ),
                        _buildPolicyPoint(
                          'Emails (النشرات البريدية)',
                          'قد نرسل لك رسائل ترويجية، ويمكنك إلغاء الاشتراك في أي وقت.',
                        ),
                        _buildPolicyPoint(
                          'Advertising Partners (الإفصاح للإعلانات)',
                          'قد تتعاون Rbhan مع أطراف ثالثة لعرض إعلانات مخصصة بناءً على نشاطك على الإنترنت. ولا تغطي هذه السياسة ممارسات تلك الأطراف.',
                        ),
                        _buildPolicyPoint(
                          'Update Your Data (تحديث البيانات)',
                          'يمكنك تحديث بياناتك من خلال حسابك، أو التواصل معنا عبر:\ncontact@rbhan.com',
                        ),
                        _buildPolicyPoint(
                          'Your Rights (حقوقك)',
                          'يمكنك طلب الوصول إلى بياناتك أو سحب موافقتك في أي وقت عبر البريد أعلاه.\nقد يؤدي سحب الموافقة إلى عدم قدرتنا على تقديم بعض الخدمات.',
                        ),
                        _buildPolicyPoint(
                          'Delete Account (حذف البيانات)',
                          'لطلب حذف حسابك وبياناتك، راسلنا من بريدك المسجل.\n\nيرجى ملاحظة:\n\nستفقد أي كاش باك متبقي.\nسيتم حذف جميع بياناتك الشخصية.\nسنحتفظ بسجلات المعاملات لأغراض تدقيقية.\nلن تتمكن من تسجيل الدخول مجددًا.',
                        ),
                        _buildPolicyPoint(
                          'Changes (التعديلات)',
                          'تحتفظ Rbhan بحق تعديل السياسة في أي وقت، وسيتم نشر التحديثات على الموقع.',
                        ),
                        _buildPolicyPoint(
                          'Governing Law (القانون الحاكم)',
                          'تخضع هذه السياسة لقوانين الدولة التي تقيم فيها.',
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

  // ✅ هيدر صار فيه English + Arabic
  Widget _buildHeader(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Center(
      child: Column(
        children: [
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: isDesktop ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'سياسة الخصوصية',
            style: TextStyle(
              fontSize: isDesktop ? 26 : 20,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.75),
              fontFamily: 'Tajawal',
            ),
          ),
        ],
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
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
