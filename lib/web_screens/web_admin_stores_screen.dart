import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// صفحة إدارة المتاجر على الويب
class WebAdminStoresScreen extends StatefulWidget {
  const WebAdminStoresScreen({super.key});

  @override
  State<WebAdminStoresScreen> createState() => _WebAdminStoresScreenState();
}

class _WebAdminStoresScreenState extends State<WebAdminStoresScreen> {
  final SupabaseClient _sb = Supabase.instance.client;
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _editingId == null ? 'إضافة متجر جديد' : 'تعديل المتجر',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Form(
                key: _storeFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // صورة المتجر
                    Center(
                      child: GestureDetector(
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
                onPressed: _isSaving ? null : () => _saveStore(setStateDialog),
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
                        _editingId == null ? 'إضافة المتجر' : 'حفظ التعديلات',
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

  DecorationImage? _getImageProvider() {
    if (_pickedImageBytes != null) {
      return DecorationImage(
        image: MemoryImage(_pickedImageBytes!),
        fit: BoxFit.contain,
      );
    } else if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_editingImageUrl!),
        fit: BoxFit.contain,
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
          labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.normal),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(
            fontSize: 14, color: Colors.black54, fontWeight: FontWeight.normal),
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
      showSnackBar(context,
          _editingId == null ? 'تمت الإضافة بنجاح' : 'تم التحديث بنجاح');
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
        await _sb.from('stores').delete().eq('id', id);
        if (mounted) showSnackBar(context, 'تم حذف المتجر');
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
                Icons.storefront_rounded,
                color: Constants.primaryColor,
                size: ResponsiveLayout.isDesktop(context) ? 48 : 36,
              ),
              const SizedBox(width: 16),
              Text(
                'إدارة المتاجر',
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
            'إضافة، تعديل، أو حذف المتاجر',
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
          // زر إضافة متجر جديد
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
                'إضافة متجر جديد',
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

          // جدول المتاجر
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _sb.from('stores').stream(
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
                      'لا توجد متاجر حالياً',
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
              return _buildStoresTable(items);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStoresTable(List<Map<String, dynamic>> items) {
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
                'الاسم',
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
                'عدد الكوبونات',
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
          rows: items.map((store) {
            final id = (store['id'] ?? '').toString();
            final slug = (store['slug'] ?? '').toString();
            final name = store['name_ar'] ?? store['name'] ?? '';
            final description =
                store['description_ar'] ?? store['description'] ?? '';
            final image = store['image'];

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
                          : Icon(Icons.storefront_rounded,
                              color: Constants.primaryColor),
                    ),
                  ),
                ),
                // الاسم
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Tajawal',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                // عدد الكوبونات
                DataCell(
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future:
                        _sb.from('coupons').select('id').eq('store_id', slug),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Constants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: Constants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      );
                    },
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
                        onPressed: () => _openAddOrEditDialog(store: store),
                        tooltip: 'تعديل',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined,
                            color: Colors.redAccent),
                        onPressed: () => _deleteStore(id),
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
