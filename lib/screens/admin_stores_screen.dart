import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../Login Signup/Widget/snackbar.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  final SupabaseClient _sb = Supabase.instance.client;

  final _storeNameArCtrl = TextEditingController();
  final _storeNameEnCtrl = TextEditingController();
  final _storeDescArCtrl = TextEditingController();
  final _storeDescEnCtrl = TextEditingController();
  final _storeFormKey = GlobalKey<FormState>();

  String? _editingId; // primary key (UUID text) في جدول stores
  String? _editingImageUrl;
  XFile? _pickedStoreImageFile;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _storeNameArCtrl.dispose();
    _storeNameEnCtrl.dispose();
    _storeDescArCtrl.dispose();
    _storeDescEnCtrl.dispose();
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
  }

  // ✅ توليد slug من الاسم (بدون أي تغيير UI)
  String _toSlug(String input) {
    final s = input.trim().toLowerCase();
    // نستبدل المسافات بشرطة ونشيل الرموز الغريبة
    final slug = s
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\-_]'), '');
    // منع slug فارغ
    return slug.isEmpty
        ? 'store-${DateTime.now().millisecondsSinceEpoch}'
        : slug;
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

  Future<void> _openAddOrEditSheet({Map<String, dynamic>? store}) async {
    _clearForm();

    if (store != null) {
      _editingId = (store['id'] ?? '').toString(); // ✅ UUID text
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
                  _editingId == null ? 'إضافة متجر جديد' : 'تعديل المتجر',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _storeFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final XFile? xfile = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1200,
                                  imageQuality: 85,
                                );
                                if (xfile != null) {
                                  setStateSheet(
                                      () => _pickedStoreImageFile = xfile);
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
                          const SizedBox(height: 25),
                          _inputField(_storeNameArCtrl, 'اسم المتجر (بالعربي)',
                              Icons.storefront_rounded),
                          _inputField(_storeNameEnCtrl, 'Store Name (English)',
                              Icons.storefront_outlined),
                          _inputField(_storeDescArCtrl, 'وصف المتجر (بالعربي)',
                              Icons.description,
                              maxLines: 2),
                          _inputField(
                            _storeDescEnCtrl,
                            'Store Description (English)',
                            Icons.description_outlined,
                            maxLines: 2,
                          ),
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
                                : () => _saveStore(setStateSheet),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    _editingId == null
                                        ? 'إضافة المتجر'
                                        : 'حفظ التعديلات',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
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
    );
  }

  DecorationImage? _getImageProvider() {
    if (_pickedStoreImageFile != null) {
      if (kIsWeb) {
        return DecorationImage(
          image: NetworkImage(_pickedStoreImageFile!.path),
          fit: BoxFit.cover,
        );
      } else {
        return DecorationImage(
          image: FileImage(File(_pickedStoreImageFile!.path)),
          fit: BoxFit.cover,
        );
      }
    } else if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_editingImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget? _getImageChild() {
    if (_pickedStoreImageFile != null) return null;
    if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) return null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, color: Constants.primaryColor),
        const SizedBox(height: 8),
        const Text('شعار المتجر',
            style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {int? maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Constants.primaryColor),
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Future<void> _saveStore(StateSetter setStateSheet) async {
    if (!(_storeFormKey.currentState?.validate() ?? false)) return;

    setStateSheet(() => _isSaving = true);

    try {
      String? finalImageUrl = _editingImageUrl;

      if (_pickedStoreImageFile != null) {
        final path = 'stores/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _uploadFile(_pickedStoreImageFile!, path);
        if (url != null) finalImageUrl = url;
      }

      // ✅ slug هو اللي بيرتبط مع coupons.store_id (text)
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

        // Fallbacks
        'name': _storeNameArCtrl.text.trim(),
        'description': _storeDescArCtrl.text.trim(),

        // ✅ مهم
        'slug': slug,

        'image': finalImageUrl ?? '',
      };

      if (_editingId == null) {
        // ✅ لا ترسل created_at (خليه default إن وجد)
        await _sb.from('stores').insert(payload);
      } else {
        await _sb.from('stores').update(payload).eq('id', _editingId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      showSnackBar(context,
          _editingId == null ? 'تمت الإضافة بنجاح' : 'تم التحديث بنجاح');
    } catch (e) {
      if (mounted) showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setStateSheet(() => _isSaving = false);
    }
  }

  Future<void> _deleteStore(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المتجر؟'),
        content: const Text(
            'سيتم حذف المتجر وكل الكوبونات المرتبطة به. هل أنت متأكد؟'),
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
        await _sb.from('stores').delete().eq('id', id); // ✅ حذف بالـ UUID
        if (mounted) showSnackBar(context, 'تم حذف المتجر');
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
  }

  Widget _storeCard(Map<String, dynamic> data) {
    final id = (data['id'] ?? '').toString(); // ✅ UUID
    final slug = (data['slug'] ?? '').toString(); // ✅ الربط مع coupons
    final name = data['name_ar'] ?? data['name'] ?? '';
    final image = data['image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
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
              child: (image != null && image.toString().isNotEmpty)
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : Icon(Icons.storefront_rounded,
                      color: Constants.primaryColor),
            ),
          ),
          title: Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          // ✅ اعرضي slug للمستخدم بدل UUID (بدون تغيير تصميم)
          subtitle: Text('ID: ${slug.isNotEmpty ? slug : id}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon:
                    Icon(Icons.edit_note_rounded, color: Colors.blueGrey[400]),
                onPressed: () => _openAddOrEditSheet(store: data),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.redAccent),
                onPressed: () => _deleteStore(id), // ✅ حذف بالـ UUID
              ),
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
                  Text(
                    'إحصائيات سريعة:',
                    style: TextStyle(
                      color: Constants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    // ✅ العد صار بالـ slug لأنه هو اللي داخل coupons.store_id
                    future:
                        _sb.from('coupons').select('id').eq('store_id', slug),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Text('• عدد الكوبونات المرتبطة: $count');
                    },
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
        title: Text('إدارة المتاجر',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Constants.primaryColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Constants.primaryColor),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Constants.primaryColor,
                  Constants.primaryColor.withOpacity(0.8),
                ]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
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
                        Icon(Icons.storefront_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text('إضافة متجر جديد',
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
              // ✅ primaryKey تبقى id (UUID) لأنها فعليًا مفتاح الجدول
              stream: _sb.from('stores').stream(
                  primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('لا توجد متاجر حالياً',
                        style: TextStyle(color: Colors.grey[400])),
                  );
                }

                final items = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _storeCard(items[index]);
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
