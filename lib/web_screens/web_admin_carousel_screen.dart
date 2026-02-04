import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants.dart';
import '../../screens/login_signup/widgets/snackbar.dart';
import '../../web_widgets/responsive_layout.dart';
import '../../web_widgets/web_navigation_bar.dart';
import '../../web_widgets/web_footer.dart';

/// ✅ صفحة إدارة بنرات الكاروسيل على الويب (UI احترافي - كاملة الوظائف)
class WebAdminCarouselScreen extends StatefulWidget {
  final bool isEmbedded;
  const WebAdminCarouselScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminCarouselScreen> createState() => _WebAdminCarouselScreenState();
}

class _WebAdminCarouselScreenState extends State<WebAdminCarouselScreen> {
  static const String _font = 'Tajawal';
  final SupabaseClient _sb = Supabase.instance.client;

  // Form
  final _nameCtrl = TextEditingController();
  final _linkCtrl = TextEditingController(); // For 'web' column
  final _formKey = GlobalKey<FormState>();

  String? _editingId;
  String? _editingImageUrl;
  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  bool _isSaving = false;

  // Picker
  final ImagePicker _picker = ImagePicker();

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _linkCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _editingId = null;
    _editingImageUrl = null;
    _nameCtrl.clear();
    _linkCtrl.clear();
    _pickedImageFile = null;
    _pickedImageBytes = null;
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

  Future<void> _openAddOrEditDialog({Map<String, dynamic>? item}) async {
    _clearForm();

    if (item != null) {
      _editingId = (item['id'] ?? '').toString();
      _editingImageUrl = (item['image'] ?? '').toString();
      _nameCtrl.text = (item['name_ar'] ?? item['name'] ?? '').toString();
      _linkCtrl.text = (item['web'] ?? '').toString();
    }

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
                      ? Icons.add_photo_alternate_rounded
                      : Icons.edit_note_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _editingId == null ? 'إضافة بنر جديد' : 'تعديل البنر',
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
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),

                    // صورة البنر
                    _imagePickerCard(setStateDialog),

                    const SizedBox(height: 16),

                    // الاسم
                    _inputField(
                      _nameCtrl,
                      'عنوان البنر (اختياري)',
                      Icons.title_rounded,
                      isRequired: false,
                    ),

                    // الرابط
                    _inputField(
                      _linkCtrl,
                      'رابط عند الضغط (اختياري)',
                      Icons.link_rounded,
                      isRequired: false,
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
                onPressed: _isSaving ? null : () => _saveItem(setStateDialog),
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
        fit: BoxFit.cover,
      );
    } else if (_editingImageUrl != null && _editingImageUrl!.isNotEmpty) {
      imageProvider = DecorationImage(
        image: NetworkImage(_editingImageUrl!),
        fit: BoxFit.cover,
      );
    }

    return InkWell(
      onTap: () async {
        final XFile? xfile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1500, // البنرات تحتاج جودة أعلى
          imageQuality: 90,
        );
        if (xfile != null) {
          final bytes = await xfile.readAsBytes();
          setStateDialog(() {
            _pickedImageFile = xfile;
            _pickedImageBytes = bytes;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 180, // مساحة أكبر للبنر
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Stack(
          children: [
            if (imageProvider != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(image: imageProvider),
                  ),
                ),
              ),
            if (imageProvider == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 40, color: Constants.primaryColor),
                    const SizedBox(height: 10),
                    Text(
                      'اضغط لاختيار صورة البنر',
                      style: TextStyle(
                        fontFamily: _font,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            // تلميح صغير
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: const Text(
                  'يفضل صور بعرضية (Landscape)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
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
        validator: isRequired
            ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }

  Future<void> _saveItem(StateSetter setStateDialog) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // validation للصورة
    if (_pickedImageFile == null && _editingId == null) {
      // حالة إضافة جديدة ولا توجد صورة
      // لكن قد يكون المستخدم يريد إضافة بنر نصي؟ عادة البنر يحتاج صورة
      // سنطلب الصورة كشيء أساسي
      // يمكن إظهار رسالة
      return;
    }

    setStateDialog(() => _isSaving = true);
    if (mounted) setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _editingImageUrl;

      if (_pickedImageFile != null) {
        final path = 'carousel/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final url = await _uploadFile(_pickedImageFile!, path);
        if (url != null) finalImageUrl = url;
      }

      // إذا لم ينجح الرفع ولا توجد صورة قديمة، نتوقف
      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        // handle error
        throw Exception('يجب اختيار صورة');
      }

      final payload = {
        'name_ar': _nameCtrl.text.trim(),
        'web': _linkCtrl.text.trim(),
        'image': finalImageUrl,
      };

      if (_editingId == null) {
        await _sb.from('carousel').insert(payload);
      } else {
        await _sb.from('carousel').update(payload).eq('id', _editingId!);
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

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف البنر؟', style: TextStyle(fontFamily: _font)),
        content: const Text(
          'سيتم حذف هذا البنر نهائياً. هل أنت متأكد؟',
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
        await _sb.from('carousel').delete().eq('id', id);
        if (mounted) showSnackBar(context, 'تم الحذف');
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
  }

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
                child: Icon(Icons.photo_library_rounded,
                    color: Constants.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'إدارة بنرات الصور',
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
            'إضافة، تعديل، أو حذف بنرات الكاروسيل بسهولة',
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
            stream: _sb.from('carousel').stream(primaryKey: ['id']).order(
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
                      'لا توجد صور في الشريط حالياً',
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
              return _buildGrid(filtered);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

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
          'إضافة بنر',
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
                hintText: 'ابحث بالاسم أو الرابط…',
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

    return items.where((r) {
      final name = (r['name_ar'] ?? r['name'] ?? '').toString().toLowerCase();
      final web = (r['web'] ?? '').toString().toLowerCase();
      return name.contains(q) || web.contains(q);
    }).toList();
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
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
        mainAxisExtent: 330,
      ),
      itemBuilder: (context, i) {
        final item = items[i];

        final imageUrl = (item['image'] ?? '').toString();
        final name = (item['name_ar'] ?? item['name'] ?? 'بدون اسم').toString();
        final link = (item['web'] ?? '').toString();
        final id = (item['id'] ?? '').toString();

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
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 190,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 44, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 190,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 44, color: Colors.grey),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 8),
                    Text(
                      link.isEmpty ? 'لا يوجد رابط' : link,
                      style: TextStyle(
                        fontFamily: _font,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color:
                            link.isEmpty ? Colors.grey[500] : Colors.blue[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _openAddOrEditDialog(item: item),
                            icon: Icon(Icons.edit_note_rounded,
                                color: Colors.blueGrey[500]),
                            label: Text(
                              'تعديل',
                              style: TextStyle(
                                fontFamily: _font,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => _deleteItem(id),
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
