import 'package:flutter/material.dart';
import '../constants.dart';
import 'responsive_layout.dart';

/// تذييل احترافي للويب
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Padding(
        padding: ResponsivePadding.page(context),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // القسم الأول: عن التطبيق
            Expanded(
              flex: 2,
              child: _buildAboutSection(),
            ),
            const SizedBox(width: 60),

            // القسم الثاني: روابط سريعة
            Expanded(
              child: _buildQuickLinks(context),
            ),
            const SizedBox(width: 40),

            // القسم الثالث: روابط قانونية
            Expanded(
              child: _buildLegalLinks(context),
            ),
            const SizedBox(width: 40),

            // القسم الرابع: تواصل معنا
            Expanded(
              child: _buildContactSection(),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _buildCopyright(),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAboutSection(),
        const SizedBox(height: 30),
        _buildQuickLinks(context),
        const SizedBox(height: 30),
        _buildLegalLinks(context),
        const SizedBox(height: 30),
        _buildContactSection(),
        const SizedBox(height: 30),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _buildCopyright(),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.primaryColor,
                    Constants.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ربحان',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Constants.primaryColor,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'منصتك الأولى للحصول على أفضل العروض والخصومات من متاجرك المفضلة. وفّر المال واستمتع بتجربة تسوق ذكية.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.6,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 20),
        _buildSocialIcons(),
      ],
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      children: [
        _buildSocialIcon(Icons.facebook, 'https://facebook.com'),
        const SizedBox(width: 12),
        _buildSocialIcon(Icons.telegram, 'https://telegram.org'),
        const SizedBox(width: 12),
        _buildSocialIcon(Icons.link, 'https://twitter.com'),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: Constants.primaryColor),
        onPressed: () {},
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'روابط سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink(context, 'الرئيسية', '/'),
        _buildFooterLink(context, 'المتاجر', '/stores'),
        _buildFooterLink(context, 'العروض', '/offers'),
        _buildFooterLink(context, 'المفضلة', '/favorites'),
      ],
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات قانونية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink(context, 'من نحن', '/about'),
        _buildFooterLink(context, 'سياسة الخصوصية', '/privacy'),
        _buildFooterLink(context, 'الشروط والأحكام', '/terms'),
        _buildFooterLink(context, 'الأسئلة الشائعة', '/faq'),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تواصل معنا',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        _buildContactItem(Icons.email_rounded, 'info@coupons.com'),
        const SizedBox(height: 8),
        _buildContactItem(Icons.phone_rounded, '+966 XX XXX XXXX'),
        const SizedBox(height: 8),
        _buildContactItem(
            Icons.location_on_rounded, 'المملكة العربية السعودية'),
      ],
    );
  }

  Widget _buildFooterLink(BuildContext context, String text, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Constants.primaryColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright() {
    return Center(
      child: Text(
        '© ${DateTime.now().year} ربحان. جميع الحقوق محفوظة.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}
