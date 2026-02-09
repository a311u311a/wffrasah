import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../models/offers.dart';
import '../providers/favorites_provider.dart';

/// بطاقة عرض (Offer) للويب
class WebOfferCard extends StatefulWidget {
  final Offer offer;
  final String? storeName;
  final String? storeImage; // ✅ الجديد: شعار المتجر

  const WebOfferCard({
    super.key,
    required this.offer,
    this.storeName,
    this.storeImage,
  });

  @override
  State<WebOfferCard> createState() => _WebOfferCardState();
}

class _WebOfferCardState extends State<WebOfferCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final isFavorite = favoriteProvider.isFavorite(widget.offer.id);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launchOffer,
        child: SizedBox(
          // ✅ تغطية المساحة الكاملة لضمان ثبات منطقة التفاعل
          child: Stack(
            children: [
              // طبقة شفافة ثابتة لمنع الوميض
              const Positioned.fill(
                  child: ColoredBox(color: Colors.transparent)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.all(isHovered ? 2 : 6),
                transform: Matrix4.identity()
                  ..translateByDouble(0.0, isHovered ? -4.0 : 0.0, 0.0, 1.0),
                child: Card(
                  elevation: isHovered ? 20 : 8, // ✅ ظلال أكثر وضوحاً
                  shadowColor: Constants.primaryColor.withValues(alpha: 0.35),
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
                        colors: [Colors.white, Colors.white],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // صورة العرض مع الكود عليها
                        _buildOfferImage(isFavorite, favoriteProvider),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // منطقة المحتوى القابلة للتمرير
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // صف اسم المتجر والكود
                                        _buildStoreAndCodeRow(),
                                        const SizedBox(height: 10),
                                        // الوصف
                                        _buildDescription(),
                                      ],
                                    ),
                                  ),
                                ),
                                // الأزرار مثبتة دائماً في الأسفل
                                _buildActions(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferImage(bool isFavorite, FavoriteProvider favoriteProvider) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 1.8 / 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الصورة
            CachedNetworkImage(
              imageUrl: widget.offer.image,
              fit: BoxFit.fill,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.local_mall_rounded,
                  size: 48,
                  color: Constants.primaryColor,
                ),
              ),
            ),
            // طبقة تعتيم خفيفة
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),

            // زر المفضلة
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    favoriteProvider.toggleFavorite(widget.offer, context);
                    HapticFeedback.mediumImpact();
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
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
      ),
    );
  }

  /// صف اسم المتجر (يمين) والكود (يسار)
  Widget _buildStoreAndCodeRow() {
    final hasCode = widget.offer.code.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // اسم المتجر على اليمين
        Expanded(
          child: Row(
            children: [
              // شعار المتجر إذا وجد
              if (widget.storeImage != null && widget.storeImage!.isNotEmpty)
                Container(
                  width: 35,
                  height: 35,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!),
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.storeImage!,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => Icon(
                          Icons.store_rounded,
                          size: 16,
                          color: Colors.grey[400]),
                    ),
                  ),
                ),
              // اسم المتجر
              Expanded(
                child: Text(
                  widget.storeName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Constants.primaryColor,
                    fontFamily: 'Tajawal',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // الكود على اليسار (إذا وجد) - قابل للنسخ
        if (hasCode)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.offer.code));
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم نسخ الكود: ${widget.offer.code}',
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Constants.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.content_copy_rounded,
                      size: 14,
                      color: Constants.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.offer.code,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                        fontFamily: 'Tajawal',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.offer.description,
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

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 16),
        Row(
          children: [
            // تصفح العرض
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _launchOffer,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text(
                  'مشاهدة العرض',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Tajawal',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // مشاركة
            IconButton(
              onPressed: _share,
              icon: Icon(Icons.share_rounded, color: Colors.grey[600]),
              tooltip: 'مشاركة',
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
          text:
              'شاهد هذا العرض المميز: ${widget.offer.name}\n${widget.offer.web}'),
    );
  }

  Future<void> _launchOffer() async {
    if (widget.offer.web.isNotEmpty) {
      final uri = Uri.parse(widget.offer.web);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
