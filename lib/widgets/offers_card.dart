import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/offers.dart';
import '../providers/favorites_provider.dart';
import '../localization/app_localizations.dart';
import '../services/analytics_service.dart';
import 'app_responsive.dart';

class OffersCard extends StatefulWidget {
  final Offer offer;
  final String? storeImage;

  const OffersCard({
    super.key,
    required this.offer,
    this.storeImage,
  });

  @override
  State<OffersCard> createState() => _OffersCardState();
}

class _OffersCardState extends State<OffersCard> {
  bool _isCopied = false;
  bool _isBusy = false;

  // ✅ 16:9
  static const double _imageAspectRatio = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final bool isFavorite = favoriteProvider.isFavorite(widget.offer.id);

    final bool hasCode = widget.offer.tags.isNotEmpty &&
        widget.offer.tags.first.trim().isNotEmpty;
    final String fullCode = hasCode ? widget.offer.tags.first.trim() : "";
    final scale = AppResponsive.tabletScale(context);
    final iconSize = 18.0 * scale;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final storeName = widget.offer.storeName.trim();
    final offerName = isEnglish && widget.offer.nameEn.trim().isNotEmpty
        ? widget.offer.nameEn.trim()
        : !isEnglish && widget.offer.nameAr.trim().isNotEmpty
            ? widget.offer.nameAr.trim()
            : widget.offer.name;
    final titleText = storeName.isNotEmpty
        ? storeName
        : widget.offer.storeId.trim().isNotEmpty
            ? widget.offer.storeId.trim()
            : offerName;
    final offerDescription =
        isEnglish && widget.offer.descriptionEn.trim().isNotEmpty
            ? widget.offer.descriptionEn.trim()
            : !isEnglish && widget.offer.descriptionAr.trim().isNotEmpty
                ? widget.offer.descriptionAr.trim()
                : widget.offer.description;
    final cardImage = (widget.storeImage?.trim().isNotEmpty ?? false)
        ? widget.storeImage!.trim()
        : widget.offer.storeImage.trim().isNotEmpty
            ? widget.offer.storeImage.trim()
            : widget.offer.image;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      color: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(
            color: Constants.primaryColor.withValues(alpha: 0.09),
          ),
          boxShadow: [
            BoxShadow(
              color: Constants.primaryColor.withValues(alpha: 0.08),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =========================
            // HEADER (Image + Icons + Code Pill)
            // =========================
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ✅ صورة واحدة فقط (بدون تكرار) + بدون فراغات
                    Image.network(
                      cardImage,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Container(
                          color: Colors.grey[50],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Constants.primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),

                    // Gradient Overlay (لتحسين وضوح الأيقونات/الكود)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black45,
                          ],
                          stops: [0.0, 0.58, 1.0],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 12,
                      right: 12,
                      child: _OfferTypeBadge(scale: scale),
                    ),
                    if (hasCode)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _OfferCodeBadge(code: fullCode, scale: scale),
                      ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w800,
                      color: Constants.storeNameColor,
                      height: 1.35,
                      fontFamily: 'Tajawal',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                  if (offerDescription.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      offerDescription,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: const Color(0xFF756F89),
                        height: 1.45,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ],
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _OfferMetaStrip(
                          hasCode: hasCode,
                          code: fullCode,
                          scale: scale,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconActionPill(
                        onTap: () => favoriteProvider.toggleFavorite(
                            widget.offer, context),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: isFavorite
                              ? _FavoriteStarIcon(
                                  key: const ValueKey('fav_active'),
                                  active: true,
                                  size: iconSize + 6,
                                )
                              : _FavoriteStarIcon(
                                  key: const ValueKey('fav_inactive'),
                                  active: false,
                                  size: iconSize + 6,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _IconActionPill(
                        onTap: () => _shareOffer(),
                        child: Icon(
                          Icons.share_rounded,
                          color: Constants.primaryColor,
                          size: iconSize + 6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // زر النسخ والذهاب للمتجر
                  SizedBox(
                    height: 48 * scale,
                    child: Material(
                      color: Constants.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _isBusy ? null : () => _onButtonTapped(),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 600),
                          opacity: _isBusy ? 0.7 : 1,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Copied Feedback
                              if (hasCode)
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 600),
                                  opacity: _isCopied ? 1.0 : 0.0,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Colors.greenAccent,
                                          size: 20 * scale),
                                      const SizedBox(width: 8),
                                      Text(
                                        localizations?.translate('copied') ??
                                            (isEnglish ? 'Copied' : 'تم النسخ'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14 * scale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fullCode,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15 * scale,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Default Label
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: _isCopied ? 0.0 : 1.0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isBusy)
                                      const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      Icon(
                                        hasCode
                                            ? Icons.copy_all_rounded
                                            : Icons.launch_rounded,
                                        color: Colors.white,
                                        size: 18 * scale,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      localizations?.translate(hasCode
                                              ? 'copy_and_go_to_store'
                                              : 'go_to_store_directly') ??
                                          (hasCode
                                              ? (isEnglish
                                                  ? 'Copy code & go to store'
                                                  : 'نسخ الكود والذهاب للمتجر')
                                              : (isEnglish
                                                  ? 'Go to store directly'
                                                  : 'اذهب للمتجر مباشرة')),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareOffer() async {
    final storeName = widget.offer.storeName.trim();
    final description = widget.offer.description.trim();
    final code = widget.offer.code.trim();
    final link = widget.offer.web.trim();
    final lines = [
      if (storeName.isNotEmpty) storeName,
      if (description.isNotEmpty) description,
      if (code.isNotEmpty) 'كود الخصم: $code',
      if (link.isNotEmpty) 'الرابط: $link',
    ];

    await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  Future<void> _onButtonTapped() async {
    final bool hasCode = widget.offer.tags.isNotEmpty &&
        widget.offer.tags.first.trim().isNotEmpty;

    if (!hasCode) {
      await _launchStore();
      return;
    }

    if (_isCopied || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _isCopied = true;
    });

    await Clipboard.setData(
      ClipboardData(text: widget.offer.tags.first.trim()),
    );
    unawaited(AnalyticsService.trackEvent(
      eventType: 'offer_copy',
      itemType: 'offer',
      itemId: widget.offer.id,
      storeId: widget.offer.storeId,
    ));

    await Future.delayed(const Duration(milliseconds: 800));
    await _launchStore();

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    setState(() {
      _isCopied = false;
      _isBusy = false;
    });
  }

  Future<void> _launchStore() async {
    try {
      final Uri url = Uri.parse(widget.offer.web);
      if (await canLaunchUrl(url)) {
        unawaited(AnalyticsService.trackEvent(
          eventType: 'store_click',
          itemType: 'offer',
          itemId: widget.offer.id,
          storeId: widget.offer.storeId,
        ));
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

// =========================
// Helper Widgets
// =========================

class _OfferTypeBadge extends StatelessWidget {
  final double scale;

  const _OfferTypeBadge({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_rounded,
            size: 15 * scale,
            color: Constants.primaryColor,
          ),
          SizedBox(width: 6 * scale),
          Text(
            'عرض',
            style: TextStyle(
              color: Constants.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 12 * scale,
              fontFamily: 'Tajawal',
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCodeBadge extends StatelessWidget {
  final String code;
  final double scale;

  const _OfferCodeBadge({
    required this.code,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 14 * scale,
            color: Colors.white,
          ),
          SizedBox(width: 6 * scale),
          Text(
            code,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12 * scale,
              letterSpacing: 1.1,
              fontFamily: 'monospace',
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferMetaStrip extends StatelessWidget {
  final bool hasCode;
  final String code;
  final double scale;

  const _OfferMetaStrip({
    required this.hasCode,
    required this.code,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer_rounded,
            color: Constants.primaryColor,
            size: 17 * scale,
          ),
          SizedBox(width: 7 * scale),
          Text(
            'عرض',
            style: TextStyle(
              color: Constants.primaryColor,
              fontSize: 13.5 * scale,
              fontWeight: FontWeight.w800,
              fontFamily: 'Tajawal',
              height: 1,
            ),
          ),
          if (hasCode) ...[
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: const Color(0xFF242032),
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 1.1,
                  height: 1,
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
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
    final scale = AppResponsive.tabletScale(context);
    final side = 40.0 * scale;
    return SizedBox(
      width: side,
      height: side,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        shadowColor: Constants.primaryColor.withValues(alpha: 0.12),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.18),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _FavoriteStarIcon extends StatelessWidget {
  final bool active;
  final double size;

  const _FavoriteStarIcon({
    super.key,
    required this.active,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      active ? 'assets/icon/star_active.svg' : 'assets/icon/star.svg',
      width: size,
      height: size,
      colorFilter:
          active ? null : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }
}
