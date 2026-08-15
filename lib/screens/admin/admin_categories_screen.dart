import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants.dart';
import '../login_signup/widgets/snackbar.dart';

class AdminCategoriesScreen extends StatefulWidget {
  final bool isEmbedded;

  const AdminCategoriesScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _sb = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  String? _editingId;
  String? _editingImageUrl;
  XFile? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final rows = await _sb
        .from('categories')
        .select('*')
        .order('name_ar', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _categoriesFuture = _fetchCategories();
    });
  }

  void _clearForm() {
    _editingId = null;
    _editingImageUrl = null;
    _pickedImage = null;
    _nameArCtrl.clear();
    _nameEnCtrl.clear();
  }

  void _fillForm(Map<String, dynamic> category) {
    _editingId = (category['id'] ?? '').toString();
    _editingImageUrl = (category['image'] ?? '').toString();
    _pickedImage = null;
    _nameArCtrl.text =
        (category['name_ar'] ?? category['name'] ?? '').toString();
    _nameEnCtrl.text = (category['name_en'] ?? '').toString();
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final path = 'categories/${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  Future<void> _openAddOrEditSheet({Map<String, dynamic>? category}) async {
    _clearForm();
    if (category != null) _fillForm(category);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, bottomInset + 24),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 520,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
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
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Constants.primaryColor
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  color: Constants.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _editingId == null
                                      ? 'إضافة فئة جديدة'
                                      : 'تعديل الفئة',
                                  style: const TextStyle(
                                    fontSize: 17,
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
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _imagePickerBox(setStateSheet),
                                  const SizedBox(height: 14),
                                  _inputField(
                                    _nameArCtrl,
                                    'اسم الفئة (عربي)',
                                    Icons.category_rounded,
                                    requiredField: true,
                                  ),
                                  _inputField(
                                    _nameEnCtrl,
                                    'Category Name (English)',
                                    Icons.category_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveCategory(setStateSheet),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    backgroundColor: Constants.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                  icon: _isSaving
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
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveCategory(StateSetter setStateSheet) async {
    if (!_formKey.currentState!.validate()) return;

    setStateSheet(() => _isSaving = true);
    try {
      var imageUrl = _editingImageUrl ?? '';
      if (_pickedImage != null) {
        final uploaded = await _uploadImage(_pickedImage!);
        if (uploaded != null && uploaded.isNotEmpty) imageUrl = uploaded;
      }

      final nameAr = _nameArCtrl.text.trim();
      final nameEn = _nameEnCtrl.text.trim();
      final payload = {
        'name': nameAr,
        'name_ar': nameAr,
        'name_en': nameEn.isEmpty ? nameAr : nameEn,
        'image': imageUrl,
      };

      if (_editingId == null) {
        await _sb.from('categories').insert({
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          ...payload,
        });
      } else {
        await _sb.from('categories').update(payload).eq('id', _editingId!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _refresh();
      showSnackBar(context, 'تم حفظ الفئة');
    } catch (e) {
      if (mounted) showSnackBar(context, 'تعذر حفظ الفئة: $e', isError: true);
    } finally {
      if (mounted) setStateSheet(() => _isSaving = false);
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final id = (category['id'] ?? '').toString();
    final name =
        (category['name_ar'] ?? category['name'] ?? 'الفئة').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل تريد حذف "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || id.isEmpty) return;

    try {
      await _sb.from('categories').delete().eq('id', id);
      if (!mounted) return;
      _refresh();
      showSnackBar(context, 'تم حذف الفئة');
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          'تعذر حذف الفئة. قد تكون مرتبطة بمتاجر أو عروض: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('إدارة الفئات'),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Constants.primaryColor,
              elevation: 0,
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _toolbar(),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'خطأ في تحميل الفئات: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final categories = _applySearch(snapshot.data ?? []);
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          color: Colors.grey[400],
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'لا توجد فئات مطابقة',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 180,
                          child: _addCategoryButton(compact: true),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns(context),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 168,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryCard(
                      category: category,
                      onEdit: () => _openAddOrEditSheet(category: category),
                      onDelete: () => _deleteCategory(category),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    return widget.isEmbedded ? content.body! : content;
  }

  Widget _addCategoryButton({bool compact = false}) {
    return SizedBox(
      width: compact ? double.infinity : null,
      height: 46,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () => _openAddOrEditSheet(),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'إضافة فئة',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final search = _searchBar();
        final button = _addCategoryButton(compact: !isWide);

        if (!isWide) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              button,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الفئة',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (_searchCtrl.text.trim().isNotEmpty)
            IconButton(
              tooltip: 'مسح',
              onPressed: () {
                _searchCtrl.clear();
                setState(() {});
              },
              icon: Icon(Icons.close_rounded, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> items) {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((category) {
      final nameAr = (category['name_ar'] ?? category['name'] ?? '')
          .toString()
          .toLowerCase();
      final nameEn = (category['name_en'] ?? category['name'] ?? '')
          .toString()
          .toLowerCase();
      return nameAr.contains(query) || nameEn.contains(query);
    }).toList();
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1300) return 4;
    if (width >= 950) return 3;
    if (width >= 620) return 2;
    return 1;
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
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
          if (image != null) setStateSheet(() => _pickedImage = image);
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
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = (category['name_ar'] ?? category['name'] ?? '').toString();
    final nameEn = (category['name_en'] ?? '').toString();
    final image = (category['image'] ?? '').toString();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Constants.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.category_rounded,
                              color: Constants.primaryColor,
                            ),
                          )
                        : Icon(
                            Icons.category_rounded,
                            color: Constants.primaryColor,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'فئة بدون اسم' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      if (nameEn.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Constants.primaryColor.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            nameEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Constants.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Divider(height: 18, color: Colors.grey.shade200),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'حذف',
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    onPressed: onDelete,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'تعديل',
                    icon: Icons.edit_rounded,
                    color: Constants.primaryColor,
                    filled: true,
                    onPressed: onEdit,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled ? color : color.withValues(alpha: 0.08);
    final foregroundColor = filled ? Colors.white : color;

    return SizedBox(
      height: 38,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
