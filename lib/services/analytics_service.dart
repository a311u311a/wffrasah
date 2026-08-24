import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  const AnalyticsService._();

  static Future<void> trackEvent({
    required String eventType,
    required String itemType,
    required String itemId,
    String? storeId,
  }) async {
    if (eventType.trim().isEmpty ||
        itemType.trim().isEmpty ||
        itemId.trim().isEmpty) {
      return;
    }

    try {
      final client = Supabase.instance.client;
      await client.from('analytics_events').insert({
        'event_type': eventType.trim(),
        'item_type': itemType.trim(),
        'item_id': itemId.trim(),
        'store_id': storeId?.trim().isEmpty ?? true ? null : storeId!.trim(),
        'user_id': client.auth.currentUser?.id,
      });
    } catch (error, stackTrace) {
      debugPrint('Analytics event ignored: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
