import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '';
  String _appName = 'Coupon App';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _appName = info.appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          localizations?.translate('حول التطبيق') ?? 'About App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: Image.asset('assets/image/coupon.png',
                    errorBuilder: (c, e, s) => Icon(Icons.shopping_bag,
                        size: 40, color: Constants.primaryColor)),
              ),
              const SizedBox(height: 15),

              Text(
                _appName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
              Text(
                'Version $_version',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Tajawal'),
              ),

              const SizedBox(height: 30),

              // Intro Section
              _buildSectionContainer(
                child: Column(
                  children: [
                    const Text(
                      'وجهتك الأولى للتسوق الذكي والتوفير الحقيقي.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نؤمن في $_appName بأن التسوق الممتع لا يجب أن يكون مكلفاً. نحن منصة متكاملة تجمع لك أحدث وأقوى الكوبونات وعروض الخصم من أشهر المتاجر المحلية والعالمية في مكان واحد.\n\nهدفنا هو تمكين المستهلك من الحصول على أفضل المنتجات بأقل الأسعار، من خلال واجهة سهلة الاستخدام وتحديثات يومية تضمن لك فاعلية كل كود خصم قبل استخدامه. مع $_appName، التوفير أصبح بضغطة زر.',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                          fontFamily: 'Tajawal'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Why Us Section
              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'لماذا نحن؟ (ما الذي يميزنا؟)',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColor,
                            fontFamily: 'Tajawal'),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'لأننا نحرص على أن تحصل على كود خصم يعمل من أول مرة، جاء $_appName ليقدم لك تجربة خصومات موثوقة عبر:',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          fontSize: 14, height: 1.5, fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 10),
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

              const SizedBox(height: 20),

              // Social Media Section
              _buildSectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      ' تابعنا وشاركنا تجربتك أو استفساراتك عبر منصاتنا الرسمية:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, fontFamily: 'Tajawal'),
                    ),
                    const SizedBox(height: 15),
                    _buildSocialRow('assets/icon/x.png', 'X (تويتر سابقاً)',
                        '@CouponApp'), // استبدل @CouponApp بالحساب الفعلي
                    _buildSocialRow(
                        'assets/icon/instagram.png', 'إنستغرام', '@CouponApp'),
                    _buildSocialRow(
                        'assets/icon/tiktok.png', 'تيك توك', '@CouponApp'),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text(
                '© ${DateTime.now().year} جميع الحقوق محفوظة. كوبونات التخفيضات',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontFamily: 'Tajawal'),
              ),
            ],
          ),
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    color: Colors.black87, fontFamily: 'Tajawal', height: 1.5),
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String iconPath, String platform, String handle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // عرض أيقونة الصورة إذا كانت متوفرة، وإلا عرض أيقونة رابط
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
