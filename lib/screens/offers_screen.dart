// صفحة العروض

import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../widgets/carouse.dart'; // يتضمن CustomCarousel
import '../widgets/category_list.dart';
import '../widgets/offers_list.dart';
import '../widgets/search_widget.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  String? selectedCategoryId;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: appBarItem(localizations),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60, top: 110),
          child: Column(
            children: [
              const SizedBox(
                height: 150,
                child: CustomCarousel(),
              ),
              SizedBox(
                height: 95,
                child: CategoryList(
                  selectedCategoryId: selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    setState(() {
                      selectedCategoryId = categoryId;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: OffersList(
                  selectedCategoryId: selectedCategoryId,
                  searchQuery: searchQuery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget appBarItem(AppLocalizations? localizations) {
    return AppBar(
      toolbarHeight: 80,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: SearchWidget(
        hintText:
            localizations?.translate('search_offer_hint') ?? 'البحث عن عرض',
        onSearch: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }
}
