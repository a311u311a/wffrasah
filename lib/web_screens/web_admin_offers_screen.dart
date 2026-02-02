import 'package:flutter/material.dart';
import '../../screens/admin/admin_offers_screen.dart';

class WebAdminOffersScreen extends StatelessWidget {
  final bool isEmbedded;
  const WebAdminOffersScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return AdminOfferScreen(
      isEmbedded: isEmbedded,
    );
  }
}
