import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// ⚠️ Important security note:
/// Never ship your Admitad client secret inside the public app.
/// Prefer: call a secure backend / Supabase Edge Function that holds the secret.
/// This file keeps the same behavior as your Firebase version for now.
class AdmitadService {
  static const String _clientId = 'e651462eac981c3179227b7cf0f5fb';
  static const String _clientSecret = 'BpGCkU2GZ2BHiI8lqmNtmKBXxjyRA4';

  final SupabaseClient _sb = Supabase.instance.client;

  Future<String?> getAccessToken() async {
    final url = Uri.parse('https://api.admitad.com/token/');
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$_clientId:$_clientSecret'))}';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': basicAuth,
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': _clientId,
          'scope': 'coupons public_data',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch coupons from Admitad and save to Supabase `coupons` table.
  /// Requires your current user to be an admin (RLS policies).
  Future<void> fetchAndSaveCoupons() async {
    final token = await getAccessToken();
    if (token == null) return;

    final url = Uri.parse('https://api.admitad.com/coupons/?limit=50&active=true');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final List results = data['results'] ?? [];

    for (final item in results) {
      final String name = (item['name'] ?? 'عرض مميز').toString();
      final String code = (item['promocode'] ?? '').toString();
      final String link = (item['goto_link'] ?? '').toString();

      // store id/slug (best effort)
      String storeId = 'store';
      if (item['campaign'] != null && item['campaign']['name'] != null) {
        storeId = item['campaign']['name'].toString().trim().toLowerCase();
        storeId = storeId.replaceAll(RegExp(r'\s+'), '');
      }

      // Insert into coupons table.
      // Your coupons schema: id, code, created_at, description, description_ar, description_en,
      // image, name, name_ar, name_en, store_id, tags, web
      await _sb.from('coupons').insert({
        'code': code,
        'created_at': DateTime.now().toIso8601String(),
        'description': name,
        'name': name,
        'web': link,
        'store_id': storeId,
        'tags': jsonEncode(<String>[]),
      });
    }
  }
}
