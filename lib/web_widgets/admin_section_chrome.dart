import 'package:flutter/material.dart';

import '../constants.dart';

/// Padding for admin screens shown inside the admin panel, so every section
/// lines up with the section header above it.
const EdgeInsets kAdminEmbeddedPadding = EdgeInsets.fromLTRB(24, 4, 24, 32);

/// Title row shown above every admin section in the web admin panel.
class AdminSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AdminSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Constants.primaryLightColor,
              borderRadius: BorderRadius.circular(Constants.radiusButton),
            ),
            child: Icon(icon, size: 21, color: Constants.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: Constants.primaryFontFamily,
                    fontSize: 22,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B3A),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: Constants.primaryFontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Constants.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
