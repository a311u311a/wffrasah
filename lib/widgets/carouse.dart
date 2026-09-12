import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants.dart';

class CustomCarousel extends StatefulWidget {
  const CustomCarousel({super.key});

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  List<Map<String, dynamic>> _lastItems = const [];
  late final Stream<List<Map<String, dynamic>>> _carouselStream;

  @override
  void initState() {
    super.initState();
    _carouselStream = Supabase.instance.client
        .from('carousel')
        .stream(primaryKey: ['id']).timeout(const Duration(seconds: 8),
            onTimeout: (sink) {
      sink.add(const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _carouselStream,
      initialData: _lastItems,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Carousel stream update failed: ${snapshot.error}');
          if (_lastItems.isEmpty) return const SizedBox.shrink();
        }

        final incomingItems = snapshot.data ?? [];
        if (incomingItems.isNotEmpty) {
          _lastItems = incomingItems;
        }

        final items = incomingItems.isNotEmpty ? incomingItems : _lastItems;
        if (items.isEmpty) return const SizedBox.shrink();

        return CarouselSlider(
          options: CarouselOptions(
            height: 176,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            viewportFraction: 0.99,
          ),
          items: items.map((item) {
            final imageUrl = (item['image'] ?? '').toString();
            final link = (item['url'] ?? item['web'] ?? '').toString();

            if (imageUrl.isEmpty) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () async {
                if (link.isEmpty) return;
                final uri = Uri.tryParse(link);
                if (uri == null) return;

                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                //margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Constants.primaryColor.withValues(alpha: 0.09),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.primaryColor.withValues(alpha: 0.10),
                      blurRadius: 4,
                      // offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.fill,
                  placeholder: (context, url) => Container(
                    color: Constants.primaryColor.withValues(alpha: 0.035),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Constants.primaryColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Constants.primaryColor.withValues(alpha: 0.035),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Constants.primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
