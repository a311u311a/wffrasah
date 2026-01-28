import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة من نحن للويب - محدثة
class WebAboutScreen extends StatefulWidget {
  const WebAboutScreen({super.key});

  @override
  State<WebAboutScreen> createState() => _WebAboutScreenState();
}

class _WebAboutScreenState extends State<WebAboutScreen> {
  String _version = '';
  final String _appName = 'rbhan';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // مطابق للموبايل F8F9FA تقريباً
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // المحتوى الرئيسي
            Container(
              padding: ResponsivePadding.page(context),
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(context),
                  const SizedBox(height: 60),

                  // Logo & Version
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Constants.primaryColor
                                    .withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Image.asset('assets/image/coupon.png',
                              errorBuilder: (c, e, s) => Icon(
                                  Icons.shopping_bag,
                                  size: 50,
                                  color: Constants.primaryColor)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _appName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        Text(
                          'Version $_version',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Tajawal'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Intro Section
                  _buildSectionContainer(
                    child: Column(
                      children: [
                        const Text(
                          'وجهتك الأولى للتسوق الذكي والتوفير الحقيقي.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Tajawal'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'نؤمن في $_appName بأن التسوق الممتع لا يجب أن يكون مكلفاً. نحن منصة متكاملة تجمع لك أحدث وأقوى الكوبونات وعروض الخصم من أشهر المتاجر المحلية والعالمية في مكان واحد.\n\nهدفنا هو تمكين المستهلك من الحصول على أفضل المنتجات بأقل الأسعار، من خلال واجهة سهلة الاستخدام وتحديثات يومية تضمن لك فاعلية كل كود خصم قبل استخدامه. مع $_appName، التوفير أصبح بضغطة زر.',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: Colors.black87,
                              fontFamily: 'Tajawal'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Why Us Section
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'لماذا نحن؟ (ما الذي يميزنا؟)',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Constants.primaryColor,
                                fontFamily: 'Tajawal'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'لأننا نحرص على أن تحصل على كود خصم يعمل من أول مرة، جاء $_appName ليقدم لك تجربة خصومات موثوقة عبر:',
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                              fontSize: 16, height: 1.6, fontFamily: 'Tajawal'),
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem('تحديث يومي',
                            'نقوم بفحص وتجربة جميع الكوبونات يدويًا يوميًا للتأكد من فعاليتها وصلاحيتها.'),
                        _buildFeatureItem('عروض حصرية',
                            'أكواد خصم خاصة لمستخدمي $_appName فقط عبر شراكات مباشرة مع المتاجر .'),
                        _buildFeatureItem('تنبيهات ذكية',
                            'لا تفوت فرصة أبداً! سنرسل لك إشعارات فورية عند توفر عرض جديد لمتجرك المفضل.'),
                        _buildFeatureItem('شفافية تامة',
                            'توضيح جميع شروط استخدام الكوبون بكل وضوح قبل الاستخدام.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Social Media Section
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          ' تابعنا وشاركنا تجربتك أو استفساراتك عبر منصاتنا الرسمية:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, height: 1.6, fontFamily: 'Tajawal'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialRow('assets/icon/x.png',
                                  'X (تويتر سابقاً)', '@rbhanco'),
                              const SizedBox(width: 20),
                              _buildSocialRow('assets/icon/instagram.png',
                                  'إنستغرام', '@rbhan.co'),
                              const SizedBox(width: 20),
                              _buildSocialRow('assets/icon/tiktok.png',
                                  'تيك توك', '@rbhan.co'),
                            ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
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
        // Added Column to contain text widgets
        children: [
          Text(
            'من نحن',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تعرف على منصة الكوبونات الأولى',
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

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
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

  Widget _buildFeatureItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black87,
                    fontFamily: 'Tajawal',
                    height: 1.6,
                    fontSize: 15),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String iconPath, String platform, String handle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(iconPath,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.link, color: Colors.grey[400], size: 20))),
          const SizedBox(width: 10),
          Text('$platform: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          Text(handle,
              style:
                  const TextStyle(color: Colors.blue, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }
}
