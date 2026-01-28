import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../login_signup/widgets/snackbar.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final SupabaseClient _sb = Supabase.instance.client;

  // Controllers
  final _couponCodeCtrl = TextEditingController();

  final _couponDescArCtrl = TextEditingController();
  final _couponDescEnCtrl = TextEditingController();
  final _couponWebCtrl = TextEditingController();

  // Tags
  final List<TextEditingController> _tagCtrls =
      List.generate(6, (_) => TextEditingController());

  final _couponFormKey = GlobalKey<FormState>();

  // ✅ store_id في جدول coupons الآن = stores.slug (TEXT)
  String? _selectedStoreId; // هنا نخزن الـ slug
  String? _selectedStoreImageUrl;
  String? _selectedStoreName; // اختياري للعرض فقط
  DateTime? _selectedExpiryDate;
  String? _editingId; // If editing coupon
  String? _editingImageUrl; // Old image if we are editing
  XFile? _pickedCouponImageFile;
  bool _isSaving = false;

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

    _selectedStoreId = null;
    _selectedStoreImageUrl = null;
    _selectedStoreName = null;
    _selectedExpiryDate = null;
  }

  // --- Upload Image (Supabase) ---
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

  void _showStorePicker(
      List<Map<String, dynamic>> stores, StateSetter setStateSheet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: 15),
          const SizedBox(height: 15),
          Text('اختر المتجر المرتبط',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Constants.primaryColor)),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, i) {
                final data = stores[i];
                final storeName =
                    data['name_ar'] ?? data['name'] ?? 'متجر بدون اسم';
                final img = data['image'];

                // ✅ نستخدم slug للربط
                final slug = (data['slug'] ?? '').toString();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (img != null && img.isNotEmpty)
                        ? NetworkImage(img)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: (img == null || img.isEmpty)
                        ? Icon(Icons.store, color: Constants.primaryColor)
                        : null,
                  ),
                  title: Text(
                    storeName.toString(),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black54),
                  ),
                  subtitle: (slug.isNotEmpty)
                      ? Text('ID: $slug',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54))
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    setStateSheet(() {
                      // ✅ هنا نخزن slug لأنه هو اللي يدخل coupons.store_id
                      _selectedStoreId =
                          (data['slug'] ?? data['id']).toString();
                      _selectedStoreImageUrl = img?.toString() ?? '';
                      _selectedStoreName = storeName.toString();
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddOrEditSheet({Map<String, dynamic>? coupon}) async {
    _clearForm();

    // ✅ Fetch stores (مع slug)
    final storeRes =
        await _sb.from('stores').select('id,slug,name,name_ar,name_en,image');
    final stores = List<Map<String, dynamic>>.from(storeRes);

    if (coupon != null) {
      _editingId = coupon['id'].toString();
      _couponCodeCtrl.text = (coupon['code'] ?? '').toString();

      _couponDescArCtrl.text = (coupon['description_ar'] ?? '').toString();
      _couponDescEnCtrl.text = (coupon['description_en'] ?? '').toString();
      _couponWebCtrl.text = (coupon['web'] ?? '').toString();

      // ✅ coupon.store_id الآن هو slug
      _selectedStoreId = (coupon['store_id'] ?? '').toString();
      _editingImageUrl = (coupon['image'] ?? '').toString();

      // ✅ Try to find current store by slug
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

      // Parse tags
      final tagsRaw = coupon['tags'];
      try {
        final parsed = (tagsRaw is String && tagsRaw.isNotEmpty)
            ? (jsonDecode(tagsRaw) as List)
            : (tagsRaw is List ? tagsRaw : <dynamic>[]);
        for (int i = 0; i < _tagCtrls.length && i < parsed.length; i++) {
          _tagCtrls[i].text = parsed[i].toString();
        }
      } catch (_) {}

      // ✅ Parse expiry_date
      if (coupon['expiry_date'] != null) {
        _selectedExpiryDate =
            DateTime.tryParse(coupon['expiry_date'].toString());
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: kToolbarHeight + 30),
        child: StatefulBuilder(
          builder: (ctx, setStateSheet) => Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                      _editingId == null ? 'إضافة كوبون جديد' : 'تعديل الكوبون',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor)),
                  const SizedBox(height: 15),
                  const Divider(indent: 20, endIndent: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _couponFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Image Picker Area
                            Center(
                              child: GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (file != null) {
                                    setStateSheet(
                                        () => _pickedCouponImageFile = file);
                                  }
                                },
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    image: _getImageProvider(),
                                  ),
                                  child: _getImageChild(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            _inputField(_couponCodeCtrl, 'كود الخصم',
                                Icons.confirmation_number),

                            _inputField(_couponDescArCtrl,
                                'وصف الكوبون (بالعربي)', Icons.description,
                                maxLines: null,
                                keyboardType: TextInputType.multiline),
                            _inputField(
                                _couponDescEnCtrl,
                                'Description (English)',
                                Icons.description_outlined,
                                maxLines: null,
                                keyboardType: TextInputType.multiline),
                            _inputField(
                                _couponWebCtrl,
                                'رابط الموقع (Web Link)',
                                Icons.language_outlined),

                            const SizedBox(height: 15),
                            _buildSectionTitle('تاريخ الانتهاء'),
                            InkWell(
                              onTap: () async {
                                DateTime selected =
                                    _selectedExpiryDate ?? DateTime.now();
                                final picked = await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20))),
                                  builder: (_) {
                                    return SafeArea(
                                      child: SizedBox(
                                        height: 420,
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 12),
                                            Text("اختر التاريخ",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Constants
                                                        .primaryColor)),
                                            const Divider(),
                                            Expanded(
                                              child: CalendarDatePicker(
                                                initialDate: selected,
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100),
                                                onDateChanged: (d) =>
                                                    selected = d,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Constants.primaryColor,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, selected),
                                                  child: const Text("تأكيد",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );

                                if (picked != null && picked is DateTime) {
                                  setStateSheet(
                                      () => _selectedExpiryDate = picked);
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
                                        icon: const Icon(Icons.clear,
                                            color: Colors.red),
                                        onPressed: () {
                                          setStateSheet(
                                              () => _selectedExpiryDate = null);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),
                            _buildSectionTitle('ربط المتجر'),
                            InkWell(
                              onTap: () =>
                                  _showStorePicker(stores, setStateSheet),
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
                                      backgroundImage:
                                          (_selectedStoreImageUrl != null &&
                                                  _selectedStoreImageUrl!
                                                      .isNotEmpty)
                                              ? NetworkImage(
                                                  _selectedStoreImageUrl!)
                                              : null,
                                      child: (_selectedStoreImageUrl == null ||
                                              _selectedStoreImageUrl!.isEmpty)
                                          ? Icon(Icons.storefront_rounded,
                                              color: Constants.primaryColor)
                                          : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      _selectedStoreId != null
                                          ? 'تم اختيار المتجر: ${_selectedStoreName ?? _selectedStoreId}'
                                          : 'اضغط لاختيار المتجر',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 14,
                                          color: Colors.black54),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            _buildSectionTitle('الوسوم (6 Tags)'),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.8,
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
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Constants.primaryColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveCoupon(setStateSheet),
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      _editingId == null
                                          ? 'حفظ ونشر الكوبون'
                                          : 'حفظ التعديلات',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
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
          ),
        ),
      ),
    );
  }

  DecorationImage? _getImageProvider() {
    if (_pickedCouponImageFile != null) {
      if (kIsWeb) {
        return DecorationImage(
            image: NetworkImage(_pickedCouponImageFile!.path),
            fit: BoxFit.contain);
      } else {
        return DecorationImage(
            image: FileImage(File(_pickedCouponImageFile!.path)),
            fit: BoxFit.contain);
      }
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
    if (_pickedCouponImageFile != null) return null;
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

  Future<void> _saveCoupon(StateSetter setStateSheet) async {
    if (!(_couponFormKey.currentState?.validate() ?? false)) return;
    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      showSnackBar(context, 'يرجى اختيار المتجر', isError: true);
      return;
    }

    setStateSheet(() => _isSaving = true);
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
        'name_ar': _couponCodeCtrl.text
            .trim(), // Name input removed, use code as fallback
        'name_en': _couponCodeCtrl.text.trim(),
        'description_ar': _couponDescArCtrl.text.trim(),
        'description_en': _couponDescEnCtrl.text.trim().isEmpty
            ? _couponDescArCtrl.text.trim()
            : _couponDescEnCtrl.text.trim(),

        // Fallbacks
        'name': _couponCodeCtrl.text.trim(), // Use code as name
        'description': _couponDescArCtrl.text.trim(),

        'web': _couponWebCtrl.text.trim(),

        // ✅ store_id لازم يكون slug
        'store_id': _selectedStoreId,

        'image': finalImageUrl,
        'tags': jsonEncode(tags),
        'expiry_date': _selectedExpiryDate?.toIso8601String(),
      };

      if (_editingId == null) {
        // ✅ لا نرسل created_at (خليه من الداتابيس إذا موجود default)
        await _sb.from('coupons').insert(payload);
      } else {
        await _sb.from('coupons').update(payload).eq('id', _editingId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      showSnackBar(context,
          _editingId == null ? 'تمت الإضافة بنجاح ✅' : 'تم التحديث بنجاح ✅');
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ: $e', isError: true);
        try {
          setStateSheet(() => _isSaving = false);
        } catch (_) {}
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

  // Small Widgets
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
      {int? maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
              borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
        style: const TextStyle(
            fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
      ),
    );
  }

  Widget _couponCard(Map<String, dynamic> data) {
    final id = data['id'].toString();
    final name = data['name_ar'] ?? data['name'] ?? '';
    final code = data['code'] ?? '';
    final image = data['image'];
    final storeId = data['store_id']; // هذا الآن slug

    List<dynamic> tagsList = [];
    if (data['tags'] != null) {
      if (data['tags'] is List) {
        tagsList = data['tags'];
      } else if (data['tags'] is String) {
        try {
          tagsList = jsonDecode(data['tags']);
        } catch (_) {}
      }
    }

    final expiryDateString = data['expiry_date'];
    int? daysLeft;
    bool isExpiringSoon = false;

    if (expiryDateString != null) {
      final expiryDate = DateTime.tryParse(expiryDateString.toString());
      if (expiryDate != null) {
        daysLeft = expiryDate.difference(DateTime.now()).inDays;
        // If daysLeft is negative, it's already expired.
        // We consider "soon" if it's <= 5 days (including existing expiration).
        if (daysLeft <= 5) {
          isExpiringSoon = true;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (image != null && image.isNotEmpty)
                  ? Image.network(image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image))
                  : Icon(Icons.confirmation_number_outlined,
                      color: Constants.primaryColor),
            ),
          ),
          title: Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('كود: $code',
                  style: TextStyle(
                      fontSize: 12,
                      // Change color to RED if expiring soon, else primaryColor
                      color:
                          isExpiringSoon ? Colors.red : Constants.primaryColor,
                      fontWeight: FontWeight.w600)),
              if (daysLeft != null) ...[
                const SizedBox(height: 4),
                Text(
                  daysLeft < 0
                      ? 'منتهي منذ ${daysLeft.abs()} يوم'
                      : 'باقي $daysLeft يوم',
                  style: TextStyle(
                    fontSize: 11,
                    color: isExpiringSoon ? Colors.red : Colors.grey[600],
                    fontWeight:
                        isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[400]),
                  onPressed: () => _openAddOrEditSheet(coupon: data)),
              IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                  onPressed: () => _deleteCoupon(id)),
              const Icon(Icons.expand_circle_down_outlined,
                  size: 20, color: Colors.grey),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفاصيل إضافية:',
                      style: TextStyle(
                          color: Constants.primaryColor,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (data['description_ar'] != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('• الوصف: ${data['description_ar']}')),
                  if (storeId != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('• متجر (slug): $storeId')),
                  if (data['web'] != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('• الرابط: ${data['web']}')),
                  if (tagsList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: tagsList.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!)),
                            child: Text(t.toString(),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Constants.primaryColor),
        title: Text('إدارة الكوبونات',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Constants.primaryColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Constants.primaryColor,
                  Constants.primaryColor.withValues(alpha: 0.8)
                ]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Constants.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openAddOrEditSheet(),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text('إضافة كوبون جديد',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _sb.from('coupons').stream(primaryKey: ['id']).order(
                'created_at',
                ascending: false,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('لا توجد كوبونات حالياً',
                        style: TextStyle(color: Colors.grey[400])),
                  );
                }

                final items = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _couponCard(items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
