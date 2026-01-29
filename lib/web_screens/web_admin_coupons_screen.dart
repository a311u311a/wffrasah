import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة إدارة الكوبونات على الويب
class WebAdminCouponsScreen extends StatefulWidget {
  const WebAdminCouponsScreen({super.key});

  @override
  State<WebAdminCouponsScreen> createState() => _WebAdminCouponsScreenState();
}

class _WebAdminCouponsScreenState extends State<WebAdminCouponsScreen> {
  final SupabaseClient _sb = Supabase.instance.client;
  final _couponCodeCtrl = TextEditingController();
  final _couponDescArCtrl = TextEditingController();
  final _couponDescEnCtrl = TextEditingController();
  final _couponWebCtrl = TextEditingController();
  final List<TextEditingController> _tagCtrls =
      List.generate(6, (_) => TextEditingController());
  final _couponFormKey = GlobalKey<FormState>();

  String? _selectedStoreId;
  String? _selectedStoreImageUrl;
  String? _selectedStoreName;
  DateTime? _selectedExpiryDate;
  String? _editingId;
  String? _editingImageUrl;
  XFile? _pickedCouponImageFile;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _couponCodeCtrl.dispose();
    _couponDescArCtrl.dispose();
    _couponDescEnCtrl.dispose();
    _couponWebCtrl.dispose();
    for (final c in _tagCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    _editingId = null;
    _editingImageUrl = null;
    _couponCodeCtrl.clear();
    _couponDescArCtrl.clear();
    _couponDescEnCtrl.clear();
    _couponWebCtrl.clear();
    for (var c in _tagCtrls) {
      c.clear();
    }
    _pickedCouponImageFile = null;
    _pickedImageBytes = null;
    _selectedStoreId = null;
    _selectedStoreImageUrl = null;
    _selectedStoreName = null;
    _selectedExpiryDate = null;
  }

  Future<String?> _uploadFile(XFile file, String path) async {
    try {
      final bytes = await file.readAsBytes();
      await _sb.storage.from('images').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return _sb.storage.from('images').getPublicUrl(path);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
      }
      return null;
    }
  }

  Future<void> _openAddOrEditDialog({Map<String, dynamic>? coupon}) async {
    _clearForm();

    final storeRes =
        await _sb.from('stores').select('id,slug,name,name_ar,name_en,image');
    final stores = List<Map<String, dynamic>>.from(storeRes);

    if (coupon != null) {
      _editingId = coupon['id'].toString();
      _couponCodeCtrl.text = (coupon['code'] ?? '').toString();
      _couponDescArCtrl.text = (coupon['description_ar'] ?? '').toString();
      _couponDescEnCtrl.text = (coupon['description_en'] ?? '').toString();
      _couponWebCtrl.text = (coupon['web'] ?? '').toString();
      _selectedStoreId = (coupon['store_id'] ?? '').toString();
      _editingImageUrl = (coupon['image'] ?? '').toString();

      final matchingStore = stores.firstWhere(
        (s) => (s['slug'] ?? s['id']).toString() == _selectedStoreId,
        orElse: () => {},
      );

      if (matchingStore.isNotEmpty) {
        _selectedStoreImageUrl = (matchingStore['image'] ?? '').toString();
        _selectedStoreName =
            (matchingStore['name_ar'] ?? matchingStore['name'] ?? '')
                .toString();
      }

      final tagsRaw = coupon['tags'];
      try {
        final parsed = (tagsRaw is String && tagsRaw.isNotEmpty)
            ? (jsonDecode(tagsRaw) as List)
            : (tagsRaw is List ? tagsRaw : <dynamic>[]);
        for (int i = 0; i < _tagCtrls.length && i < parsed.length; i++) {
          _tagCtrls[i].text = parsed[i].toString();
        }
      } catch (_) {}

      if (coupon['expiry_date'] != null) {
        _selectedExpiryDate =
            DateTime.tryParse(coupon['expiry_date'].toString());
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _editingId == null ? 'إضافة كوبون جديد' : 'تعديل الكوبون',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Form(
                key: _couponFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة الكوبون
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final file = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (file != null) {
                            final bytes = await file.readAsBytes();
                            setStateDialog(() {
                              _pickedCouponImageFile = file;
                              _pickedImageBytes = bytes;
                            });
                          }
                        },
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            image: _getImageProvider(),
                          ),
                          child: _getImageChild(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _inputField(_couponCodeCtrl, 'كود الخصم',
                        Icons.confirmation_number),
                    _inputField(_couponDescArCtrl, 'وصف الكوبون (بالعربي)',
                        Icons.description,
                        maxLines: 3),
                    _inputField(_couponDescEnCtrl, 'Description (English)',
                        Icons.description_outlined,
                        maxLines: 3),
                    _inputField(_couponWebCtrl, 'رابط الموقع (Web Link)',
                        Icons.language_outlined),

                    const SizedBox(height: 15),
                    _buildSectionTitle('تاريخ الانتهاء'),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedExpiryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() => _selectedExpiryDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Constants.primaryColor),
                            const SizedBox(width: 15),
                            Text(
                              _selectedExpiryDate != null
                                  ? 'ينتهي في: ${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month}-${_selectedExpiryDate!.day}'
                                  : 'تاريخ انتهاء الصلاحية (اختياري)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                  color: Colors.black54),
                            ),
                            const Spacer(),
                            if (_selectedExpiryDate != null)
                              IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.red),
                                onPressed: () {
                                  setStateDialog(
                                      () => _selectedExpiryDate = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    _buildSectionTitle('ربط المتجر'),
                    _buildStorePicker(stores, setStateDialog),

                    const SizedBox(height: 20),
                    _buildSectionTitle('الوسوم (6 Tags)'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3,
                      ),
                      itemCount: 6,
                      itemBuilder: (ctx, i) => TextFormField(
                        controller: _tagCtrls[i],
                        decoration: InputDecoration(
                          hintText: 'وسم ${i + 1}',
                          hintStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.normal),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : () => _saveCoupon(setStateDialog),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _editingId == null
                            ? 'حفظ ونشر الكوبون'
                            : 'حفظ التعديلات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePicker(
      List<Map<String, dynamic>> stores, StateSetter setStateDialog) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (_selectedStoreImageUrl != null &&
                      _selectedStoreImageUrl!.isNotEmpty)
                  ? NetworkImage(_selectedStoreImageUrl!)
                  : null,
              child: (_selectedStoreImageUrl == null ||
                      _selectedStoreImageUrl!.isEmpty)
                  ? Icon(Icons.storefront_rounded,
                      color: Constants.primaryColor)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _selectedStoreId != null
                    ? 'تم اختيار المتجر: ${_selectedStoreName ?? _selectedStoreId}'
                    : 'اضغط لاختيار المتجر',
                style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    color: Colors.black54),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
      itemBuilder: (context) {
        return stores.map((store) {
          final storeName = store['name_ar'] ?? store['name'] ?? 'متجر';
          final slug = (store['slug'] ?? '').toString();
          final img = store['image'];

          return PopupMenuItem<String>(
            value: slug,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: (img != null && img.isNotEmpty)
                      ? NetworkImage(img)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: (img == null || img.isEmpty)
                      ? Icon(Icons.store,
                          color: Constants.primaryColor, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    storeName.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            onTap: () {
              setStateDialog(() {
                _selectedStoreId = slug;
                _selectedStoreImageUrl = img?.toString() ?? '';
                _selectedStoreName = storeName.toString();
              });
            },
          );
        }).toList();
      },
    );
  }

  DecorationImage? _getImageProvider() {
    if (_pickedImageBytes != null) {
      return DecorationImage(
          image: MemoryImage(_pickedImageBytes!), fit: BoxFit.contain);
    } else if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) {
      return DecorationImage(
          image: NetworkImage(_editingImageUrl!), fit: BoxFit.contain);
    } else if (_selectedStoreImageUrl != null &&
        _selectedStoreImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_selectedStoreImageUrl!),
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.3), BlendMode.darken),
      );
    }
    return null;
  }

  Widget? _getImageChild() {
    if (_pickedImageBytes != null) return null;
    if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) return null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, color: Constants.primaryColor),
        const SizedBox(height: 4),
        const Text("صورة الكوبون",
            style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(title,
          style: TextStyle(
              color: Constants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {int? maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Constants.primaryColor, size: 20),
          hintText: hint,
          labelText: hint,
          labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        style: const TextStyle(
            fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
      ),
    );
  }

  Future<void> _saveCoupon(StateSetter setStateDialog) async {
    if (!(_couponFormKey.currentState?.validate() ?? false)) return;
    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      showSnackBar(context, 'يرجى اختيار المتجر', isError: true);
      return;
    }

    setStateDialog(() => _isSaving = true);
    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _editingImageUrl;

      if (_pickedCouponImageFile != null) {
        final path = 'coupons/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _uploadFile(_pickedCouponImageFile!, path);
        if (url != null) finalImageUrl = url;
      } else if (_editingId == null) {
        finalImageUrl = _selectedStoreImageUrl ?? '';
      }

      final tags = _tagCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final payload = {
        'code': _couponCodeCtrl.text.trim(),
        'name_ar': _couponCodeCtrl.text.trim(),
        'name_en': _couponCodeCtrl.text.trim(),
        'description_ar': _couponDescArCtrl.text.trim(),
        'description_en': _couponDescEnCtrl.text.trim().isEmpty
            ? _couponDescArCtrl.text.trim()
            : _couponDescEnCtrl.text.trim(),
        'name': _couponCodeCtrl.text.trim(),
        'description': _couponDescArCtrl.text.trim(),
        'web': _couponWebCtrl.text.trim(),
        'store_id': _selectedStoreId,
        'image': finalImageUrl,
        'tags': jsonEncode(tags),
        'expiry_date': _selectedExpiryDate?.toIso8601String(),
      };

      if (_editingId == null) {
        await _sb.from('coupons').insert(payload);
      } else {
        await _sb.from('coupons').update(payload).eq('id', _editingId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      showSnackBar(context,
          _editingId == null ? 'تمت الإضافة بنجاح ✅' : 'تم التحديث بنجاح ✅');
    } catch (e) {
      if (mounted) showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) {
        setStateDialog(() => _isSaving = false);
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCoupon(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الكوبون؟'),
        content: const Text('سيتم حذف الكوبون نهائياً. هل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _sb.from('coupons').delete().eq('id', id);
        if (mounted) showSnackBar(context, 'تم الحذف');
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
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
            Constants.primaryColor.withValues(alpha: 0.1),
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
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 32),
                color: Constants.primaryColor,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.confirmation_number_rounded,
                color: Constants.primaryColor,
                size: ResponsiveLayout.isDesktop(context) ? 48 : 36,
              ),
              const SizedBox(width: 16),
              Text(
                'إدارة الكوبونات',
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
            'إضافة، تعديل، أو حذف أكواد الخصم',
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
          // زر إضافة كوبون جديد
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => _openAddOrEditDialog(),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'إضافة كوبون جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // جدول الكوبونات
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _sb.from('coupons').stream(
                primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'لا توجد كوبونات حالياً',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                );
              }

              final items = snapshot.data!;
              return _buildCouponsTable(items);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCouponsTable(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Constants.primaryColor.withValues(alpha: 0.1),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'الصورة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الكود',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الوصف',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'المتجر',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'تاريخ الانتهاء',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'الإجراءات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
          rows: items.map((coupon) {
            final id = coupon['id'].toString();
            final code = coupon['code'] ?? '';
            final description =
                coupon['description_ar'] ?? coupon['description'] ?? '';
            final image = coupon['image'];
            final storeId = coupon['store_id'];
            final expiryDateString = coupon['expiry_date'];

            return DataRow(
              cells: [
                // الصورة
                DataCell(
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (image != null && image.toString().isNotEmpty)
                          ? Image.network(
                              image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            )
                          : Icon(Icons.confirmation_number,
                              color: Constants.primaryColor),
                    ),
                  ),
                ),
                // الكود
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal',
                        color: Constants.primaryColor,
                      ),
                    ),
                  ),
                ),
                // الوصف
                DataCell(
                  SizedBox(
                    width: 300,
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Tajawal',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // المتجر
                DataCell(
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _sb
                        .from('stores')
                        .select('name,name_ar,slug')
                        .eq('slug', storeId ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final store = snapshot.data!.first;
                        return Text(
                          store['name_ar'] ?? store['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Tajawal',
                          ),
                        );
                      }
                      return const Text('-');
                    },
                  ),
                ),
                // تاريخ الانتهاء
                DataCell(
                  Text(
                    expiryDateString != null
                        ? DateTime.tryParse(expiryDateString.toString())
                                ?.toString()
                                .split(' ')[0] ??
                            '-'
                        : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                // الإجراءات
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded,
                            color: Colors.blueGrey[400]),
                        onPressed: () => _openAddOrEditDialog(coupon: coupon),
                        tooltip: 'تعديل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined,
                            color: Colors.redAccent),
                        onPressed: () => _deleteCoupon(id),
                        tooltip: 'حذف',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
