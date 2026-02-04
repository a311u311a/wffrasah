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
  final bool isEmbedded;
  const WebAdminCouponsScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminCouponsScreen> createState() => _WebAdminCouponsScreenState();
}

class _WebAdminCouponsScreenState extends State<WebAdminCouponsScreen> {
  static const String _font = 'Tajawal';

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

  // ✅ Search (مثل صفحة المتاجر)
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _couponCodeCtrl.dispose();
    _couponDescArCtrl.dispose();
    _couponDescEnCtrl.dispose();
    _couponWebCtrl.dispose();
    _searchCtrl.dispose();
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
              fontFamily: _font,
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
                                color: Colors.black54,
                                fontFamily: _font,
                              ),
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
                            fontWeight: FontWeight.normal,
                            fontFamily: _font,
                          ),
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
                          fontWeight: FontWeight.normal,
                          fontFamily: _font,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey, fontFamily: _font),
              ),
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
                          fontFamily: _font,
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
                  color: Colors.black54,
                  fontFamily: _font,
                ),
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
                    style: const TextStyle(fontSize: 14, fontFamily: _font),
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
        const Text(
          "صورة الكوبون",
          style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: _font),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Constants.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: _font,
        ),
      ),
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
            fontWeight: FontWeight.normal,
            fontFamily: _font,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          fontWeight: FontWeight.normal,
          fontFamily: _font,
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
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
        title: const Text('حذف الكوبون؟', style: TextStyle(fontFamily: _font)),
        content: const Text('سيتم حذف الكوبون نهائياً. هل أنت متأكد؟',
            style: TextStyle(fontFamily: _font)),
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

  /// ✅ جلب أسماء المتاجر مرة واحدة بناءً على slugs الموجودة في الكوبونات
  Future<Map<String, String>> _fetchStoresNames(
      List<Map<String, dynamic>> coupons) async {
    final Map<String, String> map = {};
    if (coupons.isEmpty) return map;

    final slugs = coupons
        .map((c) => (c['store_id'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (slugs.isEmpty) return map;

    final data = await _sb
        .from('stores')
        .select('slug,name,name_ar')
        .inFilter('slug', slugs);

    for (final row in (data as List)) {
      final slug = (row['slug'] ?? '').toString();
      final name = (row['name_ar'] ?? row['name'] ?? '').toString();
      if (slug.isNotEmpty) map[slug] = name;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildContent(),
        ),
      );
    }

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
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 26),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 28),
                color: Constants.primaryColor,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة الكوبونات',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.isDesktop(context) ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: _font,
                    color: Colors.grey[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'إضافة، تعديل، أو حذف أكواد الخصم بسهولة',
            style: TextStyle(
              fontSize: 13,
              fontFamily: _font,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
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
          _searchWithAddButton(),
          const SizedBox(height: 18),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _sb.from('coupons').stream(primaryKey: ['id']).order(
              'created_at',
              ascending: false,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final all = snapshot.data!;
              if (all.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'لا توجد كوبونات حالياً',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                        fontFamily: _font,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }

              return FutureBuilder<Map<String, String>>(
                future: _fetchStoresNames(all),
                builder: (context, storesSnap) {
                  final storesMap = storesSnap.data ?? {};
                  final filtered = _applySearch(all, storesMap);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'لا توجد نتائج مطابقة للبحث',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontFamily: _font,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }

                  return _buildCouponsGrid(filtered, storesMap);
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applySearch(
      List<Map<String, dynamic>> items, Map<String, String> storesMap) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((c) {
      final code = (c['code'] ?? '').toString().toLowerCase();
      final ar = (c['description_ar'] ?? '').toString().toLowerCase();
      final en = (c['description_en'] ?? '').toString().toLowerCase();
      final storeId = (c['store_id'] ?? '').toString().toLowerCase();
      final storeName = (storesMap[storeId] ?? '').toLowerCase();

      return code.contains(q) ||
          ar.contains(q) ||
          en.contains(q) ||
          storeId.contains(q) ||
          storeName.contains(q);
    }).toList();
  }

  Widget _searchWithAddButton() {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (!isDesktop) {
      return Column(
        children: [
          _searchBar(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _openAddOrEditDialog(),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'إضافة كوبون',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: _font,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _searchBar()),
        const SizedBox(width: 12),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => _openAddOrEditDialog(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'إضافة كوبون',
              style: TextStyle(
                color: Colors.white,
                fontFamily: _font,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ابحث بالكود أو اسم المتجر…',
                hintStyle: TextStyle(
                  fontFamily: _font,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontFamily: _font,
                fontWeight: FontWeight.w800,
                color: Colors.grey[900],
              ),
            ),
          ),
          if (_search.trim().isNotEmpty)
            IconButton(
              tooltip: 'مسح',
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
              icon: Icon(Icons.clear_rounded, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildCouponsGrid(
      List<Map<String, dynamic>> items, Map<String, String> storesMap) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 165,
      ),
      itemBuilder: (context, i) {
        final coupon = items[i];
        final id = coupon['id'].toString();
        final code = (coupon['code'] ?? '').toString();
        final description =
            (coupon['description_ar'] ?? coupon['description'] ?? '')
                .toString();
        final image = coupon['image'];
        final storeId = (coupon['store_id'] ?? '').toString();
        final storeName = storesMap[storeId] ?? storeId;
        final expiryDateString = coupon['expiry_date'];

        DateTime? expiryDate;
        if (expiryDateString != null) {
          expiryDate = DateTime.tryParse(expiryDateString.toString());
        }

        return _couponCard(
          id: id,
          coupon: coupon,
          code: code,
          description: description,
          image: (image ?? '').toString(),
          storeName: storeName,
          expiryDate: expiryDate,
        );
      },
    );
  }

  Widget _couponCard({
    required String id,
    required Map<String, dynamic> coupon,
    required String code,
    required String description,
    required String image,
    required String storeName,
    required DateTime? expiryDate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Coupon Image
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image,
                              color: Colors.grey[500],
                            ),
                          )
                        : Icon(Icons.confirmation_number_rounded,
                            color: Constants.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),

                // Code + Store Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        storeName,
                        style: TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  tooltip: 'خيارات',
                  onSelected: (v) {
                    if (v == 'edit') _openAddOrEditDialog(coupon: coupon);
                    if (v == 'delete') _deleteCoupon(id);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description.isEmpty ? 'بدون وصف' : description,
                style: TextStyle(
                  fontFamily: _font,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Spacer(),

            // Footer: Expiry + quick actions
            Row(
              children: [
                _expiryBadge(expiryDate),
                const Spacer(),
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: () => _openAddOrEditDialog(coupon: coupon),
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[500]),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => _deleteCoupon(id),
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _expiryBadge(DateTime? date) {
    if (date == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'غير محدد',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontFamily: _font,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final daysLeft = date.difference(DateTime.now()).inDays;
    final isAhmar = daysLeft <= 5; // أحمر
    final color = isAhmar ? Colors.red : Constants.primaryColor;
    final bgColor = isAhmar
        ? Colors.red[50]!
        : Constants.primaryColor.withValues(alpha: 0.10);
    final borderColor = isAhmar
        ? Colors.red[100]!
        : Constants.primaryColor.withValues(alpha: 0.18);
    final dateStr = '${date.year}-${date.month}-${date.day}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            // ممكن نعرض "باقي X أيام" لو حابب، بس هو طلب اللون بس، فحنخلي التاريخ
            // بس ممكن نضيف نص توضيحي لو منتهي
            daysLeft < 0
                ? 'منتهي ($dateStr)'
                : (isAhmar ? 'باقي $daysLeft يوم ($dateStr)' : dateStr),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontFamily: _font,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
