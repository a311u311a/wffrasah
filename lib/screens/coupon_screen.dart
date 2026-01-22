import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../widgets/coupons_list.dart';
import '../widgets/stores_list.dart';
import '../widgets/search_widget.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  String? selectedStoreId;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: _appBarItem(localizations),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60, top: 110),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: StoresList(
                  selectedStoreId: selectedStoreId,
                  onStoreSelected: (storeId) {
                    setState(() {
                      selectedStoreId = storeId;
                    });
                  },
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: CouponsList(
                  selectedStoreId: selectedStoreId,
                  searchQuery: searchQuery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBarItem(AppLocalizations? localizations) {
    return AppBar(
      toolbarHeight: 80,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // ✅ إصلاح المشكلة هنا
              Constants.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
      ),
      title: SearchWidget(
        hintText: localizations?.translate('search_hint') ?? 'بحث...',
        onSearch: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
      centerTitle: true,
    );
  }
}
