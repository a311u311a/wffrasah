import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_i18n.dart';

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
                          webText(context, 'طلب حذف الحساب',
                              'Account Deletion Request'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: Constants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          webText(
                              context,
                              'نحن في تطبيق ربحان نلتزم بحماية بياناتك وخصوصيتك. وفقاً لسياسات Google Play وتشريعات حماية البيانات، لديك الحق الكامل في طلب حذف حسابك وجميع البيانات المرتبطة به نهائياً من أنظمتنا.',
                              'At Waferha Sah, we are committed to protecting your data and privacy. In line with Google Play policies and data protection rules, you have the full right to request permanent deletion of your account and all related data from our systems.'),
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
                          webText(context, 'ماذا يحدث عند حذف الحساب؟',
                              'What happens when the account is deleted?'),
                          webText(
                              context,
                              'عند إتمام عملية حذف الحساب، سيتم إزالة جميع بياناتك بشكل دائم ولا يمكن استرجاعها، ويشمل ذلك:\n\n'
                                  '• الملف الشخصي (الاسم، الصورة، البريد الإلكتروني).\n'
                                  '• سجل العروض والكوبونات المستخدمة.\n'
                                  '• أي نقاط أو مكافآت مكتسبة في محفظتك.\n'
                                  '• قائمة المفضلة والمتاجر المتابعة.\n'
                                  '\n'
                                  'يرجى الملاحظة أننا قد نحتفظ ببعض السجلات المالية أو سجلات المعاملات القديمة لفترة محددة إذا كان القانون يتطلب ذلك لأغراض التدقيق والمحاسبة.',
                              'Once the deletion process is completed, all your data will be permanently removed and cannot be recovered, including:\n\n'
                                  '• Profile information (name, photo, email).\n'
                                  '• Used offers and coupons history.\n'
                                  '• Any points or rewards in your wallet.\n'
                                  '• Favorites and followed stores.\n\n'
                                  'Please note that we may retain some financial or historical transaction records for a limited period if required by law for auditing and accounting purposes.'),
                        ),
                        _buildPolicyPoint(
                          webText(context, 'كيفية طلب حذف الحساب',
                              'How to request account deletion'),
                          webText(
                              context,
                              'يمكنك تقديم طلب لحذف حسابك بإحدى الطرق التالية:\n\n'
                                  '1. من داخل التطبيق:\n'
                                  '   اذهب إلى "القائمة" > "تعديل الملف" > "حذف الحساب" واتبع التعليمات.\n\n'
                                  '2. عبر البريد الإلكتروني (إذا لم تتمكن من الدخول للتطبيق):\n'
                                  '   أرسل رسالة إلى بريد الدعم الفني: wffrhasah@gmail.com\n'
                                  '   - عنوان الرسالة: "طلب حذف حساب"\n'
                                  '   - محتوى الرسالة: يرجى كتابة البريد الإلكتروني والاسم المسجله في التطبيق  .\n\n'
                                  'سيقوم فريق الدعم بمراجعة طلبك والتحقق من ملكيتك للحساب، ومن ثم تنفيذ الحذف خلال مدة أقصاها 7 أيام عمل.',
                              'You can request account deletion in one of the following ways:\n\n'
                                  '1. From inside the app:\n'
                                  '   Go to "Menu" > "Edit Profile" > "Delete Account" and follow the instructions.\n\n'
                                  '2. By email if you cannot access the app:\n'
                                  '   Send a message to support: wffrhasah@gmail.com\n'
                                  '   - Subject: "Account Deletion Request"\n'
                                  '   - Message: include the email and name registered in the app.\n\n'
                                  'Our support team will review your request, verify account ownership, and complete deletion within a maximum of 7 business days.'),
                        ),
                        _buildPolicyPoint(
                          webText(context, 'تواصل معنا', 'Contact Us'),
                          webText(
                              context,
                              'إذا كان لديك أي استفسار حول بياناتك أو عملية الحذف، لا تتردد في التواصل معنا عبر صفحة "اتصل بنا" أو عبر البريد الإلكتروني الموضح أعلاه.',
                              'If you have any questions about your data or the deletion process, contact us through the Contact Us page or the email shown above.'),
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
      webText(context, 'حذف الحساب', 'Delete Account'),
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
