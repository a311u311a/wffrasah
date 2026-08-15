import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdmitadService {
  final SupabaseClient _sb = Supabase.instance.client;

  /// Imports Admitad coupons through a secure backend function.
  ///
  /// Configure the Supabase Edge Function `admitad-coupons-import` with the
  /// Admitad client id/secret as Supabase secrets. Do not put those values in
  /// the mobile app because they are extractable from Android APKs and iOS IPAs.
  Future<void> fetchAndSaveCoupons() async {
    try {
      final response = await _sb.functions.invoke('admitad-coupons-import');

      if (response.status < 200 || response.status >= 300) {
        debugPrint('Admitad import failed: ${response.data}');
      }
    } catch (e) {
      debugPrint('Admitad import error: $e');
    }
  }
}
