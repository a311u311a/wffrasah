import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants.dart';
import '../login_signup/widgets/snackbar.dart';

class AdminPendingCouponsScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminPendingCouponsScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminPendingCouponsScreen> createState() =>
      _AdminPendingCouponsScreenState();
}

class _AdminPendingCouponsScreenState extends State<AdminPendingCouponsScreen> {
  final SupabaseClient _sb = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _pendingFuture;
  final _editFormKey = GlobalKey<FormState>();
  final _storeNameArCtrl = TextEditingController();
  final _storeNameEnCtrl = TextEditingController();
  final _storeDescArCtrl = TextEditingController();
  final _storeDescEnCtrl = TextEditingController();
  final _couponCodeCtrl = TextEditingController();
  final _couponDescArCtrl = TextEditingController();
  final _couponDescEnCtrl = TextEditingController();
  final _couponWebCtrl = TextEditingController();
  final _sourceCouponIdCtrl = TextEditingController();
  final _tagCtrls = List.generate(4, (_) => TextEditingController());
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String? _editingImageUrl;
  XFile? _pickedImage;
  DateTime? _selectedExpiryDate;
  bool _isSavingEdit = false;

  @override
  void initState() {
    super.initState();
    _pendingFuture = _fetchPendingCoupons();
    _loadCategories();
  }

  @override
  void dispose() {
    _storeNameArCtrl.dispose();
    _storeNameEnCtrl.dispose();
    _storeDescArCtrl.dispose();
    _storeDescEnCtrl.dispose();
    _couponCodeCtrl.dispose();
    _couponDescArCtrl.dispose();
    _couponDescEnCtrl.dispose();
    _couponWebCtrl.dispose();
    _sourceCouponIdCtrl.dispose();
    for (final ctrl in _tagCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await _sb.from('categories').select().order('name_ar');
      if (mounted) {
        setState(() => _categories = List<Map<String, dynamic>>.from(rows));
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchPendingCoupons() async {
    final rows = await _sb
        .from('admin_pending_coupons')
        .select('*')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  void _refreshPendingCoupons() {
    if (!mounted) return;
    setState(() {
      _pendingFuture = _fetchPendingCoupons();
    });
  }

  Future<Map<String, Map<String, String>>> _fetchStoresInfo(
      List<Map<String, dynamic>> coupons) async {
    final slugs = coupons
        .map((coupon) => (coupon['store_id'] ?? '').toString().trim())
        .where((slug) => slug.isNotEmpty)
        .toSet()
        .toList();

    if (slugs.isEmpty) return {};

    final rows = await _sb
        .from('stores')
        .select('slug,name,name_ar,image')
        .inFilter('slug', slugs);

    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        (row['slug'] ?? '').toString(): {
          'name': (row['name_ar'] ?? row['name'] ?? row['slug']).toString(),
          'image': (row['image'] ?? '').toString(),
        },
    };
  }

  List<String> _parseTags(dynamic raw) {
    if (raw is List) {
      return raw
          .map((tag) => tag.toString().trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return [];

    final jsonLike = text.startsWith('[') && text.endsWith(']');
    if (jsonLike) {
      final trimmed = text.substring(1, text.length - 1);
      return trimmed
          .split(',')
          .map((tag) => tag.replaceAll('"', '').replaceAll("'", '').trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    return text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  void _fillEditForm(
      Map<String, dynamic> coupon, Map<String, String> storeInfo) {
    final storeId = (coupon['store_id'] ?? '').toString();
    _storeNameArCtrl.text = (storeInfo['name'] ??
            coupon['store_name_ar'] ??
            coupon['name_ar'] ??
            storeId)
        .toString();
    _storeNameEnCtrl.text =
        (coupon['store_name_en'] ?? coupon['name_en'] ?? '').toString();
    _storeDescArCtrl.text = (coupon['store_description_ar'] ??
            coupon['description_ar'] ??
            coupon['description'] ??
            '')
        .toString();
    _storeDescEnCtrl.text =
        (coupon['store_description_en'] ?? coupon['description_en'] ?? '')
            .toString();
    _couponCodeCtrl.text = (coupon['code'] ?? '').toString();
    _couponDescArCtrl.text =
        (coupon['description_ar'] ?? coupon['description'] ?? '').toString();
    _couponDescEnCtrl.text = (coupon['description_en'] ?? '').toString();
    _couponWebCtrl.text = (coupon['web'] ?? '').toString();
    _sourceCouponIdCtrl.text = (coupon['source_coupon_id'] ?? '').toString();
    _selectedCategoryId = (coupon['category_id'] ?? '').toString().trim();
    if (_selectedCategoryId != null && _selectedCategoryId!.isEmpty) {
      _selectedCategoryId = null;
    }
    _editingImageUrl = ((storeInfo['image'] ?? '').isNotEmpty
            ? storeInfo['image']
            : (coupon['store_image'] ?? coupon['image']))
        ?.toString();
    _pickedImage = null;
    _selectedExpiryDate = coupon['expiry_date'] == null
        ? null
        : DateTime.tryParse(coupon['expiry_date'].toString());

    final tags = _parseTags(coupon['tags']);
    for (var i = 0; i < _tagCtrls.length; i++) {
      _tagCtrls[i].text = i < tags.length ? tags[i] : '';
    }
  }

  Future<String?> _uploadPickedImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final path = 'stores/${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  Future<void> _reviewCoupon(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      final coupon = await _sb
          .from('coupons')
          .select(
            'store_id,import_source,name,name_ar,name_en,description,description_ar,description_en,image',
          )
          .eq('id', id)
          .maybeSingle();

      await _sb.from('coupons').update({
        'approval_status': status,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': _sb.auth.currentUser?.id,
        'rejection_reason': rejectionReason,
      }).eq('id', id);

      final storeId = (coupon?['store_id'] ?? '').toString().trim();
      final importSource = (coupon?['import_source'] ?? '').toString().trim();
      if (storeId.isNotEmpty && importSource.isNotEmpty) {
        await _sb.from('stores').update({
          'approval_status': status,
          'import_source': importSource,
        }).eq('slug', storeId);
      }

      if (!mounted) return;
      _refreshPendingCoupons();
      showSnackBar(
        context,
        status == 'approved' ? 'تمت الموافقة على الكوبون' : 'تم رفض الكوبون',
      );
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'تعذر تحديث حالة الكوبون: $e', isError: true);
      }
    }
  }

  Future<void> _confirmReject(String id) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الكوبون'),
        content: TextField(
          controller: reasonCtrl,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض اختياري',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();

    if (confirmed == true) {
      await _reviewCoupon(
        id,
        'rejected',
        rejectionReason: reason.isEmpty ? null : reason,
      );
    }
  }

  Future<void> _openEditPendingCoupon(
    Map<String, dynamic> coupon,
    Map<String, String> storeInfo,
  ) async {
    _fillEditForm(coupon, storeInfo);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(top: 32, bottom: bottomInset),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: Constants.primaryColor),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'تعديل كوبون بانتظار الموافقة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _editFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _imagePickerBox(setStateSheet),
                              const SizedBox(height: 18),
                              _sectionTitle('بيانات المتجر'),
                              _inputField(
                                _storeNameArCtrl,
                                'اسم المتجر (عربي)',
                                Icons.storefront_rounded,
                                requiredField: true,
                              ),
                              _inputField(
                                _storeNameEnCtrl,
                                'Store Name (English)',
                                Icons.storefront_outlined,
                              ),
                              _inputField(
                                _storeDescArCtrl,
                                'وصف المتجر (عربي)',
                                Icons.description_rounded,
                                maxLines: 3,
                              ),
                              _inputField(
                                _storeDescEnCtrl,
                                'Store Description (English)',
                                Icons.description_outlined,
                                maxLines: 3,
                              ),
                              _categoryPicker(setStateSheet),
                              const SizedBox(height: 12),
                              _sectionTitle('بيانات الكوبون'),
                              _inputField(
                                _couponCodeCtrl,
                                'كود الكوبون',
                                Icons.confirmation_number_rounded,
                                requiredField: true,
                              ),
                              _inputField(
                                _couponDescArCtrl,
                                'وصف الكوبون (عربي)',
                                Icons.local_offer_rounded,
                                maxLines: 2,
                              ),
                              _inputField(
                                _couponDescEnCtrl,
                                'Coupon Description (English)',
                                Icons.local_offer_outlined,
                                maxLines: 2,
                              ),
                              _inputField(
                                _couponWebCtrl,
                                'رابط المتجر أو رابط التسويق',
                                Icons.link_rounded,
                              ),
                              _inputField(
                                _sourceCouponIdCtrl,
                                'رقم/معرف الكوبون من المصدر',
                                Icons.tag_rounded,
                              ),
                              _expiryPicker(setStateSheet),
                              const SizedBox(height: 10),
                              _sectionTitle('وسوم اختيارية'),
                              ..._tagCtrls.map(
                                (ctrl) => _inputField(
                                  ctrl,
                                  'وسم',
                                  Icons.sell_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSavingEdit
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isSavingEdit
                                  ? null
                                  : () => _savePendingCouponEdit(
                                        coupon,
                                        setStateSheet,
                                      ),
                              icon: _isSavingEdit
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded),
                              label: const Text('حفظ'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _savePendingCouponEdit(
    Map<String, dynamic> coupon,
    StateSetter setStateSheet,
  ) async {
    if (!_editFormKey.currentState!.validate()) return;

    setStateSheet(() => _isSavingEdit = true);
    try {
      final couponId = (coupon['id'] ?? '').toString();
      final storeId = (coupon['store_id'] ?? '').toString().trim();
      var imageUrl = _editingImageUrl ?? '';

      if (_pickedImage != null) {
        final uploaded = await _uploadPickedImage(_pickedImage!);
        if (uploaded != null && uploaded.isNotEmpty) imageUrl = uploaded;
      }

      final storeNameAr = _storeNameArCtrl.text.trim();
      final storeNameEn = _storeNameEnCtrl.text.trim();
      final storeDescAr = _storeDescArCtrl.text.trim();
      final storeDescEn = _storeDescEnCtrl.text.trim();
      final couponDescAr = _couponDescArCtrl.text.trim();
      final couponDescEn = _couponDescEnCtrl.text.trim();
      final tags = _tagCtrls
          .map((ctrl) => ctrl.text.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _sb.from('coupons').update({
        'code': _couponCodeCtrl.text.trim(),
        'name': storeNameAr,
        'name_ar': storeNameAr,
        'name_en': storeNameEn.isEmpty ? storeNameAr : storeNameEn,
        'description': couponDescAr,
        'description_ar': couponDescAr,
        'description_en': couponDescEn,
        'web': _couponWebCtrl.text.trim(),
        'source_coupon_id': _sourceCouponIdCtrl.text.trim().isEmpty
            ? null
            : _sourceCouponIdCtrl.text.trim(),
        'category_id': _selectedCategoryId,
        'expiry_date': _selectedExpiryDate?.toIso8601String(),
        'image': imageUrl,
        'tags': jsonEncode(tags),
      }).eq('id', couponId);

      if (storeId.isNotEmpty) {
        await _sb.from('stores').update({
          'name': storeNameAr,
          'name_ar': storeNameAr,
          'name_en': storeNameEn.isEmpty ? storeNameAr : storeNameEn,
          'description': storeDescAr,
          'description_ar': storeDescAr,
          'description_en': storeDescEn,
          'category_id': _selectedCategoryId,
          'image': imageUrl,
        }).eq('slug', storeId);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _refreshPendingCoupons();
      showSnackBar(context, 'تم حفظ التعديلات');
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'تعذر حفظ التعديلات: $e', isError: true);
      }
    } finally {
      if (mounted) setStateSheet(() => _isSavingEdit = false);
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Constants.primaryColor,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: requiredField
            ? (value) {
                if ((value ?? '').trim().isEmpty) return 'هذا الحقل مطلوب';
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Constants.primaryColor),
          filled: true,
          fillColor: const Color(0xFFF8F9FD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  Widget _categoryPicker(StateSetter setStateSheet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategoryId,
        decoration: InputDecoration(
          labelText: 'التصنيف',
          prefixIcon:
              Icon(Icons.category_rounded, color: Constants.primaryColor),
          filled: true,
          fillColor: const Color(0xFFF8F9FD),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('بدون فئة'),
          ),
          ..._categories.map((category) {
            final id = (category['id'] ?? '').toString();
            final name = (category['name_ar'] ??
                    category['name'] ??
                    category['name_en'] ??
                    id)
                .toString();
            return DropdownMenuItem<String>(
              value: id,
              child: Text(name),
            );
          }),
        ],
        onChanged: (value) => setStateSheet(() => _selectedCategoryId = value),
      ),
    );
  }

  Widget _imagePickerBox(StateSetter setStateSheet) {
    ImageProvider? provider;
    if (_pickedImage != null) {
      provider = kIsWeb
          ? NetworkImage(_pickedImage!.path)
          : FileImage(File(_pickedImage!.path)) as ImageProvider;
    } else if ((_editingImageUrl ?? '').isNotEmpty) {
      provider = NetworkImage(_editingImageUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: () async {
          final image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1200,
            imageQuality: 85,
          );
          if (image != null) {
            setStateSheet(() => _pickedImage = image);
          }
        },
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F5FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E3FF)),
            image: provider == null
                ? null
                : DecorationImage(image: provider, fit: BoxFit.contain),
          ),
          child: provider == null
              ? Icon(
                  Icons.add_a_photo_rounded,
                  color: Constants.primaryColor,
                  size: 34,
                )
              : null,
        ),
      ),
    );
  }

  Widget _expiryPicker(StateSetter setStateSheet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedExpiryDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setStateSheet(() => _selectedExpiryDate = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Constants.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedExpiryDate == null
                      ? 'تاريخ الانتهاء'
                      : '${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month.toString().padLeft(2, '0')}-${_selectedExpiryDate!.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_selectedExpiryDate != null)
                IconButton(
                  onPressed: () =>
                      setStateSheet(() => _selectedExpiryDate = null),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('كوبونات بانتظار الموافقة'),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Constants.primaryColor,
              elevation: 0,
            ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'خطأ في تحميل كوبونات الانتظار: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final coupons = snapshot.data ?? [];
          if (coupons.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد كوبونات بانتظار الموافقة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            );
          }

          return FutureBuilder<Map<String, Map<String, String>>>(
            future: _fetchStoresInfo(coupons),
            builder: (context, storeSnapshot) {
              final stores = storeSnapshot.data ?? {};

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: coupons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridColumns(context),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 306,
                ),
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  final storeId = (coupon['store_id'] ?? '').toString();
                  final storeInfo = stores[storeId] ?? const {};
                  final storeName =
                      (storeInfo['name'] ?? coupon['store_name_ar'] ?? storeId)
                          .toString();
                  final storeImage = (storeInfo['image']?.isNotEmpty ?? false)
                      ? storeInfo['image']!
                      : (coupon['store_image'] ?? coupon['image'] ?? '')
                          .toString();
                  return _PendingCouponCard(
                    coupon: coupon,
                    storeName: storeName,
                    storeImage: storeImage,
                    onEdit: () => _openEditPendingCoupon(coupon, storeInfo),
                    onApprove: () =>
                        _reviewCoupon(coupon['id'].toString(), 'approved'),
                    onReject: () => _confirmReject(coupon['id'].toString()),
                  );
                },
              );
            },
          );
        },
      ),
    );

    return widget.isEmbedded ? content.body! : content;
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1300) return 4;
    if (width >= 950) return 3;
    if (width >= 620) return 2;
    return 1;
  }
}

class _PendingCouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final String storeName;
  final String storeImage;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCouponCard({
    required this.coupon,
    required this.storeName,
    required this.storeImage,
    required this.onEdit,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final code = (coupon['code'] ?? '').toString();
    final description =
        (coupon['description_ar'] ?? coupon['description'] ?? '').toString();
    final web = (coupon['web'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E3FF)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: storeImage.isNotEmpty
                        ? Image.network(
                            storeImage,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.storefront_rounded,
                              color: Constants.primaryColor,
                            ),
                          )
                        : Icon(
                            Icons.storefront_rounded,
                            color: Constants.primaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'بانتظار الموافقة',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number_rounded,
                      color: Constants.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      code.isEmpty ? 'بدون كود' : code,
                      style: TextStyle(
                        color: Constants.primaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (web.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.link_rounded, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      web,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('تعديل البيانات'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('موافقة'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
