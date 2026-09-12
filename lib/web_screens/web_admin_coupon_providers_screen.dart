import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_i18n.dart';

class WebAdminCouponProvidersScreen extends StatefulWidget {
  const WebAdminCouponProvidersScreen({super.key});

  @override
  State<WebAdminCouponProvidersScreen> createState() =>
      _WebAdminCouponProvidersScreenState();
}

class _WebAdminCouponProvidersScreenState
    extends State<WebAdminCouponProvidersScreen> {
  static const String _font = 'Tajawal';

  final _sb = Supabase.instance.client;
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _searchCtrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  String _search = '';
  bool _isSaving = false;
  final Set<String> _expandedProviderIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final results = await Future.wait([
      _sb.from('coupon_providers').select().order('name'),
      _sb.from('coupons').select(
            'id, provider_id, store_id, name_ar, name_en, code, coupon_type, discount_percent, is_active, expiry_date',
          ),
      _sb.from('offers').select(
            'id, provider_id, store_id, description_ar, description_en, tags, expiry_date',
          ),
      _sb.from('stores').select('slug, name, name_ar, name_en'),
    ]);
    final rows = List<Map<String, dynamic>>.from(results[0]);
    final coupons = List<Map<String, dynamic>>.from(results[1]);
    final offers = List<Map<String, dynamic>>.from(results[2]);
    final stores = List<Map<String, dynamic>>.from(results[3]);
    final storeNames = <String, String>{};
    for (final store in stores) {
      final slug = store['slug']?.toString().trim();
      if (slug == null || slug.isEmpty) continue;
      final nameAr = store['name_ar']?.toString().trim() ?? '';
      final name = store['name']?.toString().trim() ?? '';
      final nameEn = store['name_en']?.toString().trim() ?? '';
      storeNames[slug] = nameAr.isNotEmpty
          ? nameAr
          : name.isNotEmpty
              ? name
              : nameEn;
    }
    final counts = <String, int>{};
    final offerCounts = <String, int>{};
    final groupedCoupons = <String, List<Map<String, dynamic>>>{};
    final groupedOffers = <String, List<Map<String, dynamic>>>{};
    for (final coupon in coupons) {
      final providerId = coupon['provider_id']?.toString().trim();
      if (providerId == null || providerId.isEmpty) continue;
      final storeId = coupon['store_id']?.toString().trim() ?? '';
      counts[providerId] = (counts[providerId] ?? 0) + 1;
      groupedCoupons.putIfAbsent(providerId, () => []).add({
        ...coupon,
        '_store_display_name': storeNames[storeId] ?? storeId,
      });
    }
    for (final offer in offers) {
      final providerId = offer['provider_id']?.toString().trim();
      if (providerId == null || providerId.isEmpty) continue;
      final storeId = offer['store_id']?.toString().trim() ?? '';
      offerCounts[providerId] = (offerCounts[providerId] ?? 0) + 1;
      groupedOffers.putIfAbsent(providerId, () => []).add({
        ...offer,
        '_store_display_name': storeNames[storeId] ?? storeId,
      });
    }
    return rows.map((row) {
      final providerId = row['id']?.toString().trim() ?? '';
      return {
        ...row,
        'coupon_count': counts[providerId] ?? 0,
        'offer_count': offerCounts[providerId] ?? 0,
        '_coupons': groupedCoupons[providerId] ?? <Map<String, dynamic>>[],
        '_offers': groupedOffers[providerId] ?? <Map<String, dynamic>>[],
      };
    }).toList();
  }

  Future<void> _openLocation(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.tryParse(
      trimmed.startsWith(RegExp(r'https?://')) ? trimmed : 'https://$trimmed',
    );
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showSnackBar(
        context,
        webText(context, 'تعذر فتح الموقع', 'Could not open website'),
        isError: true,
      );
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    _name.text = (row?['name'] ?? '').toString();
    _location.text = (row?['location'] ?? '').toString();
    final id = row?['id']?.toString();
    setState(() => _isSaving = false);

    await showDialog<void>(
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
                  id == null ? Icons.add_business_rounded : Icons.edit_rounded,
                  color: Constants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  id == null
                      ? webText(
                          context, 'إضافة موفر كوبونات', 'Add Coupon Provider')
                      : webText(context, 'تعديل الموفر', 'Edit Provider'),
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
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _providerInputField(
                    _name,
                    webText(context, 'اسم الموفر', 'Provider Name'),
                    Icons.business_center_outlined,
                  ),
                  _providerInputField(
                    _location,
                    webText(context, 'الموقع', 'Website'),
                    Icons.language_outlined,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(ctx),
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
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_name.text.trim().isEmpty) return;
                        final data = {
                          'name': _name.text.trim(),
                          'location': _location.text.trim()
                        };
                        setStateDialog(() => _isSaving = true);
                        try {
                          if (id == null) {
                            await _sb.from('coupon_providers').insert(data);
                          } else {
                            await _sb
                                .from('coupon_providers')
                                .update(data)
                                .eq('id', id);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            setState(() {
                              _future = _load();
                              _isSaving = false;
                            });
                          }
                        } catch (e) {
                          setStateDialog(() => _isSaving = false);
                          if (mounted) {
                            showSnackBar(context, 'خطأ: $e', isError: true);
                          }
                        }
                      },
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
                  id == null
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

  Widget _providerInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Constants.primaryColor),
          labelText: label,
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

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final location = (item['location'] ?? '').toString().toLowerCase();
      return name.contains(q) || location.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            webText(context, 'موفرو الكوبونات', 'Coupon Providers'),
            style: TextStyle(
              fontFamily: _font,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Constants.primaryColor),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: ResponsivePadding.page(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _searchWithAddButton(),
                const SizedBox(height: 18),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final items = _applySearch(snap.data ?? []);
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            webText(context, 'لا يوجد موفرو كوبونات',
                                'No coupon providers available'),
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

                    return _buildProvidersGrid(items);
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );

  Widget _searchWithAddButton() {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final addButton = SizedBox(
      height: 46,
      width: isDesktop ? null : double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          webText(context, 'إضافة موفر', 'Add Provider'),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: _font,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    if (!isDesktop) {
      return Column(
        children: [
          _searchBar(),
          const SizedBox(height: 10),
          addButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _searchBar()),
        const SizedBox(width: 12),
        addButton,
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
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: webText(context, 'ابحث باسم الموفر أو الموقع...',
                    'Search by provider name or website...'),
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

  Widget _buildProvidersGrid(List<Map<String, dynamic>> items) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final availableWidth = MediaQuery.sizeOf(context).width;
    final pagePadding = ResponsivePadding.page(context).horizontal;
    final maxContentWidth = availableWidth - pagePadding;
    final cardWidth = isDesktop
        ? ((maxContentWidth - 28) / 3).clamp(300.0, 430.0)
        : double.infinity;

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: items
          .map(
            (item) => SizedBox(
              width: cardWidth,
              child: _providerCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _providerCard(Map<String, dynamic> row) {
    final id = row['id']?.toString().trim() ?? '';
    final name = (row['name'] ?? '').toString();
    final location = (row['location'] ?? '').toString();
    final hasLocation = location.trim().isNotEmpty;
    final couponCount = (row['coupon_count'] as int?) ?? 0;
    final offerCount = (row['offer_count'] as int?) ?? 0;
    final coupons =
        List<Map<String, dynamic>>.from(row['_coupons'] as List? ?? const []);
    final offers =
        List<Map<String, dynamic>>.from(row['_offers'] as List? ?? const []);
    final totalItems = couponCount + offerCount;
    final isExpanded = _expandedProviderIds.contains(id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E7F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Constants.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.business_center_outlined,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name.isEmpty
                        ? webText(context, 'بدون اسم', 'Unnamed provider')
                        : name,
                    style: const TextStyle(
                      fontFamily: _font,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: webText(context, 'خيارات', 'Options'),
                  onSelected: (value) {
                    if (value == 'edit') _edit(row);
                    if (value == 'delete') _delete(row);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(webText(context, 'تعديل', 'Edit')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(webText(context, 'حذف', 'Delete')),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        hasLocation ? () => _openLocation(location) : null,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      webText(context, 'فتح الموقع', 'Open website'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Constants.primaryColor,
                      backgroundColor:
                          Constants.primaryColor.withValues(alpha: 0.045),
                      disabledForegroundColor: Colors.grey[500],
                      side: BorderSide(
                        color: hasLocation
                            ? Constants.primaryColor.withValues(alpha: 0.24)
                            : Colors.grey[300]!,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      fixedSize: const Size.fromHeight(40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _statusBadge(
                  '$couponCount ${webText(context, 'كوبون', 'coupons')}',
                  Icons.confirmation_number_outlined,
                ),
                const SizedBox(width: 8),
                _statusBadge(
                  '$offerCount ${webText(context, 'عرض', 'offers')}',
                  Icons.local_offer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 22, thickness: 0.8),
            Row(
              children: [
                _statusBadge(
                  webText(context, 'موفر كوبونات', 'Coupon provider'),
                  Icons.verified_outlined,
                ),
                const Spacer(),
                IconButton(
                  tooltip: webText(context, 'تعديل', 'Edit'),
                  onPressed: () => _edit(row),
                  icon: Icon(Icons.edit_note_rounded,
                      color: Colors.blueGrey[500]),
                ),
                IconButton(
                  tooltip: webText(context, 'حذف', 'Delete'),
                  onPressed: () => _delete(row),
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                ),
                const SizedBox(width: 2),
                _expandButton(
                  isExpanded: isExpanded,
                  totalItems: totalItems,
                  onTap: id.isEmpty || totalItems == 0
                      ? null
                      : () {
                          setState(() {
                            if (isExpanded) {
                              _expandedProviderIds.remove(id);
                            } else {
                              _expandedProviderIds.add(id);
                            }
                          });
                        },
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _providerDealsList(coupons, offers),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
              sizeCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandButton({
    required bool isExpanded,
    required int totalItems,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: webText(context, 'عرض الكوبونات والعروض', 'Show deals'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: totalItems == 0
                ? Colors.grey[100]
                : Constants.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: totalItems == 0
                  ? Colors.grey[200]!
                  : Constants.primaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: totalItems == 0 ? Colors.grey[400] : Constants.primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _providerDealsList(
    List<Map<String, dynamic>> coupons,
    List<Map<String, dynamic>> offers,
  ) {
    final children = <Widget>[];
    if (coupons.isNotEmpty) {
      children.add(_dealsGroupTitle(
        webText(context, 'الكوبونات', 'Coupons'),
        coupons.length,
        Icons.confirmation_number_outlined,
      ));
      children.addAll(
        coupons.map((coupon) => _providerDealRow(coupon, isOffer: false)),
      );
    }
    if (offers.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(_dealsGroupTitle(
        webText(context, 'العروض', 'Offers'),
        offers.length,
        Icons.local_offer_outlined,
      ));
      children.addAll(
        offers.map((offer) => _providerDealRow(offer, isOffer: true)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Constants.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Constants.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _dealsGroupTitle(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Constants.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: _font,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Constants.textColor,
              ),
            ),
          ),
          _miniCountBadge(count),
        ],
      ),
    );
  }

  Widget _providerDealRow(Map<String, dynamic> item, {required bool isOffer}) {
    final title = _dealTitle(item, isOffer: isOffer);
    final storeName = _dealStoreName(item);
    final code = isOffer ? _firstTag(item['tags']) : (item['code'] ?? '');
    final discount = isOffer ? '' : (item['discount_percent'] ?? '');
    final isActive = item['is_active'] != false;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEAFB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isOffer
                  ? Constants.offerBadgeBackgroundColor
                  : Constants.couponBadgeBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOffer
                  ? Icons.local_offer_outlined
                  : Icons.confirmation_number_outlined,
              color: isOffer
                  ? Constants.offerBadgeColor
                  : Constants.couponBadgeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (storeName.isNotEmpty) ...[
                      _storeNamePill(storeName),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: _font,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Constants.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (code.toString().trim().isNotEmpty ||
                    discount.toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (code.toString().trim().isNotEmpty)
                          code.toString().trim(),
                        if (discount.toString().trim().isNotEmpty)
                          '${discount.toString().trim()}%',
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Constants.secondaryTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _tinyTypeBadge(
            isOffer
                ? webText(context, 'عرض', 'Offer')
                : (isActive
                    ? webText(context, 'فعال', 'Active')
                    : webText(context, 'متوقف', 'Inactive')),
            isOffer
                ? Constants.offerBadgeColor
                : (isActive
                    ? Constants.successColor
                    : Constants.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _storeNamePill(String storeName) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Constants.primaryLightColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Constants.borderColor),
      ),
      child: Text(
        storeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Constants.storeNameColor,
          fontFamily: _font,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _miniCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Constants.primaryColor,
          fontFamily: _font,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _tinyTypeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: _font,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  String _dealTitle(Map<String, dynamic> item, {required bool isOffer}) {
    final keys = isOffer
        ? ['description_ar', 'description_en', 'name_ar', 'name_en']
        : ['name_ar', 'name_en', 'description_ar', 'description_en'];
    for (final key in keys) {
      final value = item[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return isOffer
        ? webText(context, 'عرض بدون عنوان', 'Untitled offer')
        : webText(context, 'كوبون بدون عنوان', 'Untitled coupon');
  }

  String _dealStoreName(Map<String, dynamic> item) {
    const keys = [
      '_store_display_name',
      'store_name_ar',
      'store_name',
      'store_name_en',
      'store_id'
    ];
    for (final key in keys) {
      final value = item[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  String _firstTag(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    final text = value?.toString().trim() ?? '';
    if (text.startsWith('[') && text.endsWith(']')) {
      return text
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .first
          .trim();
    }
    return text.split(',').first.trim();
  }

  Widget _statusBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: Constants.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Constants.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Constants.primaryColor,
              fontWeight: FontWeight.w900,
              fontFamily: _font,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('حذف موفر الكوبونات؟'),
              content: const Text('سيتم حذف الموفر من القائمة.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child:
                        const Text('حذف', style: TextStyle(color: Colors.red)))
              ],
            ));
    if (ok != true) return;
    try {
      await _sb.from('coupon_providers').delete().eq('id', row['id']);
      if (mounted) {
        setState(() {
          _future = _load();
        });
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'خطأ: $e', isError: true);
    }
  }
}
