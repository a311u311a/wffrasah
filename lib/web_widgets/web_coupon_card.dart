import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
          ..translate(0.0, isHovered ? -10.0 : 0.0)
          ..scale(isHovered ? 1.02 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? Constants.primaryColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isHovered ? 20 : 10,
                offset: Offset(0, isHovered ? 8 : 4),
                spreadRadius: isHovered ? 2 : 0,
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
                  // ✅ الصورة
                  _buildCouponImageFixedHeight(isFavorite),

                  // ✅ المحتوى (بدون Badge المتجر)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ✅ حذفنا: اسم المتجر + أيقونة المتجر

                                    _buildTitle(maxLines: 2),
                                    const SizedBox(height: 6),

                                    _buildDescription(maxLines: 3),

                                    const Spacer(),

                                    if (widget.coupon.code.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      _buildCouponCode(),
                                      const SizedBox(height: 10),
                                    ] else ...[
                                      const SizedBox(height: 10),
                                    ],

                                    _buildActions(isFavorite, favoriteProvider),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

  /// ✅ صورة بارتفاع ثابت
  Widget _buildCouponImageFixedHeight(bool isFavorite) {
    return Stack(
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: widget.coupon.image,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[100],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Constants.primaryColor),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Constants.primaryColor.withValues(alpha: 0.1),
                    Constants.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.local_offer_rounded,
                  size: 64,
                  color: Constants.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.10),
                ],
              ),
            ),
          ),
        ),

        // Favorite icon
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
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
      ],
    );
  }

  Widget _buildTitle({int maxLines = 2}) {
    return Text(
      widget.coupon.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
        fontFamily: 'Tajawal',
        height: 1.2,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription({int maxLines = 3}) {
    return Text(
      widget.coupon.description,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[700],
        height: 1.35,
        fontFamily: 'Tajawal',
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCouponCode() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          Icon(
            Icons.confirmation_number_rounded,
            size: 18,
            color: Constants.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'كود الخصم',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Tajawal',
            ),
          ),
          const Spacer(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Constants.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.coupon.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Courier',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  void _copyCode() async {
    if (widget.coupon.code.isNotEmpty) {
      await FlutterClipboard.copy(widget.coupon.code);
      if (!mounted) return;

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
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (widget.coupon.web.isNotEmpty) {
      _launchURL(widget.coupon.web);
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
          text: '${widget.coupon.name}\n'
              '${widget.coupon.code.isNotEmpty ? "كود الخصم: ${widget.coupon.code}" : ""}'),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
