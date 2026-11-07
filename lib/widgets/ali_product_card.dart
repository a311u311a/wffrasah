import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/ali_product.dart';
import '../services/analytics_service.dart';

/// يفتح رابط العمولة خارج التطبيق (متصفح أو تطبيق علي إكسبرس) حتى يُحتسب التتبّع.
Future<void> openAliProduct(BuildContext context, AliProduct product) async {
  final uri = Uri.tryParse(product.promotionLink);
  if (uri == null) return;

  unawaited(AnalyticsService.trackEvent(
    eventType: 'store_click',
    itemType: 'ali_product',
    itemId: product.productId.toString(),
    storeId: 'aliexpress',
  ));

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط المنتج')),
      );
    }
  } catch (e) {
    debugPrint('openAliProduct error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط المنتج')),
      );
    }
  }
}

class AliProductCard extends StatelessWidget {
  final AliProduct product;
  final double? width;

  const AliProductCard({super.key, required this.product, this.width});

  static const _aliOrange = Color(0xFFEA5C2B);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: width,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openAliProduct(context, product),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Constants.mutedBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Constants.backgroundColor,
                          child: product.image.isEmpty
                              ? const Icon(Icons.shopping_bag_outlined,
                                  color: Constants.disabledTextColor, size: 36)
                              : CachedNetworkImage(
                                  imageUrl: product.image,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                  placeholder: (_, __) => const SizedBox(),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: Constants.disabledTextColor,
                                  ),
                                ),
                        ),
                        if (product.hasDiscount)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Constants.errorColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-${product.discountPercent}%',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: Constants.textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _PriceRow(product: product),
                        const SizedBox(height: 8),
                        Container(
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _aliOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'اشترِ الآن',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final AliProduct product;
  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final isSar = product.currency.toUpperCase() == 'SAR';
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AliProduct.formatPrice(product.salePrice),
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AliProductCard._aliOrange,
              ),
            ),
            const SizedBox(width: 3),
            if (isSar)
              SvgPicture.asset(
                'assets/icon/Saudi_Riyal_Symbol-2.svg',
                width: 13,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  AliProductCard._aliOrange,
                  BlendMode.srcIn,
                ),
              )
            else
              Text(
                product.currency,
                style: const TextStyle(
                  fontSize: 11,
                  color: AliProductCard._aliOrange,
                ),
              ),
          ],
        ),
        if (product.hasDiscount)
          Text(
            AliProduct.formatPrice(product.originalPrice),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Constants.secondaryTextColor,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}
