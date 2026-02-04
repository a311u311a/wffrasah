import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة إدارة المتاجر على الويب (UI مُعاد تصميمه - نفس الخصائص)
class WebAdminStoresScreen extends StatefulWidget {
  final bool isEmbedded;
  const WebAdminStoresScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminStoresScreen> createState() => _WebAdminStoresScreenState();
}

class _WebAdminStoresScreenState extends State<WebAdminStoresScreen> {
  static const String _font = 'Tajawal';

  final SupabaseClient _sb = Supabase.instance.client;

  // Form
  final _storeNameArCtrl = TextEditingController();
  final _storeNameEnCtrl = TextEditingController();
  final _storeDescArCtrl = TextEditingController();
  final _storeDescEnCtrl = TextEditingController();
  final _storeFormKey = GlobalKey<FormState>();

  String? _editingId;
  String? _editingImageUrl;
  XFile? _pickedStoreImageFile;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  // Picker
  final ImagePicker _picker = ImagePicker();

  // UI state
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _storeNameArCtrl.dispose();
    _storeNameEnCtrl.dispose();
    _storeDescArCtrl.dispose();
    _storeDescEnCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _editingId = null;
    _editingImageUrl = null;
    _storeNameArCtrl.clear();
    _storeNameEnCtrl.clear();
    _storeDescArCtrl.clear();
    _storeDescEnCtrl.clear();
    _pickedStoreImageFile = null;
    _pickedImageBytes = null;
  }

  String _toSlug(String input) {
    final s = input.trim().toLowerCase();
    final slug = s
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\-_]'), '');
    return slug.isEmpty
        ? 'store-${DateTime.now().millisecondsSinceEpoch}'
        : slug;
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

  Future<void> _openAddOrEditDialog({Map<String, dynamic>? store}) async {
    _clearForm();

    if (store != null) {
      _editingId = (store['id'] ?? '').toString();
      _storeNameArCtrl.text =
          (store['name_ar'] ?? store['name'] ?? '').toString();
      _storeNameEnCtrl.text =
          (store['name_en'] ?? store['name'] ?? '').toString();
      _storeDescArCtrl.text =
          (store['description_ar'] ?? store['description'] ?? '').toString();
      _storeDescEnCtrl.text =
          (store['description_en'] ?? store['description'] ?? '').toString();
      _editingImageUrl = (store['image'] ?? '').toString();
    }

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
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _editingId == null
                      ? Icons.add_business_rounded
                      : Icons.edit_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _editingId == null ? 'إضافة متجر جديد' : 'تعديل المتجر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[900],
                    fontFamily: _font,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Form(
                key: _storeFormKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // صورة المتجر
                    _imagePickerCard(setStateDialog),

                    const SizedBox(height: 16),

                    // حقول
                    _twoColumns(
                      left: _inputField(
                        _storeNameArCtrl,
                        'اسم المتجر (عربي)',
                        Icons.storefront_rounded,
                      ),
                      right: _inputField(
                        _storeNameEnCtrl,
                        'Store Name (English)',
                        Icons.storefront_outlined,
                      ),
                    ),
                    _twoColumns(
                      left: _inputField(
                        _storeDescArCtrl,
                        'وصف المتجر (عربي)',
                        Icons.description_rounded,
                        maxLines: 3,
                      ),
                      right: _inputField(
                        _storeDescEnCtrl,
                        'Store Description (English)',
                        Icons.description_outlined,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: _font,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : () => _saveStore(setStateDialog),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded,
                        color: Colors.white),
                label: Text(
                  _editingId == null ? 'إضافة' : 'حفظ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

  Widget _imagePickerCard(StateSetter setStateDialog) {
    DecorationImage? imageProvider;
    if (_pickedImageBytes != null) {
      imageProvider = DecorationImage(
        image: MemoryImage(_pickedImageBytes!),
        fit: BoxFit.contain,
      );
    } else if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) {
      imageProvider = DecorationImage(
        image: NetworkImage(_editingImageUrl!),
        fit: BoxFit.contain,
      );
    }

    return InkWell(
      onTap: () async {
        final XFile? xfile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          imageQuality: 85,
        );
        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          setStateDialog(() {
            _pickedStoreImageFile = xfile;
            _pickedImageBytes = bytes;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
                image: imageProvider,
              ),
              child: imageProvider != null
                  ? null
                  : Icon(Icons.add_a_photo_rounded,
                      color: Constants.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'شعار المتجر',
                    style: TextStyle(
                      fontFamily: _font,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط لاختيار صورة (يفضل PNG أو JPG)',
                    style: TextStyle(
                      fontFamily: _font,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_rounded, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _twoColumns({required Widget left, required Widget right}) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    if (!isDesktop) {
      return Column(
        children: [
          left,
          const SizedBox(height: 10),
          right,
          const SizedBox(height: 10),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int? maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Constants.primaryColor),
          labelText: hint,
          labelStyle: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Constants.primaryColor, width: 2),
          ),
        ),
        style: TextStyle(
          fontFamily: _font,
          fontWeight: FontWeight.w800,
          color: Colors.grey[900],
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Future<void> _saveStore(StateSetter setStateDialog) async {
    if (!(_storeFormKey.currentState?.validate() ?? false)) return;

    setStateDialog(() => _isSaving = true);
    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _editingImageUrl;

      if (_pickedStoreImageFile != null) {
        final path = 'stores/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _uploadFile(_pickedStoreImageFile!, path);
        if (url != null) finalImageUrl = url;
      }

      final baseForSlug = _storeNameEnCtrl.text.trim().isNotEmpty
          ? _storeNameEnCtrl.text.trim()
          : _storeNameArCtrl.text.trim();
      final slug = _toSlug(baseForSlug);

      final payload = {
        'name_ar': _storeNameArCtrl.text.trim(),
        'name_en': _storeNameEnCtrl.text.trim().isEmpty
            ? _storeNameArCtrl.text.trim()
            : _storeNameEnCtrl.text.trim(),
        'description_ar': _storeDescArCtrl.text.trim(),
        'description_en': _storeDescEnCtrl.text.trim().isEmpty
            ? _storeDescArCtrl.text.trim()
            : _storeDescEnCtrl.text.trim(),
        'name': _storeNameArCtrl.text.trim(),
        'description': _storeDescArCtrl.text.trim(),
        'slug': slug,
        'image': finalImageUrl ?? '',
      };

      if (_editingId == null) {
        await _sb.from('stores').insert(payload);
      } else {
        await _sb.from('stores').update(payload).eq('id', _editingId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      showSnackBar(
        context,
        _editingId == null ? 'تمت الإضافة بنجاح' : 'تم التحديث بنجاح',
      );
    } catch (e) {
      if (mounted) showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) {
        setStateDialog(() => _isSaving = false);
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteStore(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المتجر؟', style: TextStyle(fontFamily: _font)),
        content: const Text(
          'سيتم حذف المتجر وكل الكوبونات المرتبطة به. هل أنت متأكد؟',
          style: TextStyle(fontFamily: _font),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _sb.from('stores').delete().eq('id', id);
        if (mounted) showSnackBar(context, 'تم حذف المتجر');
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
  }

  /// ✅ جلب عدد الكوبونات مرة واحدة لكل عرض (بدل FutureBuilder لكل صف)
  Future<Map<String, int>> _fetchCouponsCount(
      List<Map<String, dynamic>> stores) async {
    final Map<String, int> counts = {};
    if (stores.isEmpty) return counts;

    // نجمع slugs
    final slugs = stores
        .map((s) => (s['slug'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    if (slugs.isEmpty) return counts;

    // نجيب store_id لكل كوبون (مرة واحدة)
    final data = await _sb
        .from('coupons')
        .select('store_id')
        .inFilter('store_id', slugs);

    for (final row in (data as List)) {
      final sid = (row['store_id'] ?? '').toString();
      if (sid.isEmpty) continue;
      counts[sid] = (counts[sid] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                child: Icon(
                  Icons.storefront_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة المتاجر',
                  style: TextStyle(
                    fontSize: ResponsiveLayout.isDesktop(context) ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: _font,
                    color: Colors.grey[900],
                  ),
                ),
              ),
              // ✅ تم حذف زر الإضافة من الهيدر
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'إضافة، تعديل، أو حذف المتاجر بسهولة',
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
          // ✅ البحث + زر الإضافة جنب بعض
          _searchWithAddButton(),

          const SizedBox(height: 18),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _sb.from('stores').stream(primaryKey: ['id']).order(
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
                      'لا توجد متاجر حالياً',
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

              return FutureBuilder<Map<String, int>>(
                future: _fetchCouponsCount(filtered),
                builder: (context, countSnap) {
                  final counts = countSnap.data ?? {};
                  return _buildStoresGrid(filtered, counts);
                },
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((s) {
      final ar = (s['name_ar'] ?? s['name'] ?? '').toString().toLowerCase();
      final en = (s['name_en'] ?? s['name'] ?? '').toString().toLowerCase();
      final slug = (s['slug'] ?? '').toString().toLowerCase();
      return ar.contains(q) || en.contains(q) || slug.contains(q);
    }).toList();
  }

  Widget _searchWithAddButton() {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (!isDesktop) {
      // موبايل/تابلت: البحث ثم زر الإضافة تحتها
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
                'إضافة متجر',
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

    // ديسكتوب: زر الإضافة جنب البحث
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
              'إضافة متجر',
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
                hintText: 'ابحث باسم المتجر أو slug…',
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

  Widget _buildStoresGrid(
      List<Map<String, dynamic>> items, Map<String, int> counts) {
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
        final store = items[i];
        final id = (store['id'] ?? '').toString();
        final slug = (store['slug'] ?? '').toString();
        final name = (store['name_ar'] ?? store['name'] ?? '').toString();
        final desc =
            (store['description_ar'] ?? store['description'] ?? '').toString();
        final image = (store['image'] ?? '').toString();
        final couponsCount = counts[slug] ?? 0;

        return _storeCard(
          id: id,
          store: store,
          name: name,
          desc: desc,
          image: image,
          couponsCount: couponsCount,
          slug: slug,
        );
      },
    );
  }

  Widget _storeCard({
    required String id,
    required Map<String, dynamic> store,
    required String name,
    required String desc,
    required String image,
    required int couponsCount,
    required String slug,
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
                // Logo
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
                        : Icon(Icons.storefront_rounded,
                            color: Constants.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + slug
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
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
                        slug.isEmpty ? 'بدون slug' : slug,
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
                    if (v == 'edit') _openAddOrEditDialog(store: store);
                    if (v == 'delete') _deleteStore(id);
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
                desc.isEmpty ? 'بدون وصف' : desc,
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

            // Footer: count badge + quick buttons
            Row(
              children: [
                _countBadge(couponsCount),
                const Spacer(),
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: () => _openAddOrEditDialog(store: store),
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[500]),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => _deleteStore(id),
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

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: Constants.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.confirmation_number_rounded,
              size: 16, color: Constants.primaryColor),
          const SizedBox(width: 8),
          Text(
            'الكوبونات: $count',
            style: TextStyle(
              color: Constants.primaryColor,
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
