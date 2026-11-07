import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// يبلّغ الشاشات فور إضافة متجر أو تعديله أو حذفه (Supabase Realtime على
/// جدول stores)، حتى تظهر الفئة المخفية بمجرد ربط متجر بها.
/// قناة واحدة مشتركة للتطبيق كله، تُفتح عند أول مستمع.
class StoresChanges {
  StoresChanges._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();
  static RealtimeChannel? _channel;
  static Timer? _debounce;

  /// false في الاختبارات حتى لا تبقى مؤقتات اتصال Realtime مفتوحة.
  static bool enabled = true;

  /// يطلق حدثاً بعد أي تغيير في المتاجر (مع تجميع التغييرات المتتالية).
  static Stream<void> get stream {
    _ensureSubscribed();
    return _controller.stream;
  }

  static void _ensureSubscribed() {
    if (!enabled || _channel != null) return;
    try {
      _channel = Supabase.instance.client
          .channel('public:stores:changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stores',
            callback: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 600), () {
                _controller.add(null);
              });
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('StoresChanges subscribe error: $e');
      _channel = null;
    }
  }
}
