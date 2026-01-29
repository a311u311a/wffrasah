import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/offers.dart';
import '../providers/favorites_provider.dart';
import '../localization/app_localizations.dart';

class OffersCard extends StatefulWidget {
  final Offer offer;
  const OffersCard({super.key, required this.offer});

  @override
  State<OffersCard> createState() => _OffersCardState();
}

class _OffersCardState extends State<OffersCard> {
  bool _isCopied = false;
  bool _isBusy = false;

  // ✅ 4:3
  static const double _imageAspectRatio = 4 / 3;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final bool isFavorite = favoriteProvider.isFavorite(widget.offer.id);

    final bool hasCode = widget.offer.tags.isNotEmpty &&
        widget.offer.tags.first.trim().isNotEmpty;
    final String fullCode = hasCode ? widget.offer.tags.first.trim() : "";

    return Card(
      margin: const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // HEADER (Image + Icons + Code Pill)
            // =========================
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ✅ صورة واحدة فقط (بدون تكرار) + بدون فراغات
                    Image.network(
                      widget.offer.image,
                      fit: BoxFit.fill, // ✅ يملأ بدون فراغات
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
                            Colors.black12,
                            Colors.transparent,
                            Colors.black38,
                          ],
                          stops: [0.0, 0.65, 1.0],
                        ),
                      ),
                    ),

                    // ✅ Code Pill (Bottom Right)
                    if (hasCode)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: _Pill(
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.confirmation_number_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                fullCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ✅ Action Buttons (Bottom Left)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Share
                          _IconActionPill(
                            onTap: () => _shareOffer(),
                            child: SvgPicture.asset(
                              'assets/icon/share.svg',
                              height: 18,
                              width: 18,
                              colorFilter: const ColorFilter.mode(
                                  Colors.white, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Favorite
                          _IconActionPill(
                            onTap: () => favoriteProvider.toggleFavorite(
                                widget.offer, context),
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
                                      colorFilter: const ColorFilter.mode(
                                          Color(0xFFFFD700), BlendMode.srcIn),
                                    )
                                  : SvgPicture.asset(
                                      'assets/icon/star.svg',
                                      key: const ValueKey('fav_inactive'),
                                      height: 18,
                                      width: 18,
                                      colorFilter: const ColorFilter.mode(
                                          Colors.white, BlendMode.srcIn),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================
            // BODY
            // =========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.offer.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Constants.textColor,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 16),

                  // زر النسخ والذهاب للمتجر
                  SizedBox(
                    height: 48,
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
                                      const Icon(Icons.check_circle_rounded,
                                          color: Colors.greenAccent, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        localizations?.translate('copied') ??
                                            'تم النسخ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fullCode,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
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
                                        size: 18,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      localizations?.translate(hasCode
                                              ? 'copy_and_go_to_store'
                                              : 'go_to_store_directly') ??
                                          (hasCode
                                              ? 'نسخ الكود والذهاب للمتجر'
                                              : 'اذهب للمتجر مباشرة'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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
    await SharePlus.instance.share(ShareParams(text: widget.offer.web));
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
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

// =========================
// Helper Widgets
// =========================

class _Pill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const _Pill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: borderRadius ?? BorderRadius.circular(30),
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
