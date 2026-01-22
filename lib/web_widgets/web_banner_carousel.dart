import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/store.dart';
import '../constants.dart';
import 'responsive_layout.dart';

/// بنر متحرك احترافي يعرض صور المتاجر
class WebBannerCarousel extends StatefulWidget {
  final List<Store> stores;
  final Function(String storeId)? onStoreTap;

  const WebBannerCarousel({
    super.key,
    required this.stores,
    this.onStoreTap,
  });

  @override
  State<WebBannerCarousel> createState() => _WebBannerCarouselState();
}

class _WebBannerCarouselState extends State<WebBannerCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.stores.isEmpty) {
      return const SizedBox.shrink();
    }

    // فلترة المتاجر التي لديها صور فقط
    final storesWithImages =
        widget.stores.where((store) => store.image.isNotEmpty).toList();

    if (storesWithImages.isEmpty) {
      return const SizedBox.shrink();
    }

    // تحديد الارتفاع حسب حجم الشاشة
    final double bannerHeight = ResponsiveLayout.isDesktop(context)
        ? 500
        : ResponsiveLayout.isTablet(context)
            ? 400
            : 300;

    return Container(
      width: double.infinity,
      height: bannerHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // الـ Carousel
          CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: storesWithImages.length,
            itemBuilder: (context, index, realIndex) {
              return _buildBannerItem(storesWithImages[index], bannerHeight);
            },
            options: CarouselOptions(
              height: bannerHeight,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 1000),
              autoPlayCurve: Curves.easeInOutCubic,
              enlargeCenterPage: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),

          // النقاط المؤشرة (Dots Indicator)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildDotsIndicator(storesWithImages.length),
          ),

          // أزرار التنقل (للشاشات الكبيرة)
          if (ResponsiveLayout.isDesktop(context)) ...[
            _buildNavigationButton(
              isLeft: false,
              onPressed: () => _carouselController.previousPage(),
            ),
            _buildNavigationButton(
              isLeft: true,
              onPressed: () => _carouselController.nextPage(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerItem(Store store, double height) {
    return InkWell(
      onTap:
          widget.onStoreTap != null ? () => widget.onStoreTap!(store.id) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الصورة
          CachedNetworkImage(
            imageUrl: store.image,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Constants.primaryColor),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.store_rounded,
                size: 100,
                color: Colors.grey[400],
              ),
            ),
          ),

          // Gradient Overlay من الأسفل
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // معلومات المتجر
          Positioned(
            bottom: 60,
            right: 40,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم المتجر
                Text(
                  store.name,
                  style: TextStyle(
                    fontSize: ResponsiveLayout.isDesktop(context) ? 48 : 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // وصف المتجر
                if (store.description.isNotEmpty)
                  Text(
                    store.description,
                    style: TextStyle(
                      fontSize: ResponsiveLayout.isDesktop(context) ? 18 : 16,
                      color: Colors.white.withOpacity(0.95),
                      fontFamily: 'Tajawal',
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 20),

                // زر "تصفح العروض"
                ElevatedButton.icon(
                  onPressed: widget.onStoreTap != null
                      ? () => widget.onStoreTap!(store.id)
                      : null,
                  icon: const Icon(Icons.local_offer_rounded, size: 20),
                  label: const Text(
                    'تصفح العروض',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: Constants.primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Constants.primaryColor
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButton({
    required bool isLeft,
    required VoidCallback onPressed,
  }) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeft ? null : 20,
      right: isLeft ? 20 : null,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              size: 32,
            ),
            color: Constants.primaryColor,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          ),
        ),
      ),
    );
  }
}
