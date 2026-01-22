import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة من نحن للويب
class WebAboutScreen extends StatelessWidget {
  const WebAboutScreen({super.key});

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
            context,
            icon: Icons.lightbulb_rounded,
            title: 'رؤيتنا',
            content:
                'نسعى لأن نكون المنصة الرائدة في توفير أفضل العروض والخصومات في العالم العربي، مما يساعد المستخدمين على توفير المال والاستمتاع بتجربة تسوق ذكية.',
          ),
          const SizedBox(height: 40),
          _buildSection(
            context,
            icon: Icons.flag_rounded,
            title: 'مهمتنا',
            content:
                'توفير منصة سهلة الاستخدام تجمع أفضل الكوبونات والعروض من مختلف المتاجر المحلية والعالمية، مع ضمان صحة وتحديث جميع الكوبونات بشكل مستمر.',
          ),
          const SizedBox(height: 40),
          _buildSection(
            context,
            icon: Icons.trending_up_rounded,
            title: 'نجاحاتنا',
            content:
                'منذ انطلاقنا، ساعدنا آلاف المستخدمين في توفير المال من خلال أكثر من 10,000 كوبون نشط من مئات المتاجر الموثوقة.',
          ),
          const SizedBox(height: 60),
          _buildFeatures(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Constants.primaryColor,
                Constants.primaryColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.8,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      {
        'icon': Icons.verified_rounded,
        'title': 'كوبونات موثوقة',
        'desc': 'جميع الكوبونات مضمونة ومحدثة'
      },
      {
        'icon': Icons.update_rounded,
        'title': 'تحديث يومي',
        'desc': 'عروض جديدة كل يوم'
      },
      {
        'icon': Icons.devices_rounded,
        'title': 'متعدد المنصات',
        'desc': 'متاح على الويب والموبايل'
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'دعم 24/7',
        'desc': 'فريق الدعم جاهز لمساعدتك'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لماذا تختارنا؟',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 30),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveLayout.isDesktop(context) ? 2 : 1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 3,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    color: Constants.primaryColor,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['desc'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
