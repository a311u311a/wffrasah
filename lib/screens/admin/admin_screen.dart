import 'package:wffrhasah/screens/admin/admin_offers_screen.dart';
import 'package:wffrhasah/widgets/bottom_navigation_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
// import '../services/admitad_service.dart'; // لو بتستخدمينه حدثيه لـ Supabase
import 'admin_stores_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_carousel_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_pending_coupons_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _supabase = Supabase.instance.client;
  // bool _isLoadingAdmitad = false; // Removed as requested

  Future<int> _countRows(String tableName) async {
    try {
      final rows = await _supabase.from(tableName).select('id');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  // (اختياري) إذا تبين Admitad لاحقًا
  // Future<void> _importFromAdmitad() async {
  //   setState(() => _isLoadingAdmitad = true);
  //   try {
  //     await AdmitadService().fetchAndSaveCoupons();
  //     if (mounted) {
  //       showSnackBar(context, 'تم استيراد الكوبونات بنجاح من Admitad');
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       showSnackBar(context, 'خطأ أثناء الاستيراد: $e', isError: true);
  //     }
  //   } finally {
  //     if (mounted) setState(() => _isLoadingAdmitad = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'لوحة التحكم ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Constants.primaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Constants.primaryColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor, size: 30),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BottomNavBar()),
              );
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Fixed Statistics Section
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = (constraints.maxWidth - 30) / 4;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      'المتاجر',
                      _countRows('stores'),
                      Colors.blue,
                      Icons.storefront_rounded,
                      cardWidth,
                    ),
                    _buildStatCard(
                      'الكوبونات',
                      _countRows('coupons'),
                      Colors.deepPurple,
                      Icons.confirmation_number_rounded,
                      cardWidth,
                    ),
                    _buildStatCard(
                      'العروض',
                      _countRows('offers'),
                      Colors.orange,
                      Icons.local_offer_rounded,
                      cardWidth,
                    ),
                    _buildStatCard(
                      'البنرات',
                      _countRows('carousel'),
                      Colors.teal,
                      Icons.photo_library_rounded,
                      cardWidth,
                    ),
                  ],
                );
              },
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "إدارة المحتوى",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 15),
                    _buildAdminButton(
                      context,
                      title: 'إدارة وإضافة المتاجر',
                      subtitle: 'إضافة متجر جديد، تعديل، أو حذف',
                      icon: Icons.storefront_rounded,
                      color: Colors.blueGrey,
                      destination: const AdminStoresScreen(),
                      countFuture: _countRows('stores'),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminButton(
                      context,
                      title: 'إدارة وإضافة الكوبونات',
                      subtitle: 'التحكم في أكواد الخصم المتاحة',
                      icon: Icons.confirmation_number_outlined,
                      color: Colors.deepPurple,
                      destination: const AdminCouponsScreen(),
                      countFuture: _countRows('coupons'),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminButton(
                      context,
                      title: 'كوبونات بانتظار الموافقة',
                      subtitle: 'مراجعة كوبونات Omolaat قبل النشر',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.amber,
                      destination: const AdminPendingCouponsScreen(),
                      countFuture: _countRows('admin_pending_coupons'),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminButton(
                      context,
                      title: 'إدارة الفئات',
                      subtitle: 'إضافة، تعديل، أو حذف فئات المتاجر والعروض',
                      icon: Icons.category_rounded,
                      color: Colors.indigo,
                      destination: const AdminCategoriesScreen(),
                      countFuture: _countRows('categories'),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminButton(
                      context,
                      title: 'إدارة وإضافة العروض',
                      subtitle: 'نشر عرض أو خصم جديد للمستخدمين',
                      icon: Icons.local_offer_rounded,
                      color: Colors.orange,
                      destination: const AdminOfferScreen(),
                      countFuture: _countRows('offers'),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminButton(
                      context,
                      title: 'إدارة شريط الصور (Carousel)',
                      subtitle: 'تعديل السلايدر الرئيسي في الصفحة الرئيسية',
                      icon: Icons.photo_library_outlined,
                      color: Colors.teal,
                      destination: const AdminCarouselScreen(),
                      countFuture: _countRows('carousel'),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminButton(
                      context,
                      title: 'إرسال إشعارات للمستخدمين',
                      subtitle: 'إرسال رسائل تنبيه لجميع مستخدمي التطبيق',
                      icon: Icons.notifications_active_rounded,
                      color: Colors.redAccent,
                      destination: const AdminNotificationsScreen(),
                      countFuture: _countRows('notifications'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ نفس ويدجت الكرت القديم بدون تغيير
  Widget _buildStatCard(
    String title,
    Future<int> future,
    Color color,
    IconData icon,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder<int>(
            future: future,
            builder: (context, snapshot) {
              return Text(
                '${snapshot.data ?? 0}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// ✅ نفس زر الإدارة القديم بدون تغيير
  Widget _buildAdminButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
    Future<int>? countFuture,
  }) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (countFuture != null) ...[
              _AdminButtonCountBadge(future: countFuture, color: color),
              const SizedBox(width: 10),
            ],
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _AdminButtonCountBadge extends StatelessWidget {
  final Future<int> future;
  final Color color;

  const _AdminButtonCountBadge({
    required this.future,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        return Container(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          alignment: Alignment.center,
          child: snapshot.connectionState == ConnectionState.waiting
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  '${snapshot.data ?? 0}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        );
      },
    );
  }
}
