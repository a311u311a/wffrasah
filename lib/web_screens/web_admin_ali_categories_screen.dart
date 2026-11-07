import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../models/ali_category.dart';
import '../services/ali_products_service.dart';
import '../web_widgets/web_network_image.dart';

/// لوحة تحكم فئات علي إكسبرس (جدول ali_categories): الترتيب، الاسم،
/// الأيقونة، عمليات البحث، والتفعيل. التعديلات على البحث تظهر في المزامنة
/// القادمة (كل 6 ساعات).
class WebAdminAliCategoriesScreen extends StatefulWidget {
  final bool isEmbedded;

  const WebAdminAliCategoriesScreen({super.key, this.isEmbedded = false});

  @override
  State<WebAdminAliCategoriesScreen> createState() =>
      _WebAdminAliCategoriesScreenState();
}

class _WebAdminAliCategoriesScreenState
    extends State<WebAdminAliCategoriesScreen> {
  static const _font = 'Tajawal';
  final _sb = Supabase.instance.client;

  List<AliCategory> _categories = [];
  Map<String, int> _counts = {};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _sb
            .from('ali_categories')
            .select()
            .order('sort_order', ascending: true),
        _sb.from('ali_category_counts').select('id, products'),
      ]);
      final counts = <String, int>{
        for (final r in results[1] as List)
          (r['id'] ?? '').toString():
              num.tryParse('${r['products']}')?.toInt() ?? 0,
      };
      if (!mounted) return;
      setState(() {
        _categories = (results[0] as List)
            .map((r) => AliCategory.fromMap(Map<String, dynamic>.from(r)))
            .toList();
        _counts = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: _font)),
      backgroundColor: error ? Colors.redAccent : Constants.primaryColor,
    ));
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      AliProductsService.clearCache();
      await _load();
      if (mounted) _toast(done);
    } catch (e) {
      if (mounted) _toast('تعذر الحفظ: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// يبدّل ترتيب فئتين متجاورتين.
  Future<void> _move(int index, int delta) async {
    final other = index + delta;
    if (other < 0 || other >= _categories.length) return;
    final a = _categories[index];
    final b = _categories[other];
    await _run(() async {
      await _sb.from('ali_categories').update(
          {'sort_order': b.sortOrder, 'updated_at': _now()}).eq('id', a.id);
      await _sb.from('ali_categories').update(
          {'sort_order': a.sortOrder, 'updated_at': _now()}).eq('id', b.id);
    }, 'تم تغيير الترتيب');
  }

  Future<void> _toggleActive(AliCategory c, bool active) => _run(
        () => _sb
            .from('ali_categories')
            .update({'active': active, 'updated_at': _now()}).eq('id', c.id),
        active ? 'تم إظهار الفئة' : 'تم إخفاء الفئة',
      );

  String _now() => DateTime.now().toUtc().toIso8601String();

  Future<void> _openEditor([AliCategory? c]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AliCategoryDialog(category: c),
    );
    if (result == null) return;
    if (c == null) {
      final maxOrder =
          _categories.fold<int>(0, (m, x) => x.sortOrder > m ? x.sortOrder : m);
      await _run(
        () => _sb.from('ali_categories').insert({
          ...result,
          'sort_order': maxOrder + 1,
        }),
        'تمت إضافة الفئة، وتظهر منتجاتها بعد المزامنة القادمة',
      );
    } else {
      await _run(
        () => _sb
            .from('ali_categories')
            .update({...result, 'updated_at': _now()}).eq('id', c.id),
        'تم حفظ الفئة',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'فئات قسم علي إكسبرس، بالترتيب الذي تظهر به للزوار. '
                    'تعديل البحث يظهر أثره في المزامنة القادمة (كل 6 ساعات).',
                    style: TextStyle(
                      fontFamily: _font,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _openEditor(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة فئة',
                      style: TextStyle(
                          fontFamily: _font, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildList()),
        ],
      ),
    );

    if (widget.isEmbedded) return body;
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('فئات علي إكسبرس', style: TextStyle(fontFamily: _font)),
        backgroundColor: Colors.white,
        foregroundColor: Constants.primaryColor,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FD),
      body: body,
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('خطأ في تحميل الفئات: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _row(i),
    );
  }

  Widget _row(int i) {
    final c = _categories[i];
    final products = _counts[c.id] ?? 0;
    final searches = c.keywords
        .split('|')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty && !g.startsWith('-'))
        .length;
    return Opacity(
      opacity: c.active ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text('${i + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: _font,
                      fontWeight: FontWeight.w900,
                      color: Constants.primaryColor)),
            ),
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: WebNetworkImage(c.icon,
                  fit: BoxFit.contain,
                  error: (_) => Icon(Icons.category_rounded,
                      color: Constants.primaryColor)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.nameAr,
                      style: const TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    '${c.nameEn} · $products منتج · $searches بحث'
                    '${c.active ? '' : ' · مخفية'}',
                    style: const TextStyle(
                        fontFamily: _font, color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: c.active ? 'ظاهرة للزوار' : 'مخفية',
              child: Switch(
                value: c.active,
                activeThumbColor: Constants.primaryColor,
                onChanged: _busy ? null : (v) => _toggleActive(c, v),
              ),
            ),
            IconButton(
              tooltip: 'لأعلى',
              onPressed: _busy || i == 0 ? null : () => _move(i, -1),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
            IconButton(
              tooltip: 'لأسفل',
              onPressed: _busy || i == _categories.length - 1
                  ? null
                  : () => _move(i, 1),
              icon: const Icon(Icons.arrow_downward_rounded),
            ),
            IconButton(
              tooltip: 'تعديل',
              onPressed: _busy ? null : () => _openEditor(c),
              icon: Icon(Icons.edit_rounded, color: Constants.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// نافذة إضافة/تعديل فئة. ترجع الحقول المراد حفظها.
class _AliCategoryDialog extends StatefulWidget {
  final AliCategory? category;
  const _AliCategoryDialog({this.category});

  @override
  State<_AliCategoryDialog> createState() => _AliCategoryDialogState();
}

class _AliCategoryDialogState extends State<_AliCategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _nameAr = TextEditingController(text: widget.category?.nameAr);
  late final _nameEn = TextEditingController(text: widget.category?.nameEn);
  late final _icon = TextEditingController(text: widget.category?.icon);
  late final _searches = TextEditingController(
      text: _groups(widget.category?.keywords ?? '', exclude: false));
  late final _excludes = TextEditingController(
      text: _groups(widget.category?.keywords ?? '', exclude: true));

  /// عمليات البحث سطر لكل بحث، والكلمات المستبعدة مفصولة بفواصل.
  static String _groups(String keywords, {required bool exclude}) {
    final groups = keywords.split('|').map((g) => g.trim()).where((g) {
      if (g.isEmpty) return false;
      return exclude ? g.startsWith('-') : !g.startsWith('-');
    });
    return exclude
        ? groups.map((g) => g.substring(1).trim()).join(', ')
        : groups.join('\n');
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    _icon.dispose();
    _searches.dispose();
    _excludes.dispose();
    super.dispose();
  }

  String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  void _save() {
    if (!_form.currentState!.validate()) return;
    final searches = _searches.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);
    final excludes = _excludes.text.trim();
    final keywords = [
      ...searches,
      if (excludes.isNotEmpty) '-$excludes',
    ].join(' | ');
    Navigator.pop(context, {
      if (widget.category == null) 'id': _slug(_nameEn.text),
      'name_ar': _nameAr.text.trim(),
      'name_en': _nameEn.text.trim(),
      'icon': _icon.text.trim().isEmpty ? null : _icon.text.trim(),
      'keywords': keywords,
    });
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
      );

  @override
  Widget build(BuildContext context) {
    final isNew = widget.category == null;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isNew ? 'إضافة فئة علي إكسبرس' : 'تعديل الفئة',
            style: const TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 560,
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                      controller: _nameAr,
                      decoration: _dec('الاسم بالعربي'),
                      validator: required),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameEn,
                    decoration: _dec('الاسم بالإنجليزي'),
                    textDirection: TextDirection.ltr,
                    validator: (v) {
                      if (required(v) != null) return 'مطلوب';
                      if (isNew && _slug(v!).isEmpty) {
                        return 'استخدم حروفاً إنجليزية';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _icon,
                    decoration: _dec('رابط الأيقونة'),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _searches,
                    decoration: _dec('عمليات البحث في علي إكسبرس',
                        hint: 'بحث في كل سطر، بالإنجليزي'),
                    textDirection: TextDirection.ltr,
                    minLines: 4,
                    maxLines: 10,
                    validator: required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _excludes,
                    decoration: _dec('كلمات مستبعدة (اختياري)',
                        hint: 'مفصولة بفواصل: شفاف, مكشوف, sexy'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          FilledButton(
            onPressed: _save,
            style:
                FilledButton.styleFrom(backgroundColor: Constants.primaryColor),
            child: const Text('حفظ',
                style: TextStyle(
                    fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
