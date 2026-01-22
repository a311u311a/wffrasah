import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../models/coupon.dart';
import '../providers/favorites_provider.dart';

/// بطاقة كوبون محسّنة للويب - مع دعم اسم المتجر الاختياري
class WebCouponCard extends StatefulWidget {
  final Coupon coupon;
  final String? storeName; // اختياري - إذا كان متوفراً

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
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0.0, isHovered ? -8.0 : 0.0),
        child: Card(
          elevation: isHovered ? 12 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Constants.primaryColor.withOpacity(0.02),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // صورة الكوبون
                _buildCouponImage(),

                // محتوى الكوبون
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المتجر (إذا كان متوفراً)
                        if (widget.storeName != null) ...[
                          _buildStoreName(),
                          const SizedBox(height: 4),
                        ],

                        // عنوان الكوبون
                        _buildTitle(),
                        const SizedBox(height: 2),

                        // الوصف - يتمدد لملء المساحة المتبقية
                        Expanded(
                          child: _buildDescription(),
                        ),

                        // الإجراءات
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
    );
  }

  Widget _buildCouponImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: widget.coupon.image,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.local_offer_rounded,
              size: 48,
              color: Constants.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreName() {
    return Text(
      widget.storeName ?? 'متجر',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Constants.primaryColor,
        fontFamily: 'Tajawal',
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.coupon.name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        fontFamily: 'Tajawal',
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.coupon.description,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[600],
        height: 1.4,
        fontFamily: 'Tajawal',
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions(bool isFavorite, FavoriteProvider favoriteProvider) {
    return Row(
      children: [
        // نسخ الكود
        Expanded(
          child: SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _copyCode,
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: Text(
                widget.coupon.code.isNotEmpty ? 'نسخ الكود' : 'العرض',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: 'Tajawal',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // المفضلة
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => favoriteProvider.toggleFavorite(widget.coupon),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: isFavorite ? Colors.red : Colors.grey[600],
            ),
            tooltip: 'المفضلة',
          ),
        ),

        // مشاركة
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: _share,
            icon: Icon(Icons.share_rounded, size: 20, color: Colors.grey[600]),
            tooltip: 'مشاركة',
          ),
        ),
      ],
    );
  }

  void _copyCode() {
    if (widget.coupon.code.isNotEmpty) {
      FlutterClipboard.copy(widget.coupon.code).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ الكود بنجاح'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }

    // افتح الرابط إذا كان متوفراً
    if (widget.coupon.web.isNotEmpty) {
      _launchURL(widget.coupon.web);
    }
  }

  void _share() {
    Share.share(
      'تحقق من هذا العرض الرائع: ${widget.coupon.name}\nالكود: ${widget.coupon.code}',
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
