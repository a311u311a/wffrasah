import 'dart:typed_data';
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

// ✅ صفحة إدارة العروض على الويب (مستقلة) - تم تحديث التصميم
class WebAdminOffersScreen extends StatefulWidget {
  final bool isEmbedded;
  const WebAdminOffersScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminOffersScreen> createState() => _WebAdminOffersScreenState();
}

class _WebAdminOffersScreenState extends State<WebAdminOffersScreen> {
  static const String _font = 'Tajawal';
  final SupabaseClient _sb = Supabase.instance.client;

  // UI search
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

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
                hintText: 'ابحث بالاسم أو الوصف أو الوسوم أو الرابط…',
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
      final name = (r['name_ar'] ?? r['name'] ?? '').toString().toLowerCase();
      final desc = (r['description_ar'] ?? r['description'] ?? '')
          .toString()
          .toLowerCase();
      final web = (r['web'] ?? '').toString().toLowerCase();

      // tags ممكن تكون List أو null
      final tagsRaw = r['tags'];
      final tags = (tagsRaw is List)
          ? tagsRaw.map((e) => e.toString().toLowerCase()).join(' ')
          : '';

      return name.contains(q) ||
          desc.contains(q) ||
          web.contains(q) ||
          tags.contains(q);
    }

    return items.where(match).toList();
  }

  // =========================
  // Grid UI (New)
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
        mainAxisExtent: 165,
      ),
      itemBuilder: (context, index) {
        final data = items[index];

        final tags = (data['tags'] is List)
            ? List<String>.from(data['tags'])
            : <String>[];

        final offerModel = Offer(
          id: data['id'].toString(),
          name: (data['name_ar'] ?? data['name'] ?? '').toString(),
          nameAr: (data['name_ar'] ?? '').toString(),
          nameEn: (data['name_en'] ?? '').toString(),
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
        );

        return _offerCard(offerModel, data['id'].toString());
      },
    );
  }

  Widget _offerCard(Offer offer, String id) {
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
                      Text(
                        offer.name.isEmpty ? 'بدون اسم' : offer.name,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Tags row
                      if (offer.tags.isNotEmpty)
                        Text(
                          '#${offer.tags.join(" #")}',
                          style: TextStyle(
                            fontFamily: _font,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Constants.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'لا يوجد وسوم',
                          style: TextStyle(
                            fontFamily: _font,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),

                // Popup Actions
                PopupMenuButton<String>(
                  tooltip: 'خيارات',
                  onSelected: (v) {
                    if (v == 'edit') _openAddOrEditDialog(offer: offer);
                    if (v == 'delete') _deleteOffer(id);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Expiry Info
            if (offer.expiryDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Builder(builder: (_) {
                  final daysLeft =
                      offer.expiryDate!.difference(DateTime.now()).inDays;
                  final isSoon = daysLeft <= 5;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              )
            else
              const Spacer(), // spacer if no date to push buttons down

            const Spacer(),

            // Footer Buttons
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: () => _openAddOrEditDialog(offer: offer),
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[500]),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => _deleteOffer(id),
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

// ═══════════════════════════════════════════════════════════════════════════
// ✅ نموذج إضافة/تعديل العرض (Form Sheet)
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

  // Controllers
  final TextEditingController _nameArCtrl = TextEditingController();
  final TextEditingController _nameEnCtrl = TextEditingController();
  final TextEditingController _descArCtrl = TextEditingController();
  final TextEditingController _descEnCtrl = TextEditingController();
  final TextEditingController _webCtrl = TextEditingController();
  final TextEditingController _tagsCtrl = TextEditingController();

  String? _imageUrl;
  Uint8List? _pickedImageBytes;
  String? _selectedCategoryId;
  DateTime? _expiryDate;
  bool _saving = false;
  bool get _isEdit => widget.offer != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final o = widget.offer!;
      _nameArCtrl.text = o.nameAr;
      _nameEnCtrl.text = o.nameEn;
      _descArCtrl.text = o.descriptionAr;
      _descEnCtrl.text = o.descriptionEn;
      _webCtrl.text = o.web;
      _tagsCtrl.text = o.tags.join(', ');
      _imageUrl = o.image;
      _selectedCategoryId = o.categoryId.isNotEmpty ? o.categoryId : null;
      _expiryDate = o.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _descArCtrl.dispose();
    _descEnCtrl.dispose();
    _webCtrl.dispose();
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
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (_nameArCtrl.text.trim().isEmpty) {
      showSnackBar(context, 'الرجاء إدخال اسم العرض بالعربية', isError: true);
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
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim(),
        'description_ar': _descArCtrl.text.trim(),
        'description_en': _descEnCtrl.text.trim(),
        'web': _webCtrl.text.trim(),
        'image': uploadedUrl ?? '',
        'tags': tags,
        'category_id': _selectedCategoryId,
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
            // ═══ صورة العرض ═══
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

            // ═══ الاسم ═══
            _buildSectionTitle('الاسم'),
            const SizedBox(height: 10),
            _inputField(_nameArCtrl, 'الاسم بالعربية', Icons.edit_rounded),
            const SizedBox(height: 10),
            _inputField(_nameEnCtrl, 'الاسم بالإنجليزية', Icons.edit_rounded),
            const SizedBox(height: 24),

            // ═══ الوصف ═══
            _buildSectionTitle('الوصف'),
            const SizedBox(height: 10),
            _inputField(
                _descArCtrl, 'الوصف بالعربية', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 10),
            _inputField(
                _descEnCtrl, 'الوصف بالإنجليزية', Icons.description_rounded,
                maxLines: 3),
            const SizedBox(height: 24),

            // ═══ الرابط ═══
            _buildSectionTitle('رابط العرض'),
            const SizedBox(height: 10),
            _inputField(
                _webCtrl, 'https://example.com/offer', Icons.link_rounded),
            const SizedBox(height: 24),

            // ═══ الوسوم ═══
            _buildSectionTitle('الوسوم (مفصولة بفاصلة)'),
            const SizedBox(height: 10),
            _inputField(_tagsCtrl, 'خصم, عرض, صيف', Icons.tag_rounded),
            const SizedBox(height: 24),

            // ═══ التصنيف ═══
            _buildSectionTitle('التصنيف'),
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
                      hint: Text('اختر التصنيف',
                          style: TextStyle(
                              fontFamily: _font, color: Colors.grey[500])),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('بدون تصنيف')),
                        ...categories.map((cat) => DropdownMenuItem(
                              value: cat['id'].toString(),
                              child: Text(cat['name_ar'] ?? cat['name'] ?? '',
                                  style: const TextStyle(fontFamily: _font)),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ═══ تاريخ الانتهاء ═══
            _buildSectionTitle('تاريخ الانتهاء'),
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
            const SizedBox(height: 32),

            // ═══ زر الحفظ ═══
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
