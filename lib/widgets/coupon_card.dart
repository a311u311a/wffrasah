import 'dart:async';

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
import '../services/analytics_service.dart';
import 'app_responsive.dart';

class CouponCard extends StatefulWidget {
  final Coupon coupon;
  final EdgeInsetsGeometry? margin;
  final String? storeName;

  const CouponCard({
    super.key,
    required this.coupon,
    this.margin,
    this.storeName,
  });

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool isCopied = false;
  // 🔹 تحكم عام بحجم الخط
  final double globalFontSize = 13.5;

  // ✅ تعديل فقط هنا: النسخ الرسمي بدون تغيير الأنيميشن
  Future<void> _copyCodeToClipboard(String code) async {
    if (code.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    unawaited(AnalyticsService.trackEvent(
      eventType: 'coupon_copy',
      itemType: 'coupon',
      itemId: widget.coupon.id,
      storeId: widget.coupon.storeId,
    ));
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
        unawaited(AnalyticsService.trackEvent(
          eventType: 'store_click',
          itemType: 'coupon',
          itemId: widget.coupon.id,
          storeId: widget.coupon.storeId,
        ));
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
    final compactButtonHeight = 38.0 * scale;
    final fontSize = globalFontSize * scale;
    final descriptionMaxLines = isTablet ? 2 : 4;
    final imageActionsHeight = 36.0 * scale;
    final displayStoreName = widget.storeName?.trim() ?? '';
    final cardTopHeight = imageHeight + 26 + imageActionsHeight + 22;
    const buttonWidthFactor = 0.9;
    final buttonsRow = Column(mainAxisSize: MainAxisSize.min, children: [
      /// COPY BUTTON (Expanded flex: 2)
      LayoutBuilder(
        builder: (context, constraints) {
          return FractionallySizedBox(
            widthFactor: buttonWidthFactor,
            child: SizedBox(
              height: compactButtonHeight,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Constants.primaryColor.withValues(alpha: 0.08),
                        foregroundColor: Constants.primaryColor,
                        disabledBackgroundColor:
                            Constants.primaryColor.withValues(alpha: 0.08),
                        disabledForegroundColor: Constants.primaryColor,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        padding: EdgeInsets.zero, // إزالة الهوامش الكبيرة
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color:
                                Constants.primaryColor.withValues(alpha: 0.18),
                            width: 1,
                          ),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          Constants.primaryColor.withValues(alpha: 0.08),
                        ),
                      ),
                      onPressed: () {
                        _copyCodeToClipboard(widget.coupon.code);
                      },
                      child: Center(
                        child: Text(
                          '  ${widget.coupon.code}',
                          overflow:
                              TextOverflow.ellipsis, // لضمان عدم خروج النص
                          style: TextStyle(
                            fontSize: fontSize + 3,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    right: null,
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        _copyCodeToClipboard(widget.coupon.code);
                      },
                      child: Container(
                        height: compactButtonHeight,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              isCopied ? Colors.green : Constants.primaryColor,
                              Colors.transparent
                            ],
                            stops: const [0.97, 0.97],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (currentChild, previousChildren) {
                              return currentChild ?? const SizedBox.shrink();
                            },
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.98,
                                    end: 1,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: isCopied
                                ? Align(
                                    key: const ValueKey('copied_check'),
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: constraints.maxWidth *
                                          buttonWidthFactor *
                                          0.3,
                                      child: Center(
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 24 * scale,
                                        ),
                                      ),
                                    ),
                                  )
                                : Align(
                                    key: const ValueKey('copy_label'),
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: constraints.maxWidth *
                                          buttonWidthFactor *
                                          0.55,
                                      child: Center(
                                        child: Text(
                                          localizations.translate('copy_code'),
                                          style: TextStyle(
                                            fontSize: fontSize + 1,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      const SizedBox(height: 8),

      /// VISIT STORE BUTTON (Flexible flex: 1)
      FractionallySizedBox(
        widthFactor: buttonWidthFactor,
        child: SizedBox(
          height: compactButtonHeight,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _visitStore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor.withValues(alpha: 0.08),
              foregroundColor: Constants.primaryColor,
              disabledBackgroundColor:
                  Constants.primaryColor.withValues(alpha: 0.08),
              disabledForegroundColor: Constants.primaryColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Constants.primaryColor.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                Constants.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              localizations.translate('visit_store'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// ================= IMAGE =================
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: SizedBox(
                    height: cardTopHeight,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /// IMAGE
                        SizedBox(
                          width: constraints.maxWidth / 3,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.coupon.image,
                                    height: imageHeight,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: imageHeight,
                                        color: Colors.grey[100],
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
                                if (displayStoreName.isNotEmpty) ...[
                                  const SizedBox(height: 0),
                                  Text(
                                    displayStoreName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: fontSize - 2,
                                      fontWeight: FontWeight.w800,
                                      color: Constants.primaryColor
                                          .withValues(alpha: 1.0),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 1,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                  ),
                                  const SizedBox(height: 1),
                                ],
                                const Spacer(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _IconActionPill(
                                      onTap: () => _shareCoupon(context),
                                      child: SvgPicture.asset(
                                        'assets/icon/share.svg',
                                        height: iconSize,
                                        width: iconSize,
                                        colorFilter: ColorFilter.mode(
                                            Constants.primaryColor,
                                            BlendMode.srcIn),
                                      ),
                                    ),
                                    Consumer<FavoriteProvider>(
                                      builder: (context, favoriteProvider, _) {
                                        final isFavorite = favoriteProvider
                                            .isFavorite(widget.coupon.id);
                                        return _IconActionPill(
                                          onTap: () =>
                                              favoriteProvider.toggleFavorite(
                                                  widget.coupon, context),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 260),
                                            transitionBuilder: (child, anim) =>
                                                ScaleTransition(
                                                    scale: anim, child: child),
                                            child: isFavorite
                                                ? SvgPicture.asset(
                                                    'assets/icon/star_active.svg',
                                                    key: const ValueKey(
                                                        'fav_active'),
                                                    height: iconSize,
                                                    width: iconSize,
                                                    colorFilter:
                                                        const ColorFilter.mode(
                                                            Color(0xFFFFD700),
                                                            BlendMode.srcIn),
                                                  )
                                                : SvgPicture.asset(
                                                    'assets/icon/star.svg',
                                                    key: const ValueKey(
                                                        'fav_inactive'),
                                                    height: iconSize,
                                                    width: iconSize,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                            Constants
                                                                .primaryColor,
                                                            BlendMode.srcIn),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: actionGap / 2),
                        Container(
                          width: 1,
                          color: Colors.grey[200],
                        ),
                        SizedBox(width: actionGap / 2),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: contentVerticalPadding,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      widget.coupon.description,
                                      textAlign: TextAlign.center,
                                      maxLines: descriptionMaxLines,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        color: Colors.grey[550],
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ),
                                buttonsRow,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      width: 38,
      height: 38,
      padding: padding,
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
        borderRadius: BorderRadius.circular(10),
        child: _Pill(
          padding: EdgeInsets.all(9 * scale),
          child: child,
        ),
      ),
    );
  }
}
