import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../models/store.dart';

/// بطاقة متجر محسّنة للويب
class WebStoreCard extends StatefulWidget {
  final Store store;
  final VoidCallback? onTap;

  const WebStoreCard({
    super.key,
    required this.store,
    this.onTap,
  });

  @override
  State<WebStoreCard> createState() => _WebStoreCardState();
}

class _WebStoreCardState extends State<WebStoreCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.zero,
          margin:
              EdgeInsets.all(isHovered ? 0 : 4), // تعويض الحركة ليبقى في النطاق
          transform: Matrix4.identity()
            ..translateByDouble(0.0, isHovered ? -5.0 : 0.0, 0.0, 1.0),
          child: Card(
            elevation: isHovered ? 12 : 3,
            shadowColor: Constants.primaryColor.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // صورة المتجر
                  _buildStoreImage(),
                  const SizedBox(height: 12),
                  // اسم المتجر
                  _buildStoreName(),
                  const SizedBox(height: 6),
                  // عدد الكوبونات
                  _buildCouponCount(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                Constants.primaryColor.withValues(alpha: isHovered ? 0.3 : 0.1),
            blurRadius: isHovered ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.store.image,
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
              Icons.store_rounded,
              size: 40,
              color: Constants.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreName() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        widget.store.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          fontFamily: 'Tajawal',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCouponCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'كوبون متاح', // يمكن تعديله ليعرض العدد الفعلي
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Constants.primaryColor,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}
