import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store.dart';

class StoreOffersScreen extends StatelessWidget {
  final Store store;
  const StoreOffersScreen({super.key, required this.store});

  Future<String?> _resolveStoreId(SupabaseClient sb) async {
    final rawId = store.id.trim();
    if (rawId.isNotEmpty) return rawId;

    final slug = store.slug.trim();
    if (slug.isEmpty) return null;

    final res =
        await sb.from('stores').select('id').eq('slug', slug).maybeSingle();

    return res?['id'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    return FutureBuilder<String?>(
      future: _resolveStoreId(sb),
      builder: (context, idSnap) {
        if (idSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final storeId = idSnap.data;
        if (storeId == null || storeId.isEmpty) {
          return const Center(child: Text('تعذر تحديد المتجر'));
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: sb
              .from('offers') // تأكدي اسم الجدول
              .stream(primaryKey: ['id'])
              .eq('store_id', storeId) // 🔥 UUID فقط
              .order('created_at', ascending: false),
          builder: (context, snap) {
            if (!snap.hasData &&
                snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final rows = snap.data ?? [];
            if (rows.isEmpty) {
              return const Center(
                  child: Text('لا توجد عروض لهذا المتجر حالياً'));
            }

            return ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) => Text(rows[i].toString()),
            );
          },
        );
      },
    );
  }
}
