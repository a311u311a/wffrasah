import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wffrhasah/screens/login_signup/widgets/snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants.dart';

import '../../web_widgets/responsive_layout.dart';
import '../../web_widgets/web_navigation_bar.dart';
import '../../web_widgets/web_footer.dart';
import '../../web_widgets/web_i18n.dart';

/// ✅ صفحة إدارة بنرات الكاروسيل على الويب (UI احترافي - نفس المهام)
class WebAdminCarouselScreen extends StatefulWidget {
  final bool isEmbedded;
  const WebAdminCarouselScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminCarouselScreen> createState() => _WebAdminCarouselScreenState();
}

class _WebAdminCarouselScreenState extends State<WebAdminCarouselScreen> {
  static const String _font = 'Tajawal';

  final SupabaseClient _sb = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Search UI
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  int _refreshTick = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =========================
  // Storage helpers
  // =========================

  Future<List<Map<String, dynamic>>> _loadCarousel() async {
    final data = await _sb.from('carousel').select();
    return List<Map<String, dynamic>>.from(data as List);
  }

  void _refreshCarousel() {
    if (mounted) {
      setState(() => _refreshTick++);
    }
  }

  Future<String?> _uploadFile(XFile file) async {
    try {
      final fileName = 'Carousel/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();

      await _sb.storage.from('images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return _sb.storage.from('images').getPublicUrl(fileName);
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

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(webText(context, 'حذف البنر؟', 'Delete banner?'),
            style: const TextStyle(fontFamily: _font)),
        content: Text(
            webText(context, 'هل أنت متأكد من حذف هذا البنر؟',
                'Are you sure you want to delete this banner?'),
            style: const TextStyle(fontFamily: _font)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(webText(context, 'إلغاء', 'Cancel'),
                style: TextStyle(
                  fontFamily: _font,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[600],
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(webText(context, 'حذف', 'Delete'),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _sb.from('carousel').delete().eq('id', id);
        if (mounted) {
          showSnackBar(
              context,
              webText(context, 'تم حذف البنر بنجاح',
                  'Banner deleted successfully'));
          _refreshCarousel();
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

  // =========================
  // Dialog: Add/Edit
  // =========================

  Future<void> _openAddOrEditDialog({Map<String, dynamic>? item}) async {
    final nameArCtrl = TextEditingController(
      text: (item?['name_ar'] ?? item?['name'] ?? '').toString(),
    );
    final nameEnCtrl = TextEditingController(
      text: (item?['name_en'] ?? item?['name'] ?? '').toString(),
    );
    final webCtrl =
        TextEditingController(text: (item?['web'] ?? '').toString());

    XFile? pickedImage;
    Uint8List? pickedBytes;
    bool isSaving = false;

    final existingImageUrl = (item?['image'] ?? '').toString();
    final editingId = (item?['id'] ?? '').toString();

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
                  item == null
                      ? Icons.add_photo_alternate_rounded
                      : Icons.edit_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item == null
                      ? webText(context, 'إضافة بنر جديد', 'Add New Banner')
                      : webText(context, 'تعديل البنر', 'Edit Banner'),
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
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Image picker card
                  InkWell(
                    onTap: () async {
                      final img = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1600,
                        imageQuality: 80,
                      );
                      if (img != null) {
                        final bytes = await img.readAsBytes();
                        setStateDialog(() {
                          pickedImage = img;
                          pickedBytes = bytes;
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
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _buildPreviewImage(
                                pickedBytes: pickedBytes,
                                pickedFile: pickedImage,
                                existingUrl: existingImageUrl,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  webText(
                                      context, 'صورة البنر', 'Banner Image'),
                                  style: TextStyle(
                                    fontFamily: _font,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[900],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  webText(
                                      context,
                                      'اضغط لاختيار صورة (يفضل PNG أو JPG)',
                                      'Tap to choose an image (PNG or JPG preferred)'),
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
                  ),

                  const SizedBox(height: 16),

                  _inputField(
                      nameArCtrl,
                      webText(context, 'الاسم (عربي)', 'Name (Arabic)'),
                      Icons.title_rounded),
                  _inputField(
                      nameEnCtrl, 'Name (English)', Icons.title_outlined),
                  _inputField(
                      webCtrl,
                      webText(
                          context, 'رابط الموقع (Web Link)', 'Website Link'),
                      Icons.link_rounded),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: Text(
                webText(context, 'إلغاء', 'Cancel'),
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
                onPressed: isSaving
                    ? null
                    : () async {
                        // validation
                        if (nameArCtrl.text.trim().isEmpty) {
                          showSnackBar(
                              context,
                              webText(context, 'الرجاء إدخال الاسم العربي',
                                  'Please enter the Arabic name'),
                              isError: true);
                          return;
                        }
                        if (item == null && pickedImage == null) {
                          showSnackBar(
                              context,
                              webText(context, 'الرجاء اختيار صورة البنر',
                                  'Please choose a banner image'),
                              isError: true);
                          return;
                        }

                        setStateDialog(() => isSaving = true);

                        try {
                          String finalUrl = existingImageUrl;

                          if (pickedImage != null) {
                            final url = await _uploadFile(pickedImage!);
                            if (url != null) finalUrl = url;
                          }

                          final payload = {
                            // ✅ استخدام الأعمدة الموجودة في قاعدة البيانات فقط
                            'name': nameArCtrl.text.trim(),
                            'web': webCtrl.text.trim(),
                            'image': finalUrl,
                          };

                          if (item == null) {
                            await _sb.from('carousel').insert(payload);
                            if (mounted) {
                              Navigator.pop(context);
                              showSnackBar(
                                  context,
                                  webText(context, 'تمت الإضافة بنجاح ✅',
                                      'Added successfully'));
                              _refreshCarousel();
                            }
                          } else {
                            await _sb
                                .from('carousel')
                                .update(payload)
                                .eq('id', editingId);
                            if (mounted) {
                              Navigator.pop(context);
                              showSnackBar(
                                  context,
                                  webText(context, 'تم التحديث بنجاح ✅',
                                      'Updated successfully'));
                              _refreshCarousel();
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            showSnackBar(context,
                                webText(context, 'خطأ: $e', 'Error: $e'),
                                isError: true);
                          }
                        } finally {
                          if (mounted) setStateDialog(() => isSaving = false);
                        }
                      },
                icon: isSaving
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
                  item == null
                      ? webText(context, 'إضافة', 'Add')
                      : webText(context, 'حفظ', 'Save'),
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

  Widget _buildPreviewImage({
    required Uint8List? pickedBytes,
    required XFile? pickedFile,
    required String existingUrl,
  }) {
    if (pickedBytes != null) {
      return Image.memory(pickedBytes, fit: BoxFit.cover);
    }
    if (existingUrl.isNotEmpty) {
      return Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image, color: Colors.grey[500]),
      );
    }
    // placeholder
    return Icon(Icons.add_a_photo_rounded, color: Constants.primaryColor);
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) {
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
      ),
    );
  }

  // =========================
  // Build page
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
                child: Icon(Icons.photo_library_rounded,
                    color: Constants.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  webText(context, 'إدارة بنرات الصور', 'Manage Image Banners'),
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
            webText(context, 'إضافة، تعديل، أو حذف بنرات الكاروسيل بسهولة',
                'Add, edit, or delete carousel banners easily'),
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
          FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey(_refreshTick),
            future: _loadCarousel(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Text(
                      webText(context, 'حدث خطأ: ${snapshot.error}',
                          'Error: ${snapshot.error}'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

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
                    child: Column(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          webText(context, 'لا توجد صور في الشريط حالياً',
                              'No images in the carousel right now'),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontFamily: _font,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
        label: Text(
          webText(context, 'إضافة بنر', 'Add Banner'),
          style: const TextStyle(
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
                hintText: webText(context, 'ابحث بالاسم أو الرابط…',
                    'Search by name or link...'),
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
        mainAxisExtent: 165,
      ),
      itemBuilder: (context, i) {
        final item = items[i];

        final imageUrl = (item['image'] ?? '').toString();
        final name = (item['name_ar'] ??
                item['name'] ??
                webText(context, 'بدون اسم', 'No name'))
            .toString();
        final link = (item['web'] ?? '').toString();
        final id = (item['id'] ?? '').toString();

        return _carouselCard(
          id: id,
          item: item,
          name: name,
          imageUrl: imageUrl,
          link: link,
        );
      },
    );
  }

  Widget _carouselCard({
    required String id,
    required Map<String, dynamic> item,
    required String name,
    required String imageUrl,
    required String link,
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
                // Image
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
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image,
                              color: Colors.grey[500],
                            ),
                          )
                        : Icon(Icons.image_not_supported,
                            color: Constants.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + Link
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
                        link.isEmpty
                            ? webText(context, 'بدون رابط', 'No link')
                            : link,
                        style: TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: link.isEmpty
                              ? Colors.grey[600]
                              : Colors.blue[700],
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
                    if (v == 'edit') _openAddOrEditDialog(item: item);
                    if (v == 'delete') _deleteItem(id);
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

            const Spacer(),

            // Footer: Quick buttons
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: webText(context, 'تعديل', 'Edit'),
                  onPressed: () => _openAddOrEditDialog(item: item),
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[500]),
                ),
                IconButton(
                  tooltip: webText(context, 'حذف', 'Delete'),
                  onPressed: () => _deleteItem(id),
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
}
