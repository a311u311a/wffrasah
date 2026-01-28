// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ilfbqykxkjructxunuxm.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlsZmJxeWt4a2pydWN0eHVudXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MTkyODMsImV4cCI6MjA4MzI5NTI4M30.b3_5GkLGUlQCQI_B8XOhLUoK4YboPNn-FyhQCInZpxo';

void main() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  final client = Supabase.instance.client;

  // Test Store ID from user logs
  final storeId = '74a9c92a-452b-48c1-963d-bc6105625663';

  print('🔍 Checking coupons for Store ID: $storeId');

  try {
    final response =
        await client.from('coupons').select().eq('store_id', storeId);

    print('✅ Success! Found ${response.length} coupons.');
    if (response.isNotEmpty) {
      print('First coupon: ${response.first}');
    } else {
      // Try to fetch ANY coupon to see if table is empty or RLS is blocking
      print('⚠️ No coupons found for this store. Checking generic access...');
      final anyCoupon = await client.from('coupons').select().limit(1);
      print('   - Any random coupon check: ${anyCoupon.length} found.');
    }
  } catch (e) {
    print('❌ Error fetching coupons: $e');
  }
}
