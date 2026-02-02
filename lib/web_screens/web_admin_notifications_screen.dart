import 'package:flutter/material.dart';
import '../../screens/admin/admin_notifications_screen.dart';

class WebAdminNotificationsScreen extends StatelessWidget {
  final bool isEmbedded;
  const WebAdminNotificationsScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return AdminNotificationsScreen(
      isEmbedded: isEmbedded,
    );
  }
}
