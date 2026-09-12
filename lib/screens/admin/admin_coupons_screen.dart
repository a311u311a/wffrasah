import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../../services/notification_service.dart';
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
  final _discountPercentCtrl = TextEditingController();
  final _termsArCtrl = TextEditingController();
  final _termsEnCtrl = TextEditingController();

  // Tags
  final List<TextEditingController> _tagCtrls =
      List.generate(6, (_) => TextEditingController());

  final _couponFormKey = GlobalKey<FormState>();

  // ✅ store_id في جدول coupons الآن = stores.slug (TEXT)
  String? _selectedStoreId; // هنا نخزن الـ slug
  String? _selectedStoreImageUrl;
  String? _selectedStoreName; // اختياري للعرض فقط
  String? _selectedStoreNameAr;
  String? _selectedStoreNameEn;
  String? _selectedProviderId;
  String? _selectedProviderName;
  String _selectedCouponType = 'coupon';
  bool _selectedIsActive = true;
  DateTime? _selectedExpiryDate;
  String? _editingId; // If editing coupon
  String? _editingImageUrl; // Old image if we are editing
  XFile? _pickedCouponImageFile;
  bool _isSaving = false;
  late Future<List<Map<String, dynamic>>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _couponsFuture = _fetchCoupons();
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

    _selectedStoreId = null;
    _selectedStoreImageUrl = null;
    _selectedStoreName = null;
    _selectedStoreNameAr = null;
    _selectedStoreNameEn = null;
    _selectedProviderId = null;
    _selectedProviderName = null;
    _selectedCouponType = 'coupon';
    _selectedIsActive = true;
    _selectedExpiryDate = null;
  }

  void _showProviderPicker(
      List<Map<String, dynamic>> providers, StateSetter setStateSheet) {
    final searchCtrl = TextEditingController();
    var query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStatePicker) {
          final filteredProviders = providers.where((provider) {
            final text = [
              provider['name'],
            ].whereType<Object>().join(' ').toLowerCase();
            return text.contains(query.toLowerCase().trim());
          }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.70,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر موفر الكوبونات',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchCtrl,
                  onChanged: (value) => setStatePicker(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم الموفر',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Constants.primaryColor),
                    filled: true,
                    fillColor: Constants.primaryColor.withValues(alpha: 0.045),
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
                          color: Constants.primaryColor.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              setStateSheet(() {
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
                                        color: Constants.primaryColor, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'بدون موفر',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
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

                      final data = filteredProviders[i - 1];
                      final name = (data['name'] ?? 'موفر بدون اسم').toString();
                      return Material(
                        color: Constants.primaryColor.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setStateSheet(() {
                              _selectedProviderId = data['id'].toString();
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
                                  child: Icon(Icons.business_center_outlined,
                                      color: Constants.primaryColor, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
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
          );
        },
      ),
    ).whenComplete(searchCtrl.dispose);
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
    final searchCtrl = TextEditingController();
    var query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر المتجر المرتبط',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchCtrl,
                  onChanged: (value) => setStatePicker(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اسم المتجر',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Constants.primaryColor),
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
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredStores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final data = filteredStores[i];
                      final storeName =
                          data['name_ar'] ?? data['name'] ?? 'متجر بدون اسم';
                      final storeNameAr =
                          (data['name_ar'] ?? data['name'] ?? '')
                              .toString()
                              .trim();
                      final storeNameEn =
                          (data['name_en'] ?? data['name'] ?? storeNameAr)
                              .toString()
                              .trim();
                      final img = data['image'];
                      final slug = (data['slug'] ?? '').toString();

                      return Material(
                        color: Constants.primaryColor.withValues(alpha: 0.035),
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setStateSheet(() {
                              _selectedStoreId =
                                  (data['slug'] ?? data['id']).toString();
                              _selectedStoreImageUrl = img?.toString() ?? '';
                              _selectedStoreName = storeName.toString();
                              _selectedStoreNameAr = storeNameAr;
                              _selectedStoreNameEn = storeNameEn;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage:
                                      (img != null && img.isNotEmpty)
                                          ? NetworkImage(img)
                                          : null,
                                  backgroundColor: Constants.primaryColor
                                      .withValues(alpha: 0.08),
                                  child: (img == null || img.isEmpty)
                                      ? Icon(Icons.store,
                                          color: Constants.primaryColor)
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
                                        style: TextStyle(
                                          fontSize: _storePickerNameFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: Constants.textColor,
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
          );
        },
      ),
    ).whenComplete(searchCtrl.dispose);
  }

  Future<void> _openAddOrEditSheet({Map<String, dynamic>? coupon}) async {
    _clearForm();

    // ✅ Fetch stores (مع slug)
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

      // ✅ coupon.store_id الآن هو slug
      _selectedStoreId = (coupon['store_id'] ?? '').toString();
      _selectedProviderId = coupon['provider_id']?.toString();
      _editingImageUrl = (coupon['image'] ?? '').toString();

      final matchingProvider = providers.firstWhere(
        (p) => p['id'].toString() == _selectedProviderId,
        orElse: () => {},
      );
      if (matchingProvider.isNotEmpty) {
        _selectedProviderName = (matchingProvider['name'] ?? '').toString();
      }

      // ✅ Try to find current store by slug
      final matchingStore = stores.firstWhere(
        (s) => (s['slug'] ?? s['id']).toString() == _selectedStoreId,
        orElse: () => {},
      );

      if (matchingStore.isNotEmpty) {
        _selectedStoreImageUrl = (matchingStore['image'] ?? '').toString();
        _selectedStoreNameAr =
            (matchingStore['name_ar'] ?? matchingStore['name'] ?? '')
                .toString()
                .trim();
        _selectedStoreNameEn =
            (matchingStore['name_en'] ?? matchingStore['name'] ?? '')
                .toString()
                .trim();
        _selectedStoreName = _selectedStoreNameAr!.isNotEmpty
            ? _selectedStoreNameAr
            : _selectedStoreNameEn;
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
                            _buildCouponTypePicker(setStateSheet),
                            if (_selectedCouponType != 'offer')
                              _inputField(
                                _discountPercentCtrl,
                                _selectedCouponType == 'cashback'
                                    ? 'نسبة الرصيد المسترجع - مثال: 5 - 10'
                                    : _selectedCouponType == 'extra_discount'
                                        ? 'مبلغ الخصم الإضافي بالريال - اكتب الرقم فقط'
                                        : 'نسبة الخصم - مثال: 5 - 10',
                                _selectedCouponType == 'extra_discount'
                                    ? Icons.currency_exchange_rounded
                                    : Icons.percent_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            _buildActiveSwitch(setStateSheet),
                            _inputField(
                              _termsArCtrl,
                              'شروط الاستخدام (بالعربي)',
                              Icons.rule_rounded,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                            ),
                            _inputField(
                              _termsEnCtrl,
                              'Usage terms (English)',
                              Icons.rule_folder_rounded,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                            ),

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
                                          fontSize: 13,
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
                                    Expanded(
                                      child: Text(
                                        _selectedStoreId != null
                                            ? 'تم اختيار المتجر: ${_selectedStoreName ?? _selectedStoreId}'
                                            : 'اضغط لاختيار المتجر',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: _selectedStoreFontSize,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),
                            InkWell(
                              onTap: () =>
                                  _showProviderPicker(providers, setStateSheet),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.business_center_outlined,
                                        color: Constants.primaryColor),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        _selectedProviderId != null
                                            ? 'تم اختيار الموفر: ${_selectedProviderName ?? _selectedProviderId}'
                                            : 'اضغط لاختيار موفر الكوبونات',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
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

      final storeNameAr =
          (_selectedStoreNameAr ?? _selectedStoreName ?? '').trim();
      final storeNameEn =
          (_selectedStoreNameEn ?? _selectedStoreName ?? storeNameAr).trim();
      final discountPercent = _selectedCouponType == 'offer'
          ? null
          : _normalizeNumberText(_discountPercentCtrl.text);

      final payload = {
        'code': _couponCodeCtrl.text.trim(),
        'name_ar': storeNameAr,
        'name_en': storeNameEn.isNotEmpty ? storeNameEn : storeNameAr,
        'description_ar': _couponDescArCtrl.text.trim(),
        'description_en': _couponDescEnCtrl.text.trim().isEmpty
            ? _couponDescArCtrl.text.trim()
            : _couponDescEnCtrl.text.trim(),

        // Fallbacks
        'name': storeNameAr,
        'description': _couponDescArCtrl.text.trim(),

        'web': _couponWebCtrl.text.trim(),

        // ✅ store_id لازم يكون slug
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
        // ✅ لا نرسل created_at (خليه من الداتابيس إذا موجود default)
        final inserted = await _sb
            .from('coupons')
            .insert(payload)
            .select('id')
            .maybeSingle();
        final couponId = inserted?['id']?.toString() ?? '';
        if (couponId.isNotEmpty) {
          unawaited(
            NotificationService.notifyFavoriteStoreFollowers(
              couponId: couponId,
              storeId: _selectedStoreId ?? '',
              storeName: storeNameAr,
              imageUrl: finalImageUrl,
            ),
          );
        }
      } else {
        await _sb.from('coupons').update(payload).eq('id', _editingId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _refreshCoupons();
      showSnackBar(context,
          _editingId == null ? 'تمت الإضافة بنجاح ✅' : 'تم التحديث بنجاح ✅');
    } catch (e) {
      if (mounted) {
        final errorText = e.toString();
        final message = errorText.contains('coupons_coupon_type_check')
            ? 'يرجى تشغيل ملف add_extra_discount_coupon_type.sql في Supabase أولاً'
            : errorText.contains('invalid input syntax for type numeric')
                ? 'يرجى تشغيل ملف allow_discount_ranges.sql في Supabase للسماح بالنطاق مثل 5 - 20'
                : 'خطأ: $e';
        showSnackBar(context, message, isError: true);
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
        if (mounted) {
          _refreshCoupons();
          showSnackBar(context, 'تم الحذف');
        }
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
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

  bool _parseBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (['true', 't', 'yes', 'y', '1'].contains(text)) return true;
    if (['false', 'f', 'no', 'n', '0'].contains(text)) return false;
    return fallback;
  }

  double get _storePickerNameFontSize =>
      !kIsWeb && Platform.isAndroid ? 11 : 13;

  double get _selectedStoreFontSize => !kIsWeb && Platform.isAndroid ? 12 : 13;

  String _formatDiscountPercent(dynamic value) {
    final normalized = _normalizeNumberText((value ?? '').toString());
    if (normalized.isEmpty) return '';
    return normalized
        .split(RegExp(r'\s*[-–—]\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' - ');
  }

  String _couponTypeLabel(String type) {
    switch (type) {
      case 'cashback':
        return 'رصيد مسترجع';
      case 'offer':
        return 'عرض';
      case 'extra_discount':
        return 'خصم إضافي';
      default:
        return 'كوبون خصم';
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

  Widget _buildCouponTypePicker(StateSetter setStateSheet) {
    const items = {
      'coupon': 'كوبون خصم',
      'cashback': 'رصيد مسترجع',
      'offer': 'عرض',
      'extra_discount': 'خصم إضافي',
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
          labelText: 'نوع العنصر',
          labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Constants.primaryColor.withValues(alpha: 0.045),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Constants.primaryColor.withValues(alpha: 0.10))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Constants.primaryColor.withValues(alpha: 0.10))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Constants.primaryColor, width: 1.4)),
        ),
        items: items.entries
            .map((entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Constants.textColor,
                    ),
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setStateSheet(() {
            _selectedCouponType = value;
            if (value == 'offer') _discountPercentCtrl.clear();
          });
        },
      ),
    );
  }

  Widget _buildActiveSwitch(StateSetter setStateSheet) {
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
              _selectedIsActive ? 'الحالة: فعال' : 'الحالة: غير فعال',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ),
          Switch(
            value: _selectedIsActive,
            activeThumbColor: Constants.primaryColor,
            onChanged: (value) {
              setStateSheet(() => _selectedIsActive = value);
            },
          ),
        ],
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

  Widget _adminBadge(String text, {Color? color}) {
    final effectiveColor = color ?? Constants.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: effectiveColor,
        ),
      ),
    );
  }

  Widget _couponCard(Map<String, dynamic> data) {
    final id = data['id'].toString();
    final name = data['name_ar'] ?? data['name'] ?? '';
    final code = data['code'] ?? '';
    final image = data['image'];
    final storeId = data['store_id']; // هذا الآن slug
    final couponType = _normalizeCouponType(data['coupon_type']);
    final discountPercent = _formatDiscountPercent(data['discount_percent']);
    final isActive = _parseBool(data['is_active'], fallback: true);

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
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _adminBadge(_couponTypeLabel(couponType)),
                  if (couponType != 'offer')
                    _adminBadge(
                      discountPercent.isEmpty
                          ? couponType == 'extra_discount'
                              ? 'المبلغ غير محدد'
                              : 'النسبة غير محددة'
                          : couponType == 'extra_discount'
                              ? '$discountPercent ر.س'
                              : '$discountPercent%',
                    ),
                  _adminBadge(
                    isActive ? 'فعال' : 'غير فعال',
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ],
              ),
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
                  Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('• النوع: ${_couponTypeLabel(couponType)}')),
                  if (couponType != 'offer')
                    Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(discountPercent.isEmpty
                            ? couponType == 'extra_discount'
                                ? '• المبلغ: غير محدد'
                                : '• النسبة: غير محددة'
                            : couponType == 'extra_discount'
                                ? '• المبلغ: $discountPercent ر.س'
                                : '• النسبة: $discountPercent%')),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child:
                          Text('• الحالة: ${isActive ? 'فعال' : 'غير فعال'}')),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _couponsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('خطأ في تحميل الكوبونات: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[400])),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text('لا توجد كوبونات حالياً',
                        style: TextStyle(color: Colors.grey[400])),
                  );
                }

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
