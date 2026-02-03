import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/carousel.dart';
import '../constants.dart';
import 'responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

/// بنر متحرك بتصميم سينمائي حديث
class WebBannerCarousel extends StatefulWidget {
  final List<Carousel> items;

  const WebBannerCarousel({
    super.key,
    required this.items,
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
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // فلترة العناصر التي لديها صور فقط
    final itemsWithImages =
        widget.items.where((item) => item.image.isNotEmpty).toList();

    if (itemsWithImages.isEmpty) {
      return const SizedBox.shrink();
    }

    // تحديد الارتفاع حسب حجم الشاشة
    final double bannerHeight = ResponsiveLayout.isDesktop(context)
        ? 380
        : ResponsiveLayout.isTablet(context)
            ? 300
            : 200;

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // الـ Carousel
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: itemsWithImages.length,
              itemBuilder: (context, index, realIndex) {
                return _buildBannerItem(itemsWithImages[index], bannerHeight);
              },
              options: CarouselOptions(
                height: bannerHeight,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),

            // مؤشرات التقدم
            Positioned(
              bottom: 20,
              left: 30, // تغيير المكان لليسار
              child: _buildIndicators(itemsWithImages.length),
            ),

            // أزرار التنقل (شفافة وكبيرة على الجوانب)
            if (ResponsiveLayout.isDesktop(context)) ...[
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _buildSideNavButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => _carouselController.previousPage(),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _buildSideNavButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: () => _carouselController.nextPage(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBannerItem(Carousel item, double height) {
    return InkWell(
      onTap: () async {
        if (item.web.isNotEmpty) {
          final Uri url = Uri.parse(item.web);
          if (!await launchUrl(url)) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch ${item.web}')),
            );
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // الصورة
          CachedNetworkImage(
            imageUrl: item.image,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image,
                  color: Colors.white24, size: 50),
            ),
          ),

          // تدرج لوني قوي (Cinematic Gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),

          // المحتوى النصي
          Positioned(
            bottom: 40,
            right: 40, // RTL alignment
            left: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.name.isNotEmpty) const SizedBox(height: 16),
                      // زر الإجراء (Call to Action)
                      if (item.web.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Constants.primaryColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'تسوق الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators(int count) {
    return Row(
      children: List.generate(count, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Constants.primaryColor
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildSideNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: double.infinity,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.8),
            size: 24,
          ),
        ),
      ),
    );
  }
}
