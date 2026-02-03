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

/// بطاقة كوبون محسّنة للويب - بدون عرض اسم/أيقونة المتجر ✅
class WebCouponCard extends StatefulWidget {
  final Coupon coupon;
  final String? storeName; // موجود فقط للتوافق مع الاستدعاءات السابقة

  const WebCouponCard({
    super.key,
    required this.coupon,
    this.storeName,
  });

  @override
  State<WebCouponCard> createState() => _WebCouponCardState();
}

class _WebCouponCardState extends State<WebCouponCard> {
  bool isHovered = false;

  // ✅ يمنع ضغطات النسخ المتكررة بسرعة
  bool _copyLock = false;

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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            // ✅ تظبيط الظل للكارد فقط
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? Constants.primaryColor.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.07),
                blurRadius: isHovered ? 26 : 14,
                offset: Offset(0, isHovered ? 14 : 8),
                spreadRadius: isHovered ? 1 : 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
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

                  // ✅ المحتوى (بدون Badge المتجر)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          // منطقة النصوص القابلة للتمرير
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTitle(maxLines: 2),
                                  const SizedBox(height: 6),
                                  _buildDescription(
                                      maxLines:
                                          null), // ✅ بدون حد لتمكين التمرير
                                ],
                              ),
                            ),
                          ),

                          // العناصر المثبتة في الأسفل
                          const SizedBox(height: 8),
                          if (widget.coupon.code.isNotEmpty) ...[
                            _buildCouponCode(),
                            const SizedBox(height: 8),
                          ],
                          _buildActions(isFavorite, favoriteProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ صورة بارتفاع ثابت (لا تكبر/لا تُقص) + بدون ظل + بدون لون + Padding من جميع الجهات
  Widget _buildCouponImageFixedHeight(
      bool isFavorite, FavoriteProvider favoriteProvider) {
    const double outerPadding = 8; // ✅ Padding حول الصورة من كل الجهات
    const double imgHeight = 150;
    const double radius = 16;

    return Padding(
      padding: const EdgeInsets.all(outerPadding),
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
                fit: BoxFit.contain,

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
            top: 10,
            right: 10,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  favoriteProvider.toggleFavorite(widget.coupon, context);
                  HapticFeedback.mediumImpact();
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                    size: 20,
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        fontFamily: 'Tajawal',
        height: 1.2,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription({int? maxLines = 3}) {
    return Text(
      widget.coupon.description,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.35,
        fontFamily: 'Tajawal',
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  Widget _buildCouponCode() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Constants.primaryColor.withValues(alpha: 0.1),
              Constants.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Constants.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              'كود الخصم',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),

            const SizedBox(width: 12), // ✅ تقليل المسافة بين النص والبادج

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6), // ✅ أقل
                decoration: BoxDecoration(
                  color: Constants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      widget.coupon.code,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible, // ✅ بدون نقاط
                      style: const TextStyle(
                        fontSize: 13, // ✅ أصغر شوي عشان يظهر أكثر
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Courier',
                        letterSpacing: 1.0, // ✅ تقليل تباعد الحروف
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildActions(bool isFavorite, FavoriteProvider favoriteProvider) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _copyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    const Icon(Icons.copy_all_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      widget.coupon.code.isNotEmpty
                          ? 'نسخ واستخدام'
                          : 'استخدام العرض',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          height: 42,
          child: Material(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _share,
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.share_rounded,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
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
                  'تم نسخ الكود: ${widget.coupon.code}',
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
            '${widget.coupon.code.isNotEmpty ? "كود الخصم: ${widget.coupon.code}" : ""}',
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

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
