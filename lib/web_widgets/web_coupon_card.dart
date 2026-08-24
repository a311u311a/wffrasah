import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Clipboard الرسمي
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../constants.dart';
import '../models/coupon.dart';
import '../providers/favorites_provider.dart';
import '../services/analytics_service.dart';
import 'web_i18n.dart';

/// بطاقة كوبون محسّنة للويب - بدون عرض اسم/أيقونة المتجر ✅
class WebCouponCard extends StatefulWidget {
  final Coupon coupon;
  final String? storeName; // موجود فقط للتوافق مع الاستدعاءات السابقة
  final bool compact;

  const WebCouponCard({
    super.key,
    required this.coupon,
    this.storeName,
    this.compact = false,
  });

  @override
  State<WebCouponCard> createState() => _WebCouponCardState();
}

class _WebCouponCardState extends State<WebCouponCard> {
  bool isHovered = false;

  // ✅ يمنع ضغطات النسخ المتكررة بسرعة
  bool _copyLock = false;
  bool _copied = false;
  bool _showCode = false;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(widget.coupon.id);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.identity()
          ..translateByVector3(
              vector.Vector3(0.0, isHovered ? -10.0 : 0.0, 0.0))
          ..scaleByVector3(vector.Vector3.all(isHovered ? 1.02 : 1.0)),
        child: Card(
          elevation: isHovered ? 12 : 4,
          shadowColor: isHovered
              ? Constants.primaryColor.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Colors.grey,
              width: .5,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ الصورة: نفس الحجم (لا تكبر/تقص) + Padding من جميع الجهات
                _buildCouponImageFixedHeight(isFavorite, favoriteProvider),
                _buildSoftDivider(),

                // ✅ المحتوى (بدون Badge المتجر)
                Expanded(
                  child: Padding(
                    padding: widget.compact
                        ? const EdgeInsets.fromLTRB(10, 14, 10, 10)
                        : const EdgeInsets.all(8),
                    child: _buildContent(
                      isFavorite: isFavorite,
                      favoriteProvider: favoriteProvider,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoftDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 22 : 28),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Constants.primaryColor.withValues(alpha: 0.28),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool isFavorite,
    required FavoriteProvider favoriteProvider,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTitle(maxLines: 1),
              const SizedBox(height: 10),
              _buildDescription(maxLines: 2),
            ],
          )
        else
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(maxLines: 2),
                  const SizedBox(height: 6),
                  _buildDescription(maxLines: null),
                ],
              ),
            ),
          ),
        if (widget.compact) const Spacer(),
        SizedBox(height: widget.compact ? 16 : 8),
        if (widget.coupon.code.isNotEmpty) ...[
          _buildCouponCode(),
          SizedBox(height: widget.compact ? 6 : 8),
        ],
        _buildActions(isFavorite, favoriteProvider),
      ],
    );
  }

  /// ✅ صورة بارتفاع ثابت (لا تكبر/لا تُقص) + بدون ظل + بدون لون + Padding من جميع الجهات
  Widget _buildCouponImageFixedHeight(
      bool isFavorite, FavoriteProvider favoriteProvider) {
    final double outerPadding =
        widget.compact ? 20 : 10; // ✅ Padding حول الصورة من كل الجهات
    final double imgHeight = widget.compact ? 112 : 150;
    const double radius = 16;

    return Padding(
      padding: EdgeInsets.all(outerPadding),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              height: imgHeight,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: widget.coupon.image,

                // ✅ لا تكبر ولا تقص
                fit: BoxFit.fill,

                // ✅ بدون لون خلف الصورة أثناء التحميل
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),

                // ✅ بدون خلفية ملونة عند الخطأ
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.local_offer_rounded,
                    size: 58,
                    color: Constants.primaryColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),

          // Favorite icon (تنزيل/إضافة للمفضلة) ✅
          Positioned(
            top: widget.compact ? 1 : 10,
            right: widget.compact ? 1 : 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  favoriteProvider.toggleFavorite(widget.coupon, context);
                  HapticFeedback.mediumImpact();
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(widget.compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: widget.compact ? 17 : 20,
                    color: isFavorite ? Colors.red : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle({int maxLines = 2}) {
    return Text(
      widget.storeName ?? widget.coupon.name,
      style: TextStyle(
        fontSize: widget.compact ? 20 : 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        fontFamily: 'Tajawal',
        height: 1.2,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.compact ? TextAlign.center : TextAlign.start,
    );
  }

  Widget _buildDescription({int? maxLines = 3}) {
    return Text(
      widget.coupon.description,
      style: TextStyle(
        fontSize: widget.compact ? 18 : 13,
        color: Colors.grey[700],
        height: 1.20,
        fontFamily: 'Tajawal',
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      textAlign: widget.compact ? TextAlign.center : TextAlign.start,
    );
  }

  Widget _buildCouponCode() {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.coupon.code));

        setState(() {
          _showCode = true;
          _copied = true;
        });

        Future.delayed(const Duration(seconds: 8), () {
          if (!mounted) return;
          setState(() {
            _showCode = false;
            _copied = false;
          });
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 6 : 8,
          vertical: widget.compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: .5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 6 : 8,
                  vertical: widget.compact ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: (_showCode && _copied) ? Colors.green : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showCode
                        ? SingleChildScrollView(
                            key: const ValueKey('shown'),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ✅ تم النسخ
                                Text(
                                  webText(context, 'تم النسخ ✅', 'Copied'),
                                  style: TextStyle(
                                    fontSize: widget.compact ? 10.5 : 12,
                                    fontWeight: FontWeight.w900,
                                    color: (_copied)
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // ✅ الكوبون
                                Text(
                                  widget.coupon.code,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    fontSize: widget.compact ? 11.5 : 13,
                                    fontWeight: FontWeight.w900,
                                    color: (_copied)
                                        ? Colors.white
                                        : Constants.primaryColor,
                                    fontFamily: 'Courier',
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Row(
                            key: const ValueKey('hidden'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy,
                                  size: widget.compact ? 14 : 16,
                                  color: Colors.grey[600]),
                              SizedBox(width: widget.compact ? 4 : 6),
                              Flexible(
                                child: Text(
                                  webText(context, 'اضغط لنسخ الكوبون',
                                      'Tap to copy coupon'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: widget.compact ? 14 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    fontFamily: 'Tajawal',
                                  ),
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
    );
  }

  Widget _buildActions(bool isFavorite, FavoriteProvider favoriteProvider) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.compact ? 4 : 8,
        top: widget.compact ? 6 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: widget.compact ? 36 : 42,
              child: ElevatedButton(
                onPressed: _copyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(horizontal: widget.compact ? 4 : 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_all_rounded,
                          size: widget.compact ? 14 : 16),
                      SizedBox(width: widget.compact ? 4 : 6),
                      Text(
                        widget.coupon.code.isNotEmpty
                            ? webText(context, 'نسخ واستخدام', 'Copy & Use')
                            : webText(context, 'استخدام العرض', 'Use Offer'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: widget.compact ? 14 : 12,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: widget.compact ? 6 : 8),
          SizedBox(
            width: widget.compact ? 36 : 42,
            height: widget.compact ? 36 : 42,
            child: Material(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _share,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.share_rounded,
                  size: widget.compact ? 18 : 20,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode() async {
    if (widget.coupon.code.isEmpty) {
      // إذا ما فيه كود، افتح الرابط فقط لو موجود
      if (widget.coupon.web.isNotEmpty) {
        await _launchURL(widget.coupon.web);
      }
      return;
    }

    if (_copyLock) return;
    _copyLock = true;

    try {
      await Clipboard.setData(ClipboardData(text: widget.coupon.code));
      unawaited(AnalyticsService.trackEvent(
        eventType: 'coupon_copy',
        itemType: 'coupon',
        itemId: widget.coupon.id,
        storeId: widget.coupon.storeId,
      ));
      HapticFeedback.lightImpact();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  webText(
                    context,
                    'تم نسخ الكود: ${widget.coupon.code}',
                    'Code copied: ${widget.coupon.code}',
                  ),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // بعد النسخ افتح الرابط لو موجود
      if (widget.coupon.web.isNotEmpty) {
        await _launchURL(widget.coupon.web);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 350), () {
        _copyLock = false;
      });
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.coupon.name}\n'
            '${widget.coupon.code.isNotEmpty ? webText(context, "كود الخصم: ${widget.coupon.code}", "Discount code: ${widget.coupon.code}") : ""}',
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final raw = url.trim();
    if (raw.isEmpty) return;

    // ✅ محاولة parse آمنة + إضافة https إذا المستخدم مخزن بدون scheme
    Uri? uri = Uri.tryParse(raw);
    if (uri == null) return;

    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$raw');
      if (uri == null) return;
    }

    final ok = await canLaunchUrl(uri);
    if (!ok) return;

    unawaited(AnalyticsService.trackEvent(
      eventType: 'store_click',
      itemType: 'coupon',
      itemId: widget.coupon.id,
      storeId: widget.coupon.storeId,
    ));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
