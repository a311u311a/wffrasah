import 'package:flutter/material.dart';
import '../constants.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('سياسة الخصوصية',
            style: TextStyle(
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSectionContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سياسة الخصوصية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Constants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية عند استخدامك لتطبيق عرض الكوبونات والعروض ("التطبيق"). توضح هذه السياسة كيفية جمع واستخدام وحماية المعلومات.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPolicyPoint(
                    '1. المعلومات التي نقوم بجمعها',
                    'قد نقوم بجمع الأنواع التالية من المعلومات:\n\n'
                        '• معلومات شخصية: مثل البريد الإلكتروني أو رقم الهاتف في حال إنشاء حساب.\n'
                        '• معلومات غير شخصية: مثل نوع الجهاز، نظام التشغيل، وإحصاءات الاستخدام داخل التطبيق.\n'
                        '• معلومات الموقع (اختياري): فقط في حال منح الإذن، لتحسين العروض القريبة منك.',
                  ),
                  _buildPolicyPoint(
                    '2. كيفية استخدام المعلومات',
                    'نستخدم المعلومات للأغراض التالية:\n\n'
                        '• عرض الكوبونات والعروض المناسبة لك.\n'
                        '• تحسين تجربة المستخدم وأداء التطبيق.\n'
                        '• التواصل معك بخصوص التحديثات أو العروض (عند موافقتك).\n'
                        '• الامتثال للمتطلبات القانونية.',
                  ),
                  _buildPolicyPoint(
                    '3. مشاركة المعلومات',
                    'نحن لا نبيع بياناتك الشخصية. قد نشارك بعض المعلومات مع:\n\n'
                        '• شركاء العروض فقط لغرض تفعيل الكوبونات.\n'
                        '• مزودي الخدمات التقنية (مثل الاستضافة والتحليلات).\n'
                        '• الجهات القانونية عند الطلب الرسمي.',
                  ),
                  _buildPolicyPoint(
                    '4. حماية البيانات',
                    'نطبق إجراءات أمنية تقنية وتنظيمية مناسبة لحماية معلوماتك من الوصول غير المصرح به أو الفقدان أو التعديل.',
                  ),
                  _buildPolicyPoint(
                    '5. حقوق المستخدم',
                    'يحق لك:\n\n'
                        '• الوصول إلى بياناتك أو تعديلها أو حذفها.\n'
                        '• سحب الموافقة على جمع بعض البيانات.\n'
                        '• إيقاف الإشعارات التسويقية في أي وقت.',
                  ),
                  _buildPolicyPoint(
                    '6. ملفات تعريف الارتباط (Cookies)',
                    'قد نستخدم ملفات تعريف الارتباط وتقنيات مشابهة لتحسين الأداء وتحليل الاستخدام.',
                  ),
                  _buildPolicyPoint(
                    '7. التعديلات على سياسة الخصوصية',
                    'نحتفظ بالحق في تحديث هذه السياسة، وسيتم إشعارك عند أي تعديل جوهري.',
                  ),
                  _buildPolicyPoint(
                    '8. التواصل معنا',
                    'للاستفسارات المتعلقة بالخصوصية، يرجى التواصل عبر البريد الإلكتروني أو صفحة الدعم داخل التطبيق.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '© ${DateTime.now().year} جميع الحقوق محفوظة. كوبونات التخفيضات',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey[400], fontFamily: 'Tajawal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            color: Constants.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.justify,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Tajawal',
            height: 1.6,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
