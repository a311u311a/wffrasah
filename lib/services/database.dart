import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseMethods {
  final _supabase = Supabase.instance.client;

  Future<void> addUser(String userId, Map<String, dynamic> userInfoMap) async {
    // نفترض أن اسم الجدول في Supabase هو 'users'
    await _supabase.from('users').upsert({
      'id': userId,
      ...userInfoMap,
    });
  }

  // مثال لجلب البيانات بدلاً من Firestore Stream
  Stream<List<Map<String, dynamic>>> getStoresStream() {
    return _supabase.from('stores').stream(primaryKey: ['id']);
  }
}
