import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// لوحة التحكم للويب (Admin Panel)
class WebAdminScreen extends StatefulWidget {
  const WebAdminScreen({super.key});

  @override
  State<WebAdminScreen> createState() => _WebAdminScreenState();
}

class _WebAdminScreenState extends State<WebAdminScreen> {
  final _supabase = Supabase.instance.client;

  /// Stream للحصول على عدد العناصر من كل جدول
  Stream<int> _countStream(String tableName) {
    return _supabase
        .from(tableName)
        .stream(primaryKey: ['id']).map((rows) => rows.length);
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
            _buildHeader(),
            _buildContent(),
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
            Constants.primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: Constants.primaryColor,
                size: ResponsiveLayout.isDesktop(context) ? 48 : 36,
              ),
              const SizedBox(width: 16),
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
                  fontWeight: FontWeight.w900,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'إدارة محتوى التطبيق والمتاجر والكوبونات',
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

  Widget _buildContent() {
    return Container(
      padding: ResponsivePadding.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نظرة عامة
          Text(
            'نظرة عامة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 20),

          // إحصائيات
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'المتاجر',
                _countStream('stores'),
                Colors.blue,
                Icons.storefront_rounded,
              ),
              _buildStatCard(
                'الكوبونات',
                _countStream('coupons'),
                Colors.deepPurple,
                Icons.confirmation_number_rounded,
              ),
              _buildStatCard(
                'العروض',
                _countStream('offers'),
                Colors.orange,
                Icons.local_offer_rounded,
              ),
              _buildStatCard(
                'البنرات',
                _countStream('carousel'),
                Colors.teal,
                Icons.photo_library_rounded,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // إدارة المحتوى
          Text(
            'إدارة المحتوى',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 20),

          // أزرار الإدارة
          _buildAdminButton(
            title: 'إدارة وإضافة المتاجر',
            subtitle: 'إضافة متجر جديد، تعديل، أو حذف',
            icon: Icons.storefront_rounded,
            color: Colors.blueGrey,
            onTap: () {
              // TODO: Navigate to admin stores
              _showComingSoon();
            },
          ),
          const SizedBox(height: 16),

          _buildAdminButton(
            title: 'إدارة وإضافة الكوبونات',
            subtitle: 'التحكم في أكواد الخصم المتاحة',
            icon: Icons.confirmation_number_outlined,
            color: Colors.deepPurple,
            onTap: () {
              // TODO: Navigate to admin coupons
              _showComingSoon();
            },
          ),
          const SizedBox(height: 16),

          _buildAdminButton(
            title: 'إدارة وإضافة العروض',
            subtitle: 'نشر عرض أو خصم جديد للمستخدمين',
            icon: Icons.local_offer_rounded,
            color: Colors.orange,
            onTap: () {
              // TODO: Navigate to admin offers
              _showComingSoon();
            },
          ),
          const SizedBox(height: 16),

          _buildAdminButton(
            title: 'إدارة شريط الصور (Carousel)',
            subtitle: 'تعديل السلايدر الرئيسي في الصفحة الرئيسية',
            icon: Icons.photo_library_outlined,
            color: Colors.teal,
            onTap: () {
              // TODO: Navigate to admin carousel
              _showComingSoon();
            },
          ),
          const SizedBox(height: 16),

          _buildAdminButton(
            title: 'إرسال إشعارات للمستخدمين',
            subtitle: 'إرسال رسائل تنبيه لجميع مستخدمي التطبيق',
            icon: Icons.notifications_active_rounded,
            color: Colors.redAccent,
            onTap: () {
              // TODO: Navigate to admin notifications
              _showComingSoon();
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    Stream<int> stream,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              return Text(
                '${snapshot.data ?? 0}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFamily: 'Tajawal',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة قيد التطوير للنسخة الكاملة للويب'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
