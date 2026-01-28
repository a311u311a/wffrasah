import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/store.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_store_card.dart';

/// صفحة المتاجر للويب
class WebStoresScreen extends StatefulWidget {
  const WebStoresScreen({super.key});

  @override
  State<WebStoresScreen> createState() => _WebStoresScreenState();
}

class _WebStoresScreenState extends State<WebStoresScreen> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Store> allStores = [];
  List<Store> filteredStores = [];

  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final langCode = localeProvider.locale.languageCode;

    try {
      final storesData = await supabase
          .from('stores')
          .select()
          .order('name_ar', ascending: true);

      final loadedStores = (storesData as List)
          .map((store) => Store.fromSupabase(store, langCode))
          .toList();

      setState(() {
        allStores = loadedStores;
        filteredStores = loadedStores;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _filterStores(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredStores = allStores;
      } else {
        filteredStores = allStores.where((store) {
          return store.name.toLowerCase().contains(query.toLowerCase()) ||
              store.nameAr.toLowerCase().contains(query.toLowerCase()) ||
              store.nameEn.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            _buildHeader(),

            // Search Section
            _buildSearchSection(),

            // Stores Grid
            _buildStoresGrid(),

            // Footer
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'جميع المتاجر',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تصفح متاجرك المفضلة واحصل على أفضل العروض',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: ResponsivePadding.page(context),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: _filterStores,
              decoration: InputDecoration(
                hintText: 'ابحث عن متجر...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Tajawal',
                ),
                prefixIcon:
                    Icon(Icons.search_rounded, color: Constants.primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterStores('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'عدد المتاجر: ${filteredStores.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresGrid() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredStores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(
                Icons.store_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                searchQuery.isEmpty
                    ? 'لا توجد متاجر متاحة'
                    : 'لا توجد نتائج للبحث عن "$searchQuery"',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: ResponsivePadding.page(context),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveGrid.columns(context, max: 6),
          crossAxisSpacing: ResponsiveGrid.spacing(context),
          mainAxisSpacing: ResponsiveGrid.spacing(context),
          childAspectRatio: 0.85,
        ),
        itemCount: filteredStores.length,
        itemBuilder: (context, index) {
          return WebStoreCard(
            store: filteredStores[index],
            onTap: () {
              final store = filteredStores[index];
              Navigator.pushNamed(
                context,
                '/store/${store.slug}',
                arguments: store,
              );
            },
          );
        },
      ),
    );
  }
}
