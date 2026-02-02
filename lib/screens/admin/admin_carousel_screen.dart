import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants.dart';
import '../login_signup/widgets/snackbar.dart';

class AdminCarouselScreen extends StatefulWidget {
  final bool isEmbedded;
  const AdminCarouselScreen({super.key, this.isEmbedded = false});

  @override
  State<AdminCarouselScreen> createState() => _AdminCarouselScreenState();
}

class _AdminCarouselScreenState extends State<AdminCarouselScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<String?> _uploadFile(XFile file) async {
    try {
      final fileName = 'Carousel/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();

      await _supabase.storage.from('images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = _supabase.storage.from('images').getPublicUrl(fileName);
      return url;
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ في رفع الصورة: $e', isError: true);
      }
      return null;
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      await _supabase.from('carousel').delete().eq('id', id);
      if (mounted) {
        showSnackBar(context, 'تم حذف البنر بنجاح');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
  }

  void _openAddSheet() {
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final webCtrl = TextEditingController();
    XFile? pickedImage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Text('إضافة بنر جديد',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor)),
                  const SizedBox(height: 15),
                  const Divider(indent: 20, endIndent: 20),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final img = await _picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 70);
                      if (img != null) setStateSheet(() => pickedImage = img);
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)),
                      child: pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(pickedImage!.path,
                                      fit: BoxFit.cover)
                                  : Image.file(File(pickedImage!.path),
                                      fit: BoxFit.cover))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    color: Constants.primaryColor),
                                const SizedBox(height: 10),
                                const Text('اختر صورة البنر',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(nameArCtrl, 'الاسم (بالعربي)', Icons.title),
                  const SizedBox(height: 15),
                  _buildTextField(
                      nameEnCtrl, 'Name (English)', Icons.title_outlined),
                  const SizedBox(height: 15),
                  _buildTextField(
                      webCtrl, 'رابط الموقع (Web Link)', Icons.link),
                  const SizedBox(height: 20),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameArCtrl.text.trim().isEmpty ||
                                  pickedImage == null) {
                                showSnackBar(
                                    ctx, 'الرجاء إدخال الاسم العربي والصورة',
                                    isError: true);
                                return;
                              }
                              setStateSheet(() => isSaving = true);
                              final url = await _uploadFile(pickedImage!);
                              if (url != null) {
                                try {
                                  await _supabase.from('carousel').insert({
                                    'name': nameArCtrl.text.trim(),
                                    'image': url,
                                    'web': webCtrl.text.trim(),
                                  });
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  setStateSheet(() => isSaving = false);
                                  if (mounted) {
                                    showSnackBar(context, 'خطأ في الحفظ: $e',
                                        isError: true);
                                  }
                                }
                              } else {
                                setStateSheet(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('حفظ ونشر',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
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

  void _openEditSheet(Map<String, dynamic> data) {
    final nameArCtrl =
        TextEditingController(text: data['name_ar'] ?? data['name']);
    final nameEnCtrl =
        TextEditingController(text: data['name_en'] ?? data['name']);
    final webCtrl = TextEditingController(text: data['web']);
    XFile? pickedImage;
    bool isSaving = false;
    final String existingImageUrl = data['image'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Text('تعديل البنر',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Constants.primaryColor)),
                  const SizedBox(height: 15),
                  const Divider(indent: 20, endIndent: 20),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final img = await _picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 70);
                      if (img != null) setStateSheet(() => pickedImage = img);
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!)),
                      child: pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(pickedImage!.path,
                                      fit: BoxFit.cover)
                                  : Image.file(File(pickedImage!.path),
                                      fit: BoxFit.cover))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(existingImageUrl,
                                  fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(nameArCtrl, 'الاسم (بالعربي)', Icons.title),
                  const SizedBox(height: 15),
                  _buildTextField(
                      nameEnCtrl, 'Name (English)', Icons.title_outlined),
                  const SizedBox(height: 15),
                  _buildTextField(webCtrl, 'رابط الموقع (Web Link)',
                      Icons.language_outlined),
                  const SizedBox(height: 20),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setStateSheet(() => isSaving = true);
                              String finalUrl = existingImageUrl;
                              if (pickedImage != null) {
                                final url = await _uploadFile(pickedImage!);
                                if (url != null) finalUrl = url;
                              }
                              try {
                                await _supabase.from('carousel').update({
                                  'name': nameArCtrl.text.trim(),
                                  'web': webCtrl.text.trim(),
                                  'image': finalUrl,
                                }).eq('id', data['id']);
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                setStateSheet(() => isSaving = false);
                                if (mounted) {
                                  showSnackBar(context, 'خطأ في التحديث: $e',
                                      isError: true);
                                }
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('تحديث التعديلات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
        fontWeight: FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          fontWeight: FontWeight.normal,
        ),
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Constants.primaryColor)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: _buildBody(),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Constants.primaryColor),
        title: Text('إدارة بنر الصور',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Constants.primaryColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (widget.isEmbedded) const SizedBox(height: 20),
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
                onTap: _openAddSheet,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text('إضافة بنر جديد',
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
          // ✅ استخدام Supabase Stream
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('carousel').stream(primaryKey: ['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 80, color: Colors.grey[200]),
                      const SizedBox(height: 10),
                      const Text('لا توجد صور في الشريط حالياً',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  debugPrint('Carousel Item $index: $item'); // Debugging

                  final imageUrl = item['image']?.toString();
                  final name = item['name_ar'] ?? item['name'] ?? 'بدون اسم';
                  final link = item['web'] ?? 'لا يوجد رابط';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image,
                                          size: 50, color: Colors.grey),
                                    );
                                  },
                                )
                              : Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 50, color: Colors.grey),
                                ),
                        ),
                        ListTile(
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(link,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.blue)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_note_rounded,
                                      color: Colors.blue),
                                  onPressed: () => _openEditSheet(item)),
                              IconButton(
                                  icon: const Icon(Icons.delete_sweep_outlined,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('حذف البنّر؟'),
                                        content: const Text(
                                            'هل أنت متأكد من حذف هذا البنر من شريط الصور؟'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('إلغاء')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('حذف',
                                                  style: TextStyle(
                                                      color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      _deleteItem(item['id'].toString());
                                    }
                                  }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
