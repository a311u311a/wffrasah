import 'package:flutter/material.dart';
import '../../screens/admin/admin_carousel_screen.dart';

class WebAdminCarouselScreen extends StatelessWidget {
  final bool isEmbedded;
  const WebAdminCarouselScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return AdminCarouselScreen(
      isEmbedded: isEmbedded,
    );
  }
}
