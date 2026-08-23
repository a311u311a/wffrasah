import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/coupon.dart';
import '../providers/favorites_provider.dart';
import '../localization/app_localizations.dart';
import 'app_responsive.dart';

class CouponCard extends StatefulWidget {
  final Coupon coupon;
  final EdgeInsetsGeometry? margin;

  const CouponCard({super.key, required this.coupon, this.margin});

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool isCopied = false;
  // 🔹 تحكم عام بحجم الخط
  final double globalFontSize = 12;

  // ✅ تعديل فقط هنا: النسخ الرسمي بدون تغيير الأنيميشن
  Future<void> _copyCodeToClipboard(String code) async {
    if (code.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact(); // اختياري - ما يغيّر الأنيميشن

    if (!mounted) return;
    setState(() => isCopied = true);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => isCopied = false);
    });
  }

  Future<void> _shareCoupon(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${localizations.translate('coupon_code')}: ${widget.coupon.code}\n'
              '${localizations.translate('store')}: ${widget.coupon.name}',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations.translate('share_failed'),
          ),
        ),
      );
    }
  }

  Future<void> _visitStore() async {
    try {
      final Uri url = Uri.parse(widget.coupon.web);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Handle error safely without freezing
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isTablet = AppResponsive.isTablet(context);
    final scale = isTablet ? 1.05 : 1.0;
    final imageHeight = isTablet ? 120.0 : 125.0;
    final iconSize = 18.0 * scale;
    final actionGap = isTablet ? 8.0 : 12.0;
    final contentVerticalPadding = isTablet ? 6.0 : 8.0;
    final contentBottomPadding = isTablet ? 12.0 : contentVerticalPadding;
    final descriptionButtonGap = isTablet ? 10.0 : 16.0;
    final buttonHeight = isTablet ? 40.0 : 40.0 * scale;
    final fontSize = globalFontSize * scale;
    final descriptionMaxLines = isTablet ? 2 : 4;
    final buttonsRow =
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      /// COPY BUTTON (Expanded flex: 2)
      Expanded(
        flex: 3, // يأخذ ثلثي المساحة
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: buttonHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      label: Text(
                        '  ${widget.coupon.code}',
                        overflow: TextOverflow.ellipsis, // لضمان عدم خروج النص
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Constants.primaryColor,
                        padding: EdgeInsets.zero, // إزالة الهوامش الكبيرة
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Constants.primaryColor, width: 2),
                        ),
                      ),
                      onPressed: () {
                        _copyCodeToClipboard(widget.coupon.code);
                      },
                    ),
                  ),
                  Positioned.fill(
                    right: null,
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        _copyCodeToClipboard(widget.coupon.code);
                      },
                      child: AnimatedContainer(
                        width:
                            isCopied ? 100 : constraints.maxWidth, // عرض متغير
                        height: buttonHeight,
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              Constants.primaryColor,
                              Colors.transparent
                            ],
                            stops: const [0.5, 0.5],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Center(
                          child: isCopied
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 50),
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 24 * scale),
                                )
                              : Padding(
                                  padding: EdgeInsets.only(
                                      right: constraints.maxWidth *
                                          0.45), // ضبط مكان النص
                                  child: Text(
                                    localizations.translate('copy_code'),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),

      const SizedBox(width: 8),

      /// VISIT STORE BUTTON (Flexible flex: 1)
      Expanded(
        flex: 2, // يأخذ ثلث المساحة
        child: SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _visitStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              localizations.translate('visit_store'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ),
      ),
    ]);

    return Card(
      margin: widget.margin ??
          const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pinButtonsToBottom = constraints.hasBoundedHeight;
            final content = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
              ).copyWith(
                top: contentVerticalPadding,
                bottom: contentBottomPadding,
              ),
              child: Column(
                mainAxisAlignment: pinButtonsToBottom
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                children: [
                  Text(
                    widget.coupon.description,
                    textAlign: TextAlign.center,
                    maxLines: descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize - 1,
                      color: Colors.black,
                    ),
                  ),
                  if (!pinButtonsToBottom)
                    SizedBox(height: descriptionButtonGap),
                  buttonsRow,
                ],
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// ================= IMAGE =================
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      /// IMAGE
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            widget.coupon.image,
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.fill,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: imageHeight,
                                color: Colors.grey[200],
                                child: const Center(
                                    child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: imageHeight,
                                color: Colors.grey[400],
                                child: Icon(Icons.image_not_supported,
                                    size: 50 * scale),
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(width: actionGap),

                      /// SHARE + FAVORITE (Beside Image)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Share
                          _IconActionPill(
                            onTap: () => _shareCoupon(context),
                            child: SvgPicture.asset(
                              'assets/icon/share.svg',
                              height: iconSize,
                              width: iconSize,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Favorite
                          Consumer<FavoriteProvider>(
                            builder: (context, favoriteProvider, _) {
                              final isFavorite =
                                  favoriteProvider.isFavorite(widget.coupon.id);
                              return _IconActionPill(
                                onTap: () => favoriteProvider.toggleFavorite(
                                    widget.coupon, context),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: isFavorite
                                      ? SvgPicture.asset(
                                          'assets/icon/star_active.svg',
                                          key: const ValueKey('fav_active'),
                                          height: iconSize,
                                          width: iconSize,
                                          colorFilter: const ColorFilter.mode(
                                              Color(0xFFFFD700),
                                              BlendMode.srcIn),
                                        )
                                      : SvgPicture.asset(
                                          'assets/icon/star.svg',
                                          key: const ValueKey('fav_inactive'),
                                          height: iconSize,
                                          width: iconSize,
                                          colorFilter: const ColorFilter.mode(
                                              Colors.white, BlendMode.srcIn),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 5),
                    ],
                  ),
                ),

                /// ================= CONTENT =================
                if (pinButtonsToBottom) Expanded(child: content) else content,
              ],
            );
          },
        ),
      ),
    );
  }
}

// =========================
// Helper Widgets (Same as OffersCard)
// =========================

class _Pill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _Pill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
      ),
      child: child,
    );
  }
}

class _IconActionPill extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _IconActionPill({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scale = AppResponsive.isTablet(context) ? 1.05 : 1.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: _Pill(
          padding: EdgeInsets.all(8 * scale),
          child: child,
        ),
      ),
    );
  }
}
