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
                  elevation: isHovered ? 12 : 3,
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
                          Constants.primaryColor.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ✅ رأس البطاقة المحسّن: يظهر أولاً قبل الصورة
                        if (widget.storeName != null ||
                            widget.storeImage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: _buildStoreHeader(),
                          ),

                        // صورة العرض
                        _buildOfferImage(isFavorite, favoriteProvider),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // منطقة المحتوى القابلة للتمرير (العنوان والوصف)
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTitle(),
                                        const SizedBox(height: 8),
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
      child: AspectRatio(
        aspectRatio: 2.3 / 1, // ✅ تصغير الارتفاع
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
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
            ),
            // Favorite button
            Positioned(
              top: 10,
              right: 10,
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
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Row(
      children: [
        if (widget.storeImage != null)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[100]!),
              color: Colors.white,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: widget.storeImage!,
                fit: BoxFit.contain,
                errorWidget: (context, url, error) =>
                    const Icon(Icons.store_rounded, size: 20),
              ),
            ),
          ),
        if (widget.storeImage != null) const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.storeName ?? 'متجر',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
