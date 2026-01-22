import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/offers.dart';
import '../constants.dart';
import '../Login Signup/Widget/snackbar.dart';

class AddOfferScreen extends StatefulWidget {
  final Offer? offer;
  const AddOfferScreen({super.key, this.offer});

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  final _supabase = Supabase.instance.client;

  bool get isAdmin => true;

  Future<void> _deleteOffer(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('حذف العرض',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذا العرض نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('offers').delete().eq('id', id);
        if (mounted) showSnackBar(context, 'تم حذف العرض بنجاح');
      } catch (e) {
        if (mounted) showSnackBar(context, 'خطأ في الحذف: $e', isError: true);
      }
    }
  }

  void _showOfferForm(BuildContext context, {Offer? offer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OfferFormSheet(offer: offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(
          'إدارة العروض',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Constants.primaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Constants.primaryColor),
        elevation: 0,
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
                  onTap: () => _showOfferForm(context),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'إضافة عرض جديد',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✅ عرض كل العروض مباشرة
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('offers').stream(
                  primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, offerSnapshot) {
                if (!offerSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final offers = offerSnapshot.data!;
                if (offers.isEmpty) {
                  return Center(
                    child: Text('لا توجد عروض حالياً',
                        style: TextStyle(color: Colors.grey[400])),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final data = offers[index];

                    final tags = (data['tags'] is List)
                        ? List<String>.from(data['tags'])
                        : <String>[];

                    final offerModel = Offer(
                      id: data['id'].toString(),
                      name: (data['name_ar'] ?? data['name'] ?? '').toString(),
                      nameAr: (data['name_ar'] ?? '').toString(),
                      nameEn: (data['name_en'] ?? '').toString(),
                      description:
                          (data['description_ar'] ?? data['description'] ?? '')
                              .toString(),
                      descriptionAr: (data['description_ar'] ?? '').toString(),
                      descriptionEn: (data['description_en'] ?? '').toString(),
                      image: (data['image'] ?? '').toString(),
                      web: (data['web'] ?? '').toString(),
                      tags: tags,
                      categoryId:
                          (data['category_id'] ?? data['categoryId'] ?? '')
                              .toString(),
                    );

                    return _offerCard(offerModel, data['id'].toString());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _offerCard(Offer offer, String docId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 16),
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
              child: offer.image.isNotEmpty
                  ? Image.network(
                      offer.image,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    )
                  : Icon(Icons.local_offer_outlined,
                      color: Constants.primaryColor),
            ),
          ),
          title: Text(
            offer.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: offer.tags.isNotEmpty
              ? Text(
                  '#${offer.tags.join(" #")}',
                  style: TextStyle(fontSize: 11, color: Constants.primaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_note_rounded,
                          color: Colors.blueGrey[400]),
                      onPressed: () => _showOfferForm(context, offer: offer),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: Colors.redAccent),
                      onPressed: () => _deleteOffer(docId),
                    ),
                    const Icon(Icons.expand_circle_down_outlined,
                        size: 20, color: Colors.grey),
                  ],
                )
              : const Icon(Icons.expand_circle_down_outlined,
                  size: 20, color: Colors.grey),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل العرض:',
                    style: TextStyle(
                      color: Constants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('• الوصف: ${offer.description}',
                      style: TextStyle(color: Colors.grey[700], height: 1.4)),
                  const SizedBox(height: 5),
                  if (offer.web.isNotEmpty)
                    Text('• الرابط: ${offer.web}',
                        style: TextStyle(color: Colors.blue[700])),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OfferFormSheet extends StatefulWidget {
  final Offer? offer;
  const _OfferFormSheet({this.offer});

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameArCtrl,
      _nameEnCtrl,
      _descArCtrl,
      _descEnCtrl,
      _codeCtrl,
      _webCtrl;

  String? _selectedCategoryId, _selectedCategoryName;

  // ✅ ربط العرض بالمتجر (offers.store_id = stores.slug)
  String? _selectedStoreId;
  String? _selectedStoreName;
  String? _selectedStoreImage;

  bool _isSaving = false;
  XFile? _pickedOfferImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameArCtrl = TextEditingController(
        text: widget.offer?.nameAr ?? widget.offer?.name ?? '');
    _nameEnCtrl = TextEditingController(
        text: widget.offer?.nameEn ?? widget.offer?.name ?? '');
    _descArCtrl = TextEditingController(
        text: widget.offer?.descriptionAr ?? widget.offer?.description ?? '');
    _descEnCtrl = TextEditingController(
        text: widget.offer?.descriptionEn ?? widget.offer?.description ?? '');
    _codeCtrl = TextEditingController(
      text: (widget.offer?.tags.isNotEmpty ?? false)
          ? widget.offer!.tags.first
          : '',
    );
    _webCtrl = TextEditingController(text: widget.offer?.web ?? '');

    _selectedCategoryId = widget.offer?.categoryId;

    if (widget.offer != null) {
      _bootstrapOfferStoreId(widget.offer!.id);
    }

    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      _fetchCategoryName(_selectedCategoryId!);
    }
  }

  Future<void> _bootstrapOfferStoreId(String offerId) async {
    try {
      final row = await _supabase
          .from('offers')
          .select('store_id')
          .eq('id', offerId)
          .maybeSingle();
      final sid = (row?['store_id'] ?? '').toString().trim();
      if (!mounted) return;
      if (sid.isNotEmpty) {
        setState(() => _selectedStoreId = sid);
        await _loadStoreBySlug(sid);
      }
    } catch (_) {}
  }

  Future<void> _loadStoreBySlug(String slug) async {
    try {
      final s = await _supabase
          .from('stores')
          .select('slug,name_ar,name_en,name,image')
          .eq('slug', slug)
          .maybeSingle();

      if (!mounted) return;
      if (s != null) {
        setState(() {
          _selectedStoreName = (s['name_ar'] ?? s['name'] ?? '').toString();
          _selectedStoreImage = (s['image'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCategoryName(String catId) async {
    try {
      final data = await _supabase
          .from('categories')
          .select('name')
          .eq('id', catId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => _selectedCategoryName = data['name']);
      }
    } catch (_) {}
  }

  void _showStorePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('stores')
              .stream(primaryKey: ['id']).order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 15),
                const Text('اختر المتجر',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      final name = (data['name_ar'] ?? data['name'] ?? 'متجر')
                          .toString();
                      final slug = (data['slug'] ?? '').toString().trim();
                      final img = (data['image'] ?? '').toString();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (img.isNotEmpty) ? NetworkImage(img) : null,
                          child: img.isEmpty ? const Icon(Icons.store) : null,
                        ),
                        title: Text(name),
                        subtitle: slug.isNotEmpty
                            ? Text('slug: $slug',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]))
                            : null,
                        onTap: () {
                          if (slug.isEmpty) {
                            showSnackBar(
                              context,
                              'هذا المتجر لا يحتوي slug. عدّلي المتجر وخليه يولد slug.',
                              isError: true,
                            );
                            return;
                          }
                          setState(() {
                            _selectedStoreId = slug;
                            _selectedStoreName = name;
                            _selectedStoreImage = img;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase.from('categories').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 15),
                const Text('اختر الفئة',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index];
                      return ListTile(
                        leading: (data['image'] != null &&
                                data['image'].toString().isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['image'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.category_outlined),
                        title: Text((data['name'] ?? '').toString()),
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = data['id'].toString();
                            _selectedCategoryName =
                                (data['name'] ?? '').toString();
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isRequired = true,
    int? maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: isRequired
          ? (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  widget.offer == null
                      ? 'إضافة عرض جديد'
                      : 'تعديل بيانات العرض',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 25),

                // صورة العرض
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      imageQuality: 80,
                    );
                    if (image != null)
                      setState(() => _pickedOfferImage = image);
                  },
                  child: Center(
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                        image: (_pickedOfferImage != null)
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_pickedOfferImage!.path)
                                    : FileImage(File(_pickedOfferImage!.path))
                                        as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : (_selectedStoreImage != null &&
                                    _selectedStoreImage!.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(_selectedStoreImage!),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.3),
                                      BlendMode.darken,
                                    ),
                                  )
                                : null,
                      ),
                      child: (_pickedOfferImage == null)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: (_selectedStoreImage != null &&
                                          _selectedStoreImage!.isNotEmpty)
                                      ? Colors.white
                                      : Constants.primaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  (_selectedStoreImage != null &&
                                          _selectedStoreImage!.isNotEmpty)
                                      ? 'تغيير صورة العرض (اختياري)'
                                      : 'إضافة صورة للعرض',
                                  style: TextStyle(
                                    color: (_selectedStoreImage != null &&
                                            _selectedStoreImage!.isNotEmpty)
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // ✅ اختيار المتجر (يحفظ slug)
                InkWell(
                  onTap: () => _showStorePicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Constants.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (_selectedStoreId == null ||
                                    _selectedStoreId!.isEmpty)
                                ? 'اختر المتجر'
                                : (_selectedStoreName ?? _selectedStoreId!),
                            style: TextStyle(
                              color: (_selectedStoreId == null ||
                                      _selectedStoreId!.isEmpty)
                                  ? Colors.grey[600]
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                _buildTextField(
                    _nameArCtrl, 'اسم العرض (بالعربي)', Icons.title),
                const SizedBox(height: 15),
                _buildTextField(
                    _nameEnCtrl, 'Offer Name (English)', Icons.title_outlined),
                const SizedBox(height: 15),
                _buildTextField(
                  _descArCtrl,
                  'وصف العرض (بالعربي)',
                  Icons.description,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  _descEnCtrl,
                  'Offer Description (English)',
                  Icons.description_outlined,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 15),
                _buildTextField(_codeCtrl, 'كود الخصم (اختياري)', Icons.code,
                    isRequired: false),
                const SizedBox(height: 15),
                _buildTextField(
                    _webCtrl, 'رابط المتجر', Icons.language_outlined),
                const SizedBox(height: 15),

                // اختيار الفئة
                InkWell(
                  onTap: () => _showCategoryPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category_outlined,
                            color: Constants.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategoryName ?? 'فئة العرض',
                            style: TextStyle(
                              color: _selectedCategoryName == null
                                  ? Colors.grey[600]
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
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
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'حفظ البيانات',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStoreId == null || _selectedStoreId!.isEmpty) {
      showSnackBar(context, 'يرجى اختيار المتجر', isError: true);
      return;
    }
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      showSnackBar(context, 'يرجى اختيار الفئة', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    String finalImageUrl = _selectedStoreImage ?? '';

    if (_pickedOfferImage != null) {
      try {
        final fileName =
            'offers_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final bytes = await _pickedOfferImage!.readAsBytes();
        await _supabase.storage.from('images').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        finalImageUrl = _supabase.storage.from('images').getPublicUrl(fileName);
      } catch (e) {
        showSnackBar(context, 'فشل رفع الصورة: $e', isError: true);
        if (mounted) setState(() => _isSaving = false);
        return;
      }
    }

    final data = {
      'name_ar': _nameArCtrl.text.trim(),
      'name_en': _nameEnCtrl.text.trim().isEmpty
          ? _nameArCtrl.text.trim()
          : _nameEnCtrl.text.trim(),
      'description_ar': _descArCtrl.text.trim(),
      'description_en': _descEnCtrl.text.trim().isEmpty
          ? _descArCtrl.text.trim()
          : _descEnCtrl.text.trim(),
      'name': _nameArCtrl.text.trim(),
      'description': _descArCtrl.text.trim(),
      'web': _webCtrl.text.trim(),

      // ✅ ربط المتجر
      'store_id': _selectedStoreId, // slug

      // ✅ category_id حسب جدولك
      'category_id': _selectedCategoryId,

      // ✅ tags jsonb
      'tags': _codeCtrl.text.trim().isEmpty
          ? <String>[]
          : <String>[_codeCtrl.text.trim()],

      'image': finalImageUrl,
    };

    try {
      if (widget.offer == null) {
        await _supabase.from('offers').insert(data);
      } else {
        // ✅ Fix: Use upsert with explicit ID to prevent "null value in column id" error
        data['id'] = widget.offer!.id;
        // Clean any potential nulls just in case, though validator handles most
        data.removeWhere((key, value) => value == null);
        await _supabase.from('offers').upsert(data);
      }
      if (mounted) {
        Navigator.pop(context);
        showSnackBar(
          context,
          widget.offer == null ? 'تمت إضافة العرض ✅' : 'تم تحديث العرض ✅',
        );
      }
    } catch (e) {
      showSnackBar(context, 'حدث خطأ أثناء الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
