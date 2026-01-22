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

class CouponCard extends StatefulWidget {
  final Coupon coupon;

  const CouponCard({super.key, required this.coupon});

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool isCopied = false;
  // 🔹 تحكم عام بحجم الخط
  final double globalFontSize = 12;

  void _copyCodeToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => isCopied = true);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => isCopied = false);
    });
  }

  void _shareCoupon(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    Share.share(
      '${localizations.translate('coupon_code')}: ${widget.coupon.code}\n'
      '${localizations.translate('store')}: ${widget.coupon.name}',
    );
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

    return Card(
      margin: const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
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
                        height: 125,
                        width: double.infinity,
                        fit: BoxFit.fill,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 125,
                            color: Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 125,
                            color: Colors.grey[400],
                            child:
                                const Icon(Icons.image_not_supported, size: 50),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// SHARE + FAVORITE (Beside Image)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Share
                      _IconActionPill(
                        onTap: () => _shareCoupon(context),
                        child: SvgPicture.asset(
                          'assets/icon/share.svg',
                          height: 18,
                          width: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Favorite
                      Consumer<FavoriteProvider>(
                        builder: (context, favoriteProvider, _) {
                          final isFavorite =
                              favoriteProvider.isFavorite(widget.coupon.id);
                          return _IconActionPill(
                            onTap: () =>
                                favoriteProvider.toggleFavorite(widget.coupon),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: isFavorite
                                  ? SvgPicture.asset(
                                      'assets/icon/star_active.svg',
                                      key: const ValueKey('fav_active'),
                                      height: 18,
                                      width: 18,
                                      color: const Color(0xFFFFD700),
                                    )
                                  : SvgPicture.asset(
                                      'assets/icon/star.svg',
                                      key: const ValueKey('fav_inactive'),
                                      height: 18,
                                      width: 18,
                                      color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Text(
                    widget.coupon.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: globalFontSize - 1,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// COPY CODE (FLEXIBLE SIZE) + VISIT STORE
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    /// COPY BUTTON (Expanded flex: 2)
                    Expanded(
                      flex: 3, // يأخذ ثلثي المساحة
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    label: Text(
                                      '  ${widget.coupon.code}',
                                      overflow: TextOverflow
                                          .ellipsis, // لضمان عدم خروج النص
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Constants.primaryColor,
                                      padding: EdgeInsets
                                          .zero, // إزالة الهوامش الكبيرة
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                            color: Constants.primaryColor,
                                            width: 2),
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
                                      width: isCopied
                                          ? 100
                                          : constraints.maxWidth, // عرض متغير
                                      height: 40,
                                      duration:
                                          const Duration(milliseconds: 300),
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
                                            ? const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 50),
                                                child: Icon(Icons.check,
                                                    color: Colors.white,
                                                    size: 24),
                                              )
                                            : Padding(
                                                padding: EdgeInsets.only(
                                                    right: constraints
                                                            .maxWidth *
                                                        0.45), // ضبط مكان النص
                                                child: Text(
                                                  localizations
                                                      .translate('copy_code'),
                                                  style: TextStyle(
                                                    fontSize: globalFontSize,
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
                        height: 40,
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
                            style: TextStyle(fontSize: globalFontSize),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
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
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: _Pill(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }
}
