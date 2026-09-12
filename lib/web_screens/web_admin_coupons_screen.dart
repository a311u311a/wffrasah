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
import '../web_widgets/web_i18n.dart';

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
  final _discountPercentCtrl = TextEditingController();
  final _termsArCtrl = TextEditingController();
  final _termsEnCtrl = TextEditingController();

  final List<TextEditingController> _tagCtrls =
      List.generate(6, (_) => TextEditingController());

  final _couponFormKey = GlobalKey<FormState>();

  String? _selectedStoreId;
  String? _selectedStoreImageUrl;
  String? _selectedStoreName;
  String? _selectedProviderId;
  String? _selectedProviderName;
  String _selectedCouponType = 'coupon';
  bool _selectedIsActive = true;
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
  late Future<List<Map<String, dynamic>>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _couponsFuture = _fetchCoupons();
  }

  Future<List<Map<String, dynamic>>> _fetchCoupons() async {
    final rows = await _sb
        .from('coupons')
        .select('*')
        .eq('approval_status', 'approved')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _refreshCoupons() {
    if (!mounted) return;
    setState(() {
      _couponsFuture = _fetchCoupons();
    });
  }

  @override
  void dispose() {
    _couponCodeCtrl.dispose();
    _couponDescArCtrl.dispose();
    _couponDescEnCtrl.dispose();
    _couponWebCtrl.dispose();
    _discountPercentCtrl.dispose();
    _termsArCtrl.dispose();
    _termsEnCtrl.dispose();
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
    _discountPercentCtrl.clear();
    _termsArCtrl.clear();
    _termsEnCtrl.clear();

    for (var c in _tagCtrls) {
      c.clear();
    }

    _pickedCouponImageFile = null;
    _pickedImageBytes = null;

    _selectedStoreId = null;
    _selectedStoreImageUrl = null;
    _selectedStoreName = null;
    _selectedProviderId = null;
    _selectedProviderName = null;
    _selectedCouponType = 'coupon';
    _selectedIsActive = true;
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
        showSnackBar(
            context,
            webText(
                context, 'خطأ في رفع الصورة: $e', 'Image upload failed: $e'),
            isError: true);
      }
      return null;
    }
  }

  Future<void> _openAddOrEditDialog({Map<String, dynamic>? coupon}) async {
    _clearForm();

    final storeRes = await _sb
        .from('stores')
        .select('id,slug,name,name_ar,name_en,image')
        .eq('approval_status', 'approved');
    final stores = List<Map<String, dynamic>>.from(storeRes);
    final providerRes = await _sb
        .from('coupon_providers')
        .select('id,name')
        .order('name');
    final providers = List<Map<String, dynamic>>.from(providerRes);

    if (coupon != null) {
      _editingId = coupon['id'].toString();
      _couponCodeCtrl.text = (coupon['code'] ?? '').toString();
      _couponDescArCtrl.text = (coupon['description_ar'] ?? '').toString();
      _couponDescEnCtrl.text = (coupon['description_en'] ?? '').toString();
      _couponWebCtrl.text = (coupon['web'] ?? '').toString();
      _discountPercentCtrl.text = (coupon['discount_percent'] ?? '').toString();
      _termsArCtrl.text = (coupon['terms_ar'] ?? '').toString();
      _termsEnCtrl.text = (coupon['terms_en'] ?? '').toString();
      _selectedCouponType = _normalizeCouponType(coupon['coupon_type']);
      _selectedIsActive = _parseBool(coupon['is_active'], fallback: true);
      _selectedStoreId = (coupon['store_id'] ?? '').toString();
      _selectedProviderId = coupon['provider_id']?.toString();
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

      final matchingProvider = providers.firstWhere(
        (p) => p['id'].toString() == _selectedProviderId,
        orElse: () => {},
      );
      if (matchingProvider.isNotEmpty) {
        _selectedProviderName = (matchingProvider['name'] ?? '').toString();
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
            _editingId == null
                ? webText(context, 'إضافة كوبون جديد', 'Add New Coupon')
                : webText(context, 'تعديل الكوبون', 'Edit Coupon'),
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

                    _inputField(
                        _couponCodeCtrl,
                        webText(context, 'كود الخصم', 'Discount Code'),
                        Icons.confirmation_number),
                    _inputField(
                        _couponDescArCtrl,
                        webText(context, 'وصف الكوبون (بالعربي)',
                            'Coupon Description (Arabic)'),
                        Icons.description,
                        maxLines: 3),
                    _inputField(_couponDescEnCtrl, 'Description (English)',
                        Icons.description_outlined,
                        maxLines: 3),
                    _inputField(
                        _couponWebCtrl,
                        webText(
                            context, 'رابط الموقع (Web Link)', 'Website Link'),
                        Icons.language_outlined),
                    _buildCouponTypePicker(setStateDialog),
                    if (_selectedCouponType != 'offer')
                      _inputField(
                        _discountPercentCtrl,
                        _selectedCouponType == 'cashback'
                            ? webText(
                                context,
                                'نسبة الرصيد المسترجع - مثال: 5 - 10',
                                'Cashback percent - example: 5 - 10')
                            : _selectedCouponType == 'extra_discount'
                                ? webText(
                                    context,
                                    'مبلغ الخصم الإضافي بالريال - اكتب الرقم فقط',
                                    'Extra discount amount in SAR - number only')
                                : webText(context, 'نسبة الخصم - مثال: 5 - 10',
                                    'Discount percent - example: 5 - 10'),
                        _selectedCouponType == 'extra_discount'
                            ? Icons.currency_exchange_rounded
                            : Icons.percent_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    _buildActiveSwitch(setStateDialog),
                    _inputField(
                      _termsArCtrl,
                      webText(context, 'شروط الاستخدام (بالعربي)',
                          'Usage terms (Arabic)'),
                      Icons.rule_rounded,
                      maxLines: 3,
                    ),
                    _inputField(
                      _termsEnCtrl,
                      'Usage terms (English)',
                      Icons.rule_folder_rounded,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 15),
                    _buildSectionTitle(
                        webText(context, 'تاريخ الانتهاء', 'Expiry Date')),
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
                                  ? webText(
                                      context,
                                      'ينتهي في: ${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month}-${_selectedExpiryDate!.day}',
                                      'Expires on: ${_selectedExpiryDate!.year}-${_selectedExpiryDate!.month}-${_selectedExpiryDate!.day}')
                                  : webText(
                                      context,
                                      'تاريخ انتهاء الصلاحية (اختياري)',
                                      'Expiry date (optional)'),
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
                    _buildSectionTitle(
                        webText(context, 'ربط المتجر', 'Link Store')),
                    _buildStorePicker(stores, setStateDialog),
                    const SizedBox(height: 12),
                    _buildProviderPicker(providers, setStateDialog),

                    const SizedBox(height: 20),
                    _buildSectionTitle(
                        webText(context, 'الوسوم (6 Tags)', 'Tags (6)')),
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
                          hintText:
                              webText(context, 'وسم ${i + 1}', 'Tag ${i + 1}'),
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
              child: Text(
                webText(context, 'إلغاء', 'Cancel'),
                style: const TextStyle(color: Colors.grey, fontFamily: _font),
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
                            ? webText(context, 'حفظ ونشر الكوبون',
                                'Save & Publish Coupon')
                            : webText(context, 'حفظ التعديلات', 'Save Changes'),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showStorePickerDialog(stores, setStateDialog),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Constants.primaryColor.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Constants.primaryColor.withValues(alpha: 0.10)),
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
                    ? webText(
                        context,
                        'تم اختيار المتجر: ${_selectedStoreName ?? _selectedStoreId}',
                        'Selected store: ${_selectedStoreName ?? _selectedStoreId}')
                    : webText(
                        context, 'اضغط لاختيار المتجر', 'Tap to choose store'),
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                  color: Colors.black54,
                  fontFamily: _font,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Future<void> _showStorePickerDialog(
      List<Map<String, dynamic>> stores, StateSetter setStateDialog) async {
    final searchCtrl = TextEditingController();
    var query = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStatePicker) {
          final filteredStores = stores.where((store) {
            final name = [
              store['name'],
              store['name_ar'],
              store['name_en'],
              store['slug'],
            ].whereType<Object>().join(' ').toLowerCase();
            return name.contains(query.toLowerCase().trim());
          }).toList();

          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(
              webText(context, 'اختر المتجر المرتبط', 'Choose linked store'),
              style: TextStyle(
                color: Constants.primaryColor,
                fontFamily: _font,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 520,
              height: 520,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    onChanged: (value) => setStatePicker(() => query = value),
                    decoration: InputDecoration(
                      hintText: webText(
                          context, 'ابحث عن اسم المتجر', 'Search stores'),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Constants.primaryColor),
                      filled: true,
                      fillColor:
                          Constants.primaryColor.withValues(alpha: 0.045),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Constants.primaryColor,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredStores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final store = filteredStores[i];
                        final storeName = store['name_ar'] ??
                            store['name'] ??
                            webText(context, 'متجر', 'Store');
                        final slug = (store['slug'] ?? '').toString();
                        final img = store['image'];

                        return Material(
                          color:
                              Constants.primaryColor.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              setStateDialog(() {
                                _selectedStoreId =
                                    (store['slug'] ?? store['id']).toString();
                                _selectedStoreImageUrl = img?.toString() ?? '';
                                _selectedStoreName = storeName.toString();
                              });
                              Navigator.pop(ctx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage:
                                        (img != null && img.isNotEmpty)
                                            ? NetworkImage(img)
                                            : null,
                                    backgroundColor: Constants.primaryColor
                                        .withValues(alpha: 0.08),
                                    child: (img == null || img.isEmpty)
                                        ? Icon(Icons.store,
                                            color: Constants.primaryColor,
                                            size: 18)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          storeName.toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: _font,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (slug.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            'ID: $slug',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: _font,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Constants.primaryColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    searchCtrl.dispose();
  }

  Widget _buildProviderPicker(
      List<Map<String, dynamic>> providers, StateSetter setStateDialog) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showProviderPickerDialog(providers, setStateDialog),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Constants.primaryColor.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Constants.primaryColor.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(Icons.business_center_outlined, color: Constants.primaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _selectedProviderId != null
                    ? webText(
                        context,
                        'تم اختيار الموفر: ${_selectedProviderName ?? _selectedProviderId}',
                        'Selected provider: ${_selectedProviderName ?? _selectedProviderId}')
                    : webText(context, 'اضغط لاختيار موفر الكوبونات',
                        'Tap to choose coupon provider'),
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                  color: Colors.black54,
                  fontFamily: _font,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Future<void> _showProviderPickerDialog(
      List<Map<String, dynamic>> providers, StateSetter setStateDialog) async {
    final searchCtrl = TextEditingController();
    var query = '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStatePicker) {
          final filteredProviders = providers.where((provider) {
            final text = [
              provider['name'],
            ].whereType<Object>().join(' ').toLowerCase();
            return text.contains(query.toLowerCase().trim());
          }).toList();

          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(
              webText(context, 'اختر موفر الكوبونات', 'Choose coupon provider'),
              style: TextStyle(
                color: Constants.primaryColor,
                fontFamily: _font,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SizedBox(
              width: 520,
              height: 520,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    onChanged: (value) => setStatePicker(() => query = value),
                    decoration: InputDecoration(
                      hintText: webText(
                          context, 'ابحث عن اسم الموفر', 'Search providers'),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Constants.primaryColor),
                      filled: true,
                      fillColor:
                          Constants.primaryColor.withValues(alpha: 0.045),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredProviders.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                      if (i == 0) {
                          return Material(
                            color:
                                Constants.primaryColor.withValues(alpha: 0.035),
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                setStateDialog(() {
                                  _selectedProviderId = null;
                                  _selectedProviderName = null;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Constants.primaryColor
                                          .withValues(alpha: 0.08),
                                      child: Icon(Icons.close_rounded,
                                          color: Constants.primaryColor,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        webText(
                                            context, 'بدون موفر', 'No provider'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontFamily: _font,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right_rounded,
                                        color: Constants.primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final provider = filteredProviders[i - 1];
                        final name = (provider['name'] ?? '').toString().trim();
                        return Material(
                          color:
                              Constants.primaryColor.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              setStateDialog(() {
                                _selectedProviderId = provider['id'].toString();
                                _selectedProviderName = name;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Constants.primaryColor
                                        .withValues(alpha: 0.08),
                                    child: Icon(
                                      Icons.business_center_outlined,
                                      color: Constants.primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name.isEmpty
                                          ? webText(
                                              context, 'موفر بدون اسم', 'Provider')
                                          : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontFamily: _font,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Constants.primaryColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    searchCtrl.dispose();
  }

  Widget _buildCouponTypePicker(StateSetter setStateDialog) {
    final items = {
      'coupon': webText(context, 'كوبون خصم', 'Discount coupon'),
      'cashback': webText(context, 'رصيد مسترجع', 'Cashback'),
      'offer': webText(context, 'عرض', 'Offer'),
      'extra_discount': webText(context, 'خصم إضافي', 'Extra discount'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCouponType,
        borderRadius: BorderRadius.circular(16),
        dropdownColor: Colors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: Constants.primaryColor),
        decoration: InputDecoration(
          prefixIcon:
              Icon(Icons.local_offer_rounded, color: Constants.primaryColor),
          labelText: webText(context, 'نوع العنصر', 'Item type'),
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.normal,
            fontFamily: _font,
          ),
          filled: true,
          fillColor: Constants.primaryColor.withValues(alpha: 0.045),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Constants.primaryColor.withValues(alpha: 0.10),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Constants.primaryColor,
              width: 1.4,
            ),
          ),
        ),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: const TextStyle(fontFamily: _font),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setStateDialog(() {
            _selectedCouponType = value;
            if (value == 'offer') _discountPercentCtrl.clear();
          });
        },
      ),
    );
  }

  Widget _buildActiveSwitch(StateSetter setStateDialog) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _selectedIsActive
                ? Icons.verified_rounded
                : Icons.error_outline_rounded,
            color: _selectedIsActive ? Colors.green : Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedIsActive
                  ? webText(context, 'الحالة: فعال', 'Status: active')
                  : webText(context, 'الحالة: غير فعال', 'Status: inactive'),
              style: const TextStyle(
                fontFamily: _font,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          Switch(
            value: _selectedIsActive,
            activeThumbColor: Constants.primaryColor,
            onChanged: (value) {
              setStateDialog(() => _selectedIsActive = value);
            },
          ),
        ],
      ),
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
        Text(
          webText(context, "صورة الكوبون", "Coupon Image"),
          style: const TextStyle(
              fontSize: 10, color: Colors.grey, fontFamily: _font),
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
        validator: (_) => null,
      ),
    );
  }

  Future<void> _saveCoupon(StateSetter setStateDialog) async {
    if (!(_couponFormKey.currentState?.validate() ?? false)) return;
    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      showSnackBar(context,
          webText(context, 'يرجى اختيار المتجر', 'Please choose a store'),
          isError: true);
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
      final discountPercent = _selectedCouponType == 'offer'
          ? null
          : _normalizeNumberText(_discountPercentCtrl.text);

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
        'provider_id': _selectedProviderId,
        'image': finalImageUrl,
        'discount_percent': discountPercent,
        'coupon_type': _selectedCouponType,
        'terms_ar': _termsArCtrl.text.trim(),
        'terms_en': _termsEnCtrl.text.trim().isEmpty
            ? _termsArCtrl.text.trim()
            : _termsEnCtrl.text.trim(),
        'is_active': _selectedIsActive,
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
      _refreshCoupons();
      showSnackBar(
          context,
          _editingId == null
              ? webText(context, 'تمت الإضافة بنجاح ✅', 'Added successfully')
              : webText(context, 'تم التحديث بنجاح ✅', 'Updated successfully'));
    } catch (e) {
      if (mounted) {
        final isTypeConstraintError =
            e.toString().contains('coupons_coupon_type_check');
        final isNumericRangeError =
            e.toString().contains('invalid input syntax for type numeric');
        showSnackBar(
          context,
          isTypeConstraintError
              ? webText(
                  context,
                  'يرجى تشغيل ملف add_extra_discount_coupon_type.sql في Supabase أولاً',
                  'Run add_extra_discount_coupon_type.sql in Supabase first',
                )
              : isNumericRangeError
                  ? webText(
                      context,
                      'يرجى تشغيل ملف allow_discount_ranges.sql في Supabase للسماح بالنطاق مثل 5 - 20',
                      'Run allow_discount_ranges.sql in Supabase to allow ranges such as 5 - 20',
                    )
                  : webText(context, 'خطأ: $e', 'Error: $e'),
          isError: true,
        );
      }
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
        title: Text(webText(context, 'حذف الكوبون؟', 'Delete coupon?'),
            style: const TextStyle(fontFamily: _font)),
        content: Text(
            webText(context, 'سيتم حذف الكوبون نهائياً. هل أنت متأكد؟',
                'The coupon will be permanently deleted. Are you sure?'),
            style: const TextStyle(fontFamily: _font)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(webText(context, 'إلغاء', 'Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(webText(context, 'حذف', 'Delete'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _sb.from('coupons').delete().eq('id', id);
        if (mounted) {
          _refreshCoupons();
          showSnackBar(
              context, webText(context, 'تم الحذف', 'Deleted successfully'));
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context,
              webText(context, 'خطأ في الحذف: $e', 'Delete failed: $e'),
              isError: true);
        }
      }
    }
  }

  String _normalizeCouponType(dynamic value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'رصيد مسترجع' ||
        text == 'رصيد' ||
        text == 'cash back' ||
        text == 'cash-back') {
      return 'cashback';
    }
    if (text == 'عرض' || text == 'offer') return 'offer';
    if (text == 'خصم إضافي' ||
        text == 'خصم اضافي' ||
        text == 'extra discount' ||
        text == 'extra_discount') {
      return 'extra_discount';
    }
    if (text == 'خصم' || text == 'كوبون خصم') return 'coupon';
    if (text == 'cashback' || text == 'offer' || text == 'extra_discount') {
      return text;
    }
    return 'coupon';
  }

  String _normalizeNumberText(String value) {
    const digits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(digits[char] ?? char);
    }

    return buffer
        .toString()
        .replaceAll('٪', '')
        .replaceAll('%', '')
        .replaceAll('٫', '.')
        .replaceAll(',', '.')
        .trim();
  }

  bool _parseBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (['true', 't', 'yes', 'y', '1'].contains(text)) return true;
    if (['false', 'f', 'no', 'n', '0'].contains(text)) return false;
    return fallback;
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
                  webText(context, 'إدارة الكوبونات', 'Manage Coupons'),
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
            webText(context, 'إضافة، تعديل، أو حذف أكواد الخصم بسهولة',
                'Add, edit, or delete discount codes easily'),
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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _couponsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      webText(
                          context,
                          'خطأ في تحميل الكوبونات: ${snapshot.error}',
                          'Failed to load coupons: ${snapshot.error}'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              final all = snapshot.data ?? [];
              if (all.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      webText(context, 'لا توجد كوبونات حالياً',
                          'No coupons available right now'),
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
                          webText(context, 'لا توجد نتائج مطابقة للبحث',
                              'No matching search results'),
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
              label: Text(
                webText(context, 'إضافة كوبون', 'Add Coupon'),
                style: const TextStyle(
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
            label: Text(
              webText(context, 'إضافة كوبون', 'Add Coupon'),
              style: const TextStyle(
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
                hintText: webText(context, 'ابحث بالكود أو اسم المتجر…',
                    'Search by code or store name...'),
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
              tooltip: webText(context, 'مسح', 'Clear'),
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
        mainAxisExtent:
            245, // ✅ ارتفاع كافٍ لاستيعاب الصورة + البادجات + الوصف + الـ footer
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
        final discountPercent = (coupon['discount_percent'] ?? '').toString();
        final couponType = _normalizeCouponType(coupon['coupon_type']);
        final isActive = _parseBool(coupon['is_active'], fallback: true);

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
          discountPercent: discountPercent,
          couponType: couponType,
          isActive: isActive,
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
    required String discountPercent,
    required String couponType,
    required bool isActive,
    required DateTime? expiryDate,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Coupon Image
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            width: 82,
                            height: 82,
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

                // Store Name + Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
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
                        code,
                        style: TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Constants.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  tooltip: webText(context, 'خيارات', 'Options'),
                  onSelected: (v) {
                    if (v == 'edit') _openAddOrEditDialog(coupon: coupon);
                    if (v == 'delete') _deleteCoupon(id);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: Text(webText(context, 'تعديل', 'Edit'))),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text(webText(context, 'حذف', 'Delete'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _adminInfoBadge(_couponTypeLabel(couponType)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _adminInfoBadge(
                    discountPercent.trim().isEmpty
                        ? webText(
                            context,
                            couponType == 'extra_discount'
                                ? 'المبلغ غير محدد'
                                : 'خصم غير محدد',
                            couponType == 'extra_discount'
                                ? 'Amount not set'
                                : 'Discount not set')
                        : webText(
                            context,
                            couponType == 'extra_discount'
                                ? 'خصم $discountPercent ر.س'
                                : 'خصم $discountPercent%',
                            couponType == 'extra_discount'
                                ? '$discountPercent SAR discount'
                                : '$discountPercent% discount'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _adminInfoBadge(
                    isActive
                        ? webText(context, 'فعال', 'Active')
                        : webText(context, 'غير فعال', 'Inactive'),
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description - لا يلتف ولا يرفع ارتفاع البطاقة عند النص الطويل
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 18,
                child: Text(
                  description.isEmpty
                      ? webText(context, 'بدون وصف', 'No description')
                      : description,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _font,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ),

            const Spacer(),

            const Divider(height: 18, thickness: 0.5),

            // Footer: Expiry + quick actions
            Row(
              children: [
                _expiryBadge(expiryDate),
                const Spacer(),
                IconButton(
                  tooltip: webText(context, 'تعديل', 'Edit'),
                  onPressed: () => _openAddOrEditDialog(coupon: coupon),
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[500]),
                ),
                IconButton(
                  tooltip: webText(context, 'حذف', 'Delete'),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 12, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              webText(context, 'غير محدد', 'Not set'),
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
                fontFamily: _font,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    final daysLeft = date.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final isCritical = daysLeft <= 5; // أحمر كامل

    // ✅ إذا بقي 5 أيام أو أقل: خلفية حمراء كاملة مع نص أبيض
    final bgColor = isCritical
        ? Colors.red
        : Constants.primaryColor.withValues(alpha: 0.10);
    final textColor = isCritical ? Colors.white : Constants.primaryColor;
    final borderColor = isCritical
        ? Colors.red
        : Constants.primaryColor.withValues(alpha: 0.18);

    // ✅ التاريخ
    final dateStr =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

    // ✅ المدة المتبقية مع التاريخ
    String remainingText;
    if (isExpired) {
      remainingText = webText(
          context,
          '$dateStr • منتهي منذ ${daysLeft.abs()} يوم',
          '$dateStr • expired ${daysLeft.abs()} days ago');
    } else if (daysLeft == 0) {
      remainingText = webText(
          context, '$dateStr • ينتهي اليوم!', '$dateStr • expires today');
    } else if (daysLeft == 1) {
      remainingText =
          webText(context, '$dateStr • باقي يوم واحد', '$dateStr • 1 day left');
    } else if (daysLeft <= 10) {
      remainingText = webText(context, '$dateStr • باقي $daysLeft أيام',
          '$dateStr • $daysLeft days left');
    } else {
      remainingText = webText(context, '$dateStr • باقي $daysLeft يوم',
          '$dateStr • $daysLeft days left');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 12, color: textColor),
          const SizedBox(width: 6),
          Text(
            remainingText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontFamily: _font,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminInfoBadge(String text, {Color? color}) {
    final effectiveColor = color ?? Constants.primaryColor;
    final isAccent = color == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 34,
      decoration: BoxDecoration(
        gradient: isAccent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB5B3FF),
                  Color(0xFF6D5DF6),
                ],
              )
            : null,
        color: isAccent ? null : effectiveColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccent
              ? const Color(0xFF7C6BFF).withValues(alpha: 0.30)
              : effectiveColor.withValues(alpha: 0.18),
        ),
        boxShadow: isAccent
            ? [
                BoxShadow(
                  color: const Color(0xFF6D5DF6).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isAccent ? Colors.white : effectiveColor,
            height: 1,
          ),
        ),
      ),
    );
  }

  String _couponTypeLabel(String type) {
    switch (type) {
      case 'cashback':
        return webText(context, 'رصيد مسترجع', 'Cashback');
      case 'offer':
        return webText(context, 'عرض', 'Offer');
      case 'extra_discount':
        return webText(context, 'خصم إضافي', 'Extra discount');
      default:
        return webText(context, 'كوبون خصم', 'Discount coupon');
    }
  }
}
