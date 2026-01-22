import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../models/offers.dart';

/// بطاقة عرض (Offer) للويب
class WebOfferCard extends StatefulWidget {
  final Offer offer;
  final String? storeName;

  const WebOfferCard({
    super.key,
    required this.offer,
    this.storeName,
  });

  @override
  State<WebOfferCard> createState() => _WebOfferCardState();
}

class _WebOfferCardState extends State<WebOfferCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    // ملاحظة: نحتاج للتأكد من أن FavoriteProvider يدعم العروض (Offer) أو إنشاء واحد جديد
    // حالياً سنفترض أنه للكوبونات فقط، لذا سنخفي زر المفضلة مؤقتاً أو نستخدم منطقاً مخصصاً
    // final favoriteProvider = Provider.of<FavoriteProvider>(context);
    // final isFavorite = favoriteProvider.isFavorite(widget.offer.id);

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
                  Colors.orange.withOpacity(0.03), // لون مختلف قليلاً للعروض
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // صورة العرض
                _buildOfferImage(),

                // محتوى العرض
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اسم المتجر (إذا كان متوفراً)
                        if (widget.storeName != null) ...[
                          _buildStoreName(),
                          const SizedBox(height: 8),
                        ],

                        // نوع "عرض"
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'عرض خاص',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // عنوان العرض
                        _buildTitle(),
                        const SizedBox(height: 8),

                        // الوصف
                        _buildDescription(),
                        const Spacer(),

                        // الإجراءات
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
    );
  }

  Widget _buildOfferImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: widget.offer.image,
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
              Icons.local_mall_rounded, // أيقونة مختلفة للعروض
              size: 48,
              color: Colors.orange,
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
      widget.offer.name,
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
                  backgroundColor: Colors.orange, // لون مميز للعروض
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

  void _share() {
    Share.share(
      'شاهد هذا العرض المميز: ${widget.offer.name}\n${widget.offer.web}',
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
