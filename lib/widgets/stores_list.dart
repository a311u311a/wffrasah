import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../models/store.dart';
import 'error_message.dart';
import 'loading_indicator.dart';

class StoresList extends StatelessWidget {
  final Function(String?) onStoreSelected;
  final String? selectedStoreId; // slug غالباً

  const StoresList({
    super.key,
    required this.onStoreSelected,
    this.selectedStoreId,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final supabase = Supabase.instance.client;

    return SizedBox(
      height: 75,
      child: StreamBuilder<List<dynamic>>(
        stream: supabase
            .from('coupons')
            .stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, couponSnapshot) {
          if (couponSnapshot.hasError) return const SizedBox();
          if (!couponSnapshot.hasData) return const CustomLoadingIndicator();

          final couponRows =
              (couponSnapshot.data ?? []).cast<Map<String, dynamic>>();

          // ✅ كل القيم الموجودة في coupons.store_id (قد تكون slug أو id)
          final Set<String> activeStoreKeys = couponRows
              .map((c) => (c['store_id'] ?? c['storeId'])?.toString())
              .where((v) => v != null && v.trim().isNotEmpty)
              .cast<String>()
              .toSet();

          return StreamBuilder<List<dynamic>>(
            stream: supabase.from('stores').stream(
                primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, storeSnapshot) {
              if (storeSnapshot.hasError) {
                return ErrorMessage(
                  message: localizations?.translate('error_loading_stores') ??
                      'Error loading stores',
                );
              }
              if (!storeSnapshot.hasData) return const CustomLoadingIndicator();

              final storeRows =
                  (storeSnapshot.data ?? []).cast<Map<String, dynamic>>();

              final stores = storeRows
                  .map((data) => Store.fromSupabase(
                      data, localizations?.locale.languageCode ?? 'ar'))
                  .where((s) => s.slug.trim().isNotEmpty) // ✅ هنا
                  .where((s) =>
                      activeStoreKeys.contains(s.slug) ||
                      activeStoreKeys.contains(s.id))
                  .toList();

              // ✅ إزالة التكرار: نعتمد على "المفتاح" الفعلي للعرض (slug إن وجد وإلا id)
              final seen = <String>{};
              final displayStores = <Store>[];
              for (final s in stores) {
                final key = s.slug.trim().isNotEmpty ? s.slug : s.id;
                if (seen.contains(key)) continue;
                seen.add(key);
                displayStores.add(s);
              }

              // ✅ لو المتجر المحدد لم يعد موجوداً ضمن النشطين
              if (selectedStoreId != null &&
                  selectedStoreId!.isNotEmpty &&
                  !displayStores.any((s) {
                    final key = s.slug.trim().isNotEmpty ? s.slug : s.id;
                    return key == selectedStoreId;
                  })) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onStoreSelected(null);
                });
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                scrollDirection: Axis.horizontal,
                itemCount: displayStores.length + 1, // ✅ هنا
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildShowAllItem(context, selectedStoreId == null);
                  }

                  final store = displayStores[index - 1]; // ✅ هنا
                  final storeKey =
                      store.slug.trim().isNotEmpty ? store.slug : store.id;

                  return _buildStoreItem(
                    context,
                    store,
                    selectedStoreId == storeKey,
                    storeKey,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStoreItem(
    BuildContext context,
    Store store,
    bool isSelected,
    String storeKey,
  ) {
    return GestureDetector(
      onTap: () => onStoreSelected(storeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(
                  top: BorderSide(color: Constants.primaryColor, width: 2),
                  left: BorderSide(color: Constants.primaryColor, width: 2),
                  right: BorderSide(color: Constants.primaryColor, width: 2),
                  bottom: BorderSide(color: Constants.primaryColor, width: 20),
                )
              : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Constants.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 6 : 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Image.network(
              store.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.store, size: 40, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowAllItem(BuildContext context, bool isSelected) {
    final localizations = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => onStoreSelected(null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(
                  top: BorderSide(color: Constants.primaryColor, width: 2),
                  left: BorderSide(color: Constants.primaryColor, width: 2),
                  right: BorderSide(color: Constants.primaryColor, width: 2),
                  bottom: BorderSide(color: Constants.primaryColor, width: 20),
                )
              : Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Constants.primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 6 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icon/grid.svg',
              height: 30,
              width: 30,
              colorFilter: ColorFilter.mode(
                isSelected ? Constants.primaryColor : Colors.grey,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              localizations?.translate('show_all') ?? 'All',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Constants.primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
