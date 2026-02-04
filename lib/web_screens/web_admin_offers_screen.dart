import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rbhan/screens/login_signup/widgets/snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/offers.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

// ✅ صفحة إدارة العروض على الويب (مستقلة) - تصميم مُحدّث
class WebAdminOffersScreen extends StatefulWidget {
  final bool isEmbedded;
  const WebAdminOffersScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminOffersScreen> createState() => _WebAdminOffersScreenState();
}

class _WebAdminOffersScreenState extends State<WebAdminOffersScreen> {
  static const String _font = 'Tajawal';
  final SupabaseClient _sb = Supabase.instance.client;

  // Cache store names: storeId (slug) -> Name
  Map<String, String> _storeNames = {};

  // UI search
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchStoreNames();
  }

  Future<void> _fetchStoreNames() async {
    try {
      final res = await _sb.from('stores').select('slug, name, name_ar');
      final data = res as List;
      final map = <String, String>{};
      for (final item in data) {
        final slug = (item['slug'] ?? '').toString();
        final nameAr = (item['name_ar'] ?? '').toString();
        final nameEn = (item['name'] ?? '').toString();
        map[slug] = nameAr.isNotEmpty ? nameAr : nameEn;
      }
      if (mounted) setState(() => _storeNames = map);
    } catch (e) {
      debugPrint('Error fetching store names: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =========================
  // Actions
  // =========================

  Future<void> _deleteOffer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('حذف العرض؟', style: TextStyle(fontFamily: _font)),
        content: const Text('سيتم حذف العرض نهائياً. هل أنت متأكد؟',
            style: TextStyle(fontFamily: _font)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: _font,
                    fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _sb.from('offers').delete().eq('id', id);
        if (mounted) showSnackBar(context, 'تم حذف العرض');
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
  }

  Future<void> _openAddOrEditDialog({Offer? offer}) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  offer == null
                      ? Icons.add_business_rounded
                      : Icons.edit_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  offer == null ? 'إضافة عرض جديد' : 'تعديل العرض',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[900],
                    fontFamily: _font,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
              ),
            ],
          ),
          content: SizedBox(
            width: 760,
            height: ResponsiveLayout.isDesktop(context) ? 640 : 560,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _OfferFormSheet(offer: offer),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // Build
  // =========================

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildBody(),
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
                child: Icon(Icons.local_offer_rounded,
                    color: Constants.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة العروض',
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
            'إضافة، تعديل، أو حذف العروض بسهولة',
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

  Widget _buildBody() {
    return Container(
      padding: ResponsivePadding.page(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchAndAddRow(),
          const SizedBox(height: 18),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _sb.from('offers').stream(primaryKey: ['id']).order(
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
                      'لا توجد عروض حالياً',
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

              final filtered = _applySearch(all);
              return _buildOffersList(filtered);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // =========================
  // Search + Add button row
  // =========================

  Widget _searchAndAddRow() {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final addBtn = SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: () => _openAddOrEditDialog(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إضافة عرض',
          style: TextStyle(
            color: Colors.white,
            fontFamily: _font,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    final search = _searchBar();

    if (!isDesktop) {
      return Column(
        children: [
          search,
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: addBtn),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 12),
        addBtn,
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
                hintText: 'ابحث بالوصف أو الوسوم أو الرابط…',
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

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;

    bool match(Map<String, dynamic> r) {
      final desc = (r['description_ar'] ?? r['description'] ?? '')
          .toString()
          .toLowerCase();
      final web = (r['web'] ?? '').toString().toLowerCase();

      final tagsRaw = r['tags'];
      final tags = (tagsRaw is List)
          ? tagsRaw.map((e) => e.toString().toLowerCase()).join(' ')
          : '';

      final code = (r['code'] ?? '').toString().toLowerCase(); // ✅ بحث بالكود

      return desc.contains(q) ||
          web.contains(q) ||
          tags.contains(q) ||
          code.contains(q);
    }

    return items.where(match).toList();
  }

  // =========================
  // Grid UI
  // =========================

  Widget _buildOffersList(List<Map<String, dynamic>> items) {
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
        mainAxisExtent: 185, // ✅ زودناها شوي عشان ترتيب النصوص
      ),
      itemBuilder: (context, index) {
        final data = items[index];

        final tags = (data['tags'] is List)
            ? List<String>.from(data['tags'])
            : <String>[];

        final offerModel = Offer(
          id: data['id'].toString(),
          // ✅ الاسم لم يعد مهم بالواجهة
          name: '',
          nameAr: '',
          nameEn: '',
          description:
              (data['description_ar'] ?? data['description'] ?? '').toString(),
          descriptionAr: (data['description_ar'] ?? '').toString(),
          descriptionEn: (data['description_en'] ?? '').toString(),
          image: (data['image'] ?? '').toString(),
          web: (data['web'] ?? '').toString(),
          tags: tags,
          categoryId:
              (data['category_id'] ?? data['categoryId'] ?? '').toString(),
          expiryDate: data['expiry_date'] != null
              ? DateTime.tryParse(data['expiry_date'].toString())
              : null,

          // ✅ مهم: لازم يكون Offer model عندك يحتوي storeId
          // لو موجود سابقاً تمام
          // ignore: deprecated_member_use_from_same_package
          storeId: (data['store_id'] ?? '').toString(),

          // ✅ كود الخصم
          code: (data['code'] ?? data['coupon_code'] ?? '').toString(),
        );

        return _offerCard(offerModel, data['id'].toString());
      },
    );
  }

  // ✅ بطاقة العرض الجديدة: اسم المتجر بالأعلى + تحته الكود + الوصف بالمنتصف
  Widget _offerCard(Offer offer, String id) {
    final storeName = _storeNames[offer.storeId] ?? 'بدون متجر';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Top Row: Image + Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: offer.image.isNotEmpty
                        ? Image.network(
                            offer.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image,
                              color: Colors.grey[500],
                            ),
                          )
                        : Icon(Icons.local_offer_outlined,
                            color: Constants.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name + menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _font,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 26,
                            width: 26,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              tooltip: 'خيارات',
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _openAddOrEditDialog(offer: offer);
                                }
                                if (v == 'delete') {
                                  _deleteOffer(id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('تعديل')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('حذف')),
                              ],
                              child: Icon(Icons.more_horiz,
                                  color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // ✅ Code badge تحت اسم المتجر
                      if (offer.code.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Constants.primaryColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Constants.primaryColor
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number_rounded,
                                  size: 14, color: Constants.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                offer.code,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                  color: Constants.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'بدون كود',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ✅ الوصف في منتصف البطاقة
            Expanded(
              child: (offer.description.isNotEmpty)
                  ? Text(
                      offer.description,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      'لا يوجد وصف',
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),

            const Divider(height: 18, thickness: 0.5),

            // Footer: Buttons + Expiry
            Row(
              children: [
                // Buttons left
                Row(
                  children: [
                    InkWell(
                      onTap: () => _openAddOrEditDialog(offer: offer),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.edit_note_rounded,
                            size: 20, color: Colors.blueGrey[500]),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _deleteOffer(id),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_sweep_outlined,
                            size: 20, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Expiry Info (Right)
                if (offer.expiryDate != null)
                  Builder(builder: (_) {
                    final daysLeft =
                        offer.expiryDate!.difference(DateTime.now()).inDays;
                    final isSoon = daysLeft <= 5;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSoon ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSoon ? Colors.red[100]! : Colors.green[100]!,
                        ),
                      ),
                      child: Text(
                        daysLeft < 0
                            ? 'منتهي منذ ${daysLeft.abs()} يوم'
                            : 'باقي $daysLeft يوم',
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 10,
                          color: isSoon ? Colors.red[700] : Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ✅ نموذج إضافة/تعديل العرض (Form Sheet) - حسب ترتيبك + زرين
// ═══════════════════════════════════════════════════════════════════════════

class _OfferFormSheet extends StatefulWidget {
  final Offer? offer;
  const _OfferFormSheet({this.offer});

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  static const String _font = 'Tajawal';
  final SupabaseClient _sb = Supabase.instance.client;

  final TextEditingController _descArCtrl = TextEditingController();
  final TextEditingController _descEnCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _storeUrlCtrl = TextEditingController();
  final TextEditingController _tagsCtrl = TextEditingController();

  String? _imageUrl;
  Uint8List? _pickedImageBytes;
  String? _selectedCategoryId;
  String? _selectedStoreId;
  List<Map<String, dynamic>> _stores = [];
  DateTime? _expiryDate;
  bool _saving = false;

  bool get _isEdit => widget.offer != null;

  @override
  void initState() {
    super.initState();
    _fetchStores();

    if (_isEdit) {
      final o = widget.offer!;
      _descArCtrl.text = o.descriptionAr;
      _descEnCtrl.text = o.descriptionEn;
      _storeUrlCtrl.text = o.web;
      _tagsCtrl.text = o.tags.join(', ');
      _imageUrl = o.image;
      _selectedCategoryId = o.categoryId.isNotEmpty ? o.categoryId : null;
      _selectedStoreId = o.storeId.isNotEmpty ? o.storeId : null;
      _expiryDate = o.expiryDate;

      // ✅ استرجاع كود الخصم عند التعديل
      _codeCtrl.text = o.code;
    }
  }

  Future<void> _fetchStores() async {
    try {
      final res = await _sb
          .from('stores')
          .select('slug, name, name_ar, image')
          .order('name');
      if (mounted) {
        setState(() {
          _stores = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching stores: $e');
    }
  }

  @override
  void dispose() {
    _descArCtrl.dispose();
    _descEnCtrl.dispose();
    _codeCtrl.dispose();
    _storeUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImageBytes == null) return _imageUrl;

    try {
      final fileName = 'offer_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'offers/$fileName';

      await _sb.storage.from('images').uploadBinary(
            path,
            _pickedImageBytes!,
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

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      showSnackBar(context, 'الرجاء اختيار المتجر', isError: true);
      return;
    }
    if (_descArCtrl.text.trim().isEmpty) {
      showSnackBar(context, 'الرجاء إدخال الوصف بالعربية', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final uploadedUrl = await _uploadImage();

      final tags = _tagsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final data = {
        'name_ar': '',
        'name_en': '',
        'description_ar': _descArCtrl.text.trim(),
        'description_en': _descEnCtrl.text.trim(),

        // ✅ كود الخصم
        'code': _codeCtrl.text.trim(), // لو عمودك coupon_code غيّرها هنا

        // ✅ رابط المتجر
        'web': _storeUrlCtrl.text.trim(),

        'image': uploadedUrl ?? '',
        'tags': tags,
        'category_id': _selectedCategoryId,
        'store_id': _selectedStoreId,
        'expiry_date': _expiryDate?.toIso8601String(),
      };

      if (_isEdit) {
        await _sb.from('offers').update(data).eq('id', widget.offer!.id);
        if (mounted) showSnackBar(context, 'تم تحديث العرض بنجاح');
      } else {
        await _sb.from('offers').insert(data);
        if (mounted) showSnackBar(context, 'تم إضافة العرض بنجاح');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) الصورة
            _buildSectionTitle('صورة العرض'),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _pickedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(_pickedImageBytes!,
                              fit: BoxFit.cover),
                        )
                      : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child:
                                  Image.network(_imageUrl!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 6),
                                Text('اختر صورة',
                                    style: TextStyle(
                                        fontFamily: _font,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2) اختر المتجر
            _buildSectionTitle('اختر المتجر'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStoreId,
                  hint: Text('اختر المتجر',
                      style: TextStyle(
                          fontFamily: _font, color: Colors.grey[500])),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('اختر المتجر',
                          style: TextStyle(fontFamily: _font)),
                    ),
                    ..._stores.map((s) {
                      final name = (s['name_ar'] ?? s['name'] ?? '').toString();
                      final slug = (s['slug'] ?? '').toString();
                      return DropdownMenuItem<String>(
                        value: slug,
                        child: Text(name,
                            style: const TextStyle(fontFamily: _font)),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedStoreId = v),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3) فئة العرض
            _buildSectionTitle('فئة العرض'),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _sb.from('categories').select(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategoryId,
                      hint: Text('اختر الفئة',
                          style: TextStyle(
                              fontFamily: _font, color: Colors.grey[500])),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('بدون فئة',
                              style: TextStyle(fontFamily: _font)),
                        ),
                        ...categories.map((cat) => DropdownMenuItem<String>(
                              value: cat['id'].toString(),
                              child: Text(
                                (cat['name_ar'] ?? cat['name'] ?? '')
                                    .toString(),
                                style: const TextStyle(fontFamily: _font),
                              ),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 4) تاريخ الصلاحية
            _buildSectionTitle('تاريخ الصلاحية'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickExpiryDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.grey[500]),
                    const SizedBox(width: 12),
                    Text(
                      _expiryDate != null
                          ? '${_expiryDate!.year}/${_expiryDate!.month}/${_expiryDate!.day}'
                          : 'اختر التاريخ',
                      style: TextStyle(
                        fontFamily: _font,
                        fontWeight: FontWeight.w700,
                        color: _expiryDate != null
                            ? Colors.grey[800]
                            : Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child:
                            Icon(Icons.clear_rounded, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5) الوصف بالعربي
            _buildSectionTitle('الوصف بالعربية'),
            const SizedBox(height: 10),
            _inputField(
              _descArCtrl,
              'اكتب وصف العرض بالعربية',
              Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 6) الوصف بالانجليزي
            _buildSectionTitle('الوصف بالإنجليزية'),
            const SizedBox(height: 10),
            _inputField(
              _descEnCtrl,
              'Write offer description in English',
              Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 7) كود الخصم
            _buildSectionTitle('كود الخصم'),
            const SizedBox(height: 10),
            _inputField(
              _codeCtrl,
              'مثال: RBHAN20',
              Icons.confirmation_number_rounded,
            ),
            const SizedBox(height: 24),

            // 8) رابط المتجر
            _buildSectionTitle('رابط المتجر'),
            const SizedBox(height: 10),
            _inputField(
              _storeUrlCtrl,
              'https://store.com',
              Icons.link_rounded,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('الوسوم (اختياري)'),
            const SizedBox(height: 10),
            _inputField(_tagsCtrl, 'خصم, عرض, رمضان', Icons.tag_rounded),
            const SizedBox(height: 32),

            // زرين
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _isEdit ? 'تحديث العرض' : 'إضافة العرض',
                              style: const TextStyle(
                                fontFamily: _font,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: _font,
        fontWeight: FontWeight.w900,
        fontSize: 14,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: _font, color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w700,
          color: Colors.grey[900],
        ),
      ),
    );
  }
}
