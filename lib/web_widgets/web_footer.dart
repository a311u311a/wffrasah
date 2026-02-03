import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import 'responsive_layout.dart';

/// تذييل احترافي للويب
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

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
          mobile: _buildMobileLayout(context, localizations),
          desktop: _buildDesktopLayout(context, localizations),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, AppLocalizations? localizations) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // القسم الأول: عن التطبيق
            Expanded(
              flex: 2,
              child: _buildAboutSection(localizations),
            ),
            const SizedBox(width: 60),

            // القسم الثاني: روابط سريعة
            Expanded(
              child: _buildQuickLinks(context, localizations),
            ),
            const SizedBox(width: 40),

            // القسم الثالث: روابط قانونية
            Expanded(
              child: _buildLegalLinks(context, localizations),
            ),
            const SizedBox(width: 40),

            // القسم الرابع: تواصل معنا
            Expanded(
              child: _buildContactSection(localizations),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _buildCopyright(localizations),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAboutSection(localizations),
        const SizedBox(height: 30),
        _buildQuickLinks(context, localizations),
        const SizedBox(height: 30),
        _buildLegalLinks(context, localizations),
        const SizedBox(height: 30),
        _buildContactSection(localizations),
        const SizedBox(height: 30),
        const Divider(height: 1),
        const SizedBox(height: 20),
        _buildCopyright(localizations),
      ],
    );
  }

  Widget _buildAboutSection(AppLocalizations? localizations) {
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
              child: SvgPicture.asset(
                'assets/image/Rbhan.svg',
                width: 50,
                height: 50,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              localizations?.translate('app_name') ?? 'ربحان',
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
          localizations?.translate('about_app_intro_body') ??
              'منصتك الأولى للحصول على أفضل العروض والخصومات من متاجرك المفضلة. وفّر المال واستمتع بتجربة تسوق ذكية.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.6,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSocialIcon({
    required dynamic svgPathOrIcon,
    required String url,
  }) {
    final colorHex =
        Constants.primaryColor.toARGB32().toRadixString(16).substring(2);

    Widget iconWidget;
    if (svgPathOrIcon == 'x') {
      iconWidget = SvgPicture.string(
        '<svg viewBox="0 0 24 24" fill="#$colorHex"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"></path></svg>',
        width: 20,
        height: 20,
      );
    } else if (svgPathOrIcon == 'instagram') {
      iconWidget = SvgPicture.string(
        '<svg viewBox="0 0 24 24" fill="#$colorHex"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.981 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"></path></svg>',
        width: 20,
        height: 20,
      );
    } else if (svgPathOrIcon == 'pinterest') {
      iconWidget = SvgPicture.string(
        '<svg viewBox="0 0 24 24" fill="#$colorHex"><path d="M12.017 0C5.396 0 .029 5.367.029 11.987c0 5.079 3.158 9.417 7.618 11.162-.105-.949-.199-2.403.041-3.439.219-.937 1.406-5.965 1.406-5.965s-.359-.719-.359-1.782c0-1.668.967-2.914 2.171-2.914 1.023 0 1.518.769 1.518 1.69 0 1.029-.655 2.568-.994 3.995-.283 1.194.599 2.169 1.777 2.169 2.133 0 3.772-2.249 3.772-5.495 0-2.873-2.064-4.882-5.012-4.882-3.414 0-5.418 2.561-5.418 5.207 0 1.031.397 2.138.893 2.738.098.119.112.224.083.345l-.333 1.36c-.053.22-.174.267-.402.161-1.499-.698-2.436-2.889-2.436-4.649 0-3.785 2.75-7.261 7.929-7.261 4.162 0 7.398 2.965 7.398 6.93 0 4.136-2.607 7.464-6.227 7.464-1.216 0-2.359-.631-2.75-1.378l-.748 2.853c-.271 1.043-1.002 2.35-1.492 3.146 1.124.347 2.317.535 3.554.535 6.622 0 11.988-5.365 11.988-11.987C24 5.369 18.633 0 12.017 0z"/></svg>',
        width: 20,
        height: 20,
      );
    } else {
      iconWidget = Icon(
        svgPathOrIcon is IconData ? svgPathOrIcon : Icons.link,
        size: 20,
        color: Constants.primaryColor,
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: iconWidget,
        onPressed: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      ),
    );
  }

  Widget _buildQuickLinks(
      BuildContext context, AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          localizations?.translate('quick_links') ?? 'روابط سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink(
            context, localizations?.translate('home') ?? 'الرئيسية', '/'),
        _buildFooterLink(context,
            localizations?.translate('stores') ?? 'المتاجر', '/stores'),
        _buildFooterLink(
            context, localizations?.translate('offers') ?? 'العروض', '/offers'),
        _buildFooterLink(context,
            localizations?.translate('favorites') ?? 'المفضلة', '/favorites'),
      ],
    );
  }

  Widget _buildLegalLinks(
      BuildContext context, AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          localizations?.translate('legal_info') ?? 'معلومات قانونية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        _buildFooterLink(
            context, localizations?.translate('about') ?? 'من نحن', '/about'),
        _buildFooterLink(
            context,
            localizations?.translate('privacy_policy') ?? 'Privacy Policy',
            '/privacy'),
        _buildFooterLink(
            context,
            localizations?.translate('terms_of_use') ?? 'Terms of Service',
            '/terms'),
        _buildFooterLink(context,
            localizations?.translate('faq') ?? 'الأسئلة الشائعة', '/faq'),
      ],
    );
  }

  Widget _buildContactSection(AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          localizations?.translate('contact_us') ?? 'تواصل معنا',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 16),
        _buildContactItem(Icons.email_rounded, 'support@rbhan.co'),
        const SizedBox(height: 8),
        // _buildContactItem(Icons.phone_rounded, '+966 XX XXX XXXX'),
        const SizedBox(height: 8),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSocialIcon(
              svgPathOrIcon: 'x',
              url: 'https://x.com/rbhanco',
            ),
            const SizedBox(width: 12),
            _buildSocialIcon(
              svgPathOrIcon: 'instagram',
              url: 'https://instagram.com/rbhan.co',
            ),
            const SizedBox(width: 12),
            _buildSocialIcon(
              svgPathOrIcon: 'pinterest',
              url: 'https://pinterest.com/rbhanco',
            ),
          ],
        ),
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

  Widget _buildCopyright(AppLocalizations? localizations) {
    return Center(
      child: Text(
        '© ${DateTime.now().year} ${localizations?.translate('app_name') ?? 'ربحان'}. ${localizations?.translate('rights_reserved_rbhan') ?? 'جميع الحقوق محفوظة.'}',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}
