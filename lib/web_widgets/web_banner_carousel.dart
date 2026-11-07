import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/carousel.dart';
import '../constants.dart';
import 'responsive_layout.dart';
import 'web_i18n.dart';
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

    // الارتفاع يتبع عرض الصفحة حتى تظهر الصورة كاملة بدون قص.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final ratio = ResponsiveLayout.isMobile(context) ? 2.0 : 2.4;
        final bannerHeight = (width / ratio).clamp(160.0, 560.0);
        return _buildCarousel(itemsWithImages, bannerHeight);
      },
    );
  }

  Widget _buildCarousel(List<Carousel> itemsWithImages, double bannerHeight) {
    final isMobile = ResponsiveLayout.isMobile(context);
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
              bottom: isMobile ? 10 : 20,
              left: isMobile ? 16 : 30, // تغيير المكان لليسار
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
    final isMobile = ResponsiveLayout.isMobile(context);
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
          _RetryingWebBannerImage(imageUrl: item.image),

          // تدرج لوني قوي (Cinematic Gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
                stops: const [0.78, 1.0],
              ),
            ),
          ),

          // المحتوى النصي
          Positioned(
            bottom: isMobile ? 10 : 24,
            right: isMobile ? 12 : 28, // RTL alignment
            left: isMobile ? 12 : 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الإجراء (Call to Action)
                      if (item.web.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 22,
                              vertical: isMobile ? 6 : 11),
                          decoration: BoxDecoration(
                            color: Constants.primaryColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                webText(context, 'تسوق الآن', 'Shop Now'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: isMobile ? 14 : 18,
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

class _RetryingWebBannerImage extends StatefulWidget {
  final String imageUrl;

  const _RetryingWebBannerImage({required this.imageUrl});

  @override
  State<_RetryingWebBannerImage> createState() =>
      _RetryingWebBannerImageState();
}

class _RetryingWebBannerImageState extends State<_RetryingWebBannerImage> {
  static const int _maxRetries = 3;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  @override
  void didUpdateWidget(covariant _RetryingWebBannerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryTimer?.cancel();
      _retryAttempt = 0;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.imageUrl.trim();

    final url = _imageUrlForAttempt(imageUrl);
    return Stack(
      fit: StackFit.expand,
      children: [
        // نسخة مموّهة تملأ الفراغ حول الصورة إذا اختلفت نسبتها عن البنر.
        ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
        _buildFullImage(imageUrl, url),
      ],
    );
  }

  Widget _buildFullImage(String imageUrl, String url) {
    return Image.network(
      url,
      key: ValueKey('$imageUrl-$_retryAttempt'),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _bannerImageFallback(showLoader: true);
      },
      errorBuilder: (context, error, stackTrace) {
        _scheduleRetry();
        return _bannerImageFallback(showLoader: _retryAttempt < _maxRetries);
      },
    );
  }

  String _imageUrlForAttempt(String imageUrl) {
    if (_retryAttempt == 0) return imageUrl;

    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasScheme) return imageUrl;

    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      '_wffr_web_retry': _retryAttempt.toString(),
    }).toString();
  }

  void _scheduleRetry() {
    if (_retryAttempt >= _maxRetries || _retryTimer?.isActive == true) return;

    final attempt = _retryAttempt + 1;
    final delay = Duration(milliseconds: 600 * attempt);
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _retryAttempt = attempt;
      });
    });
  }

  Widget _bannerImageFallback({required bool showLoader}) {
    return Container(
      color: Colors.grey[900],
      alignment: Alignment.center,
      child: showLoader
          ? SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.32),
              ),
            )
          : const Icon(Icons.broken_image, color: Colors.white24, size: 50),
    );
  }
}
