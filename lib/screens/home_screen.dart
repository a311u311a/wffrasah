import 'package:flutter/material.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../widgets/coupons_list.dart';
import '../widgets/stores_list.dart';
import '../widgets/carouse.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedStoreId;
  bool isSearching = false;
  String searchQuery = ''; // نص البحث

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false, // يمنع انضغاط الواجهة عند ظهور الكيبورد
      backgroundColor: Colors.white,
      appBar: appBarItem(localizations),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60, top: 110),
          child: Column(
            children: [
              const CustomCarousel(),
              const SizedBox(height: 15),
              SizedBox(
                height:
                    100, // زيادة الارتفاع قليلاً لتناسب الحجم الجديد للمتاجر وظلالها
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
                  searchQuery: searchQuery, // تمرير نص البحث إلى CouponsList
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
      backgroundColor: Colors.transparent, // جعل الخلفية شفافة
      elevation: 0,
      surfaceTintColor: Colors.transparent, // منع تغير اللون عند التمرير
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Stack(
          // استخدمنا Stack لحل مشكلة المساحة
          alignment: Alignment.centerRight, // لضمان بقاء أيقونة البحث في مكانها
          children: [
            // العنوان يختفي تماماً عند البحث لتجنب الـ Overflow
            if (!isSearching)
              Align(
                alignment: Alignment.center,
                child: Text(
                  "الكوبونات",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Constants.primaryColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),

            // شريط البحث الأنميشن
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              // استخدمنا عرض الشاشة الكامل ناقص مسافة بسيطة للهوامش
              width:
                  isSearching ? MediaQuery.of(context).size.width * 0.90 : 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.white,
                boxShadow: kElevationToShadow[4],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: isSearching
                          ? TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              style: TextStyle(color: Constants.primaryColor),
                              decoration: InputDecoration(
                                hintText:
                                    localizations?.translate('search_hint') ??
                                        'بحث...',
                                hintStyle:
                                    TextStyle(color: Constants.primaryColor),
                                border: InputBorder.none,
                              ),
                            )
                          : const SizedBox
                              .shrink(), // استخدام shrink أفضل من null
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () {
                        setState(() {
                          if (isSearching) {
                            isSearching = false;
                            searchQuery = '';
                          } else {
                            isSearching = true;
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Icon(
                          isSearching ? Icons.close : Icons.search,
                          color: Constants.primaryColor,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
