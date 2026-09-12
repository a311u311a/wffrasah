import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/coupon.dart';
import '../providers/favorites_provider.dart';
import '../services/analytics_service.dart';

// بطاقة الكوبون الرئيسية: تعرض بيانات الكوبون المختصرة داخل القائمة.
// عند الضغط عليها يتم فتح شاشة التفاصيل الكاملة للكوبون.
class CouponCard extends StatefulWidget {
  final Coupon coupon;
  final EdgeInsetsGeometry? margin;
  final String? storeName;
  final double? height;

  const CouponCard({
    super.key,
    required this.coupon,
    this.margin,
    this.storeName,
    this.height,
  });

  @override
  State<CouponCard> createState() => _CouponCardState();
}

// حالة بطاقة الكوبون: تتولى منطق النسخ، المشاركة، متابعة المتجر،
// تسجيل الاستخدام، وتحديد اسم الصورة والخصم المناسب لكل كوبون.
class _CouponCardState extends State<CouponCard> {
  bool _copied = false;
  bool _isFollowing = false;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFollowState());
  }

  String get _storeName {
    final name = widget.coupon.storeName.trim();
    if (name.isNotEmpty) return name;
    final fallback = widget.storeName?.trim() ?? '';
    if (fallback.isNotEmpty) return fallback;
    return widget.coupon.name;
  }

  String get _cardImageUrl {
    final isOffer = widget.coupon.couponType == 'offer' ||
        widget.coupon.couponType == 'عرض';

    if (isOffer) {
      final storeImage = widget.coupon.storeImage.trim();
      if (storeImage.isNotEmpty) return storeImage;
      return widget.coupon.image;
    }

    final storeImage = widget.coupon.storeImage.trim();
    if (storeImage.isNotEmpty) return storeImage;
    return widget.coupon.image;
  }

  String get _detailsImageUrl {
    final offerImage = widget.coupon.image.trim();
    if (offerImage.isNotEmpty) return offerImage;

    final storeImage = widget.coupon.storeImage.trim();
    if (storeImage.isNotEmpty) return storeImage;
    return '';
  }

  String get _discountLabel {
    return widget.coupon.discountPercent?.trim() ?? '';
  }

  String get _ticketTitle {
    switch (widget.coupon.couponType) {
      case 'cashback':
        return 'رصيد مسترجع';
      case 'offer':
        return 'عرض';
      case 'extra_discount':
        return 'خصم إضافي';
      default:
        return 'كوبون';
    }
  }

  Future<void> _copyCode() async {
    final code = widget.coupon.code.trim();
    if (code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    await _recordUsage('copy');
    unawaited(AnalyticsService.trackEvent(
      eventType: 'coupon_copy',
      itemType: 'coupon',
      itemId: widget.coupon.id,
      storeId: widget.coupon.storeId,
    ));
    HapticFeedback.lightImpact();

    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareCoupon() async {
    final description = widget.coupon.description.trim();
    final code = widget.coupon.code.trim();
    final link = widget.coupon.web.trim();
    final lines = [
      _storeName,
      if (description.isNotEmpty) description,
      if (code.isNotEmpty) 'كود الخصم: $code',
      if (link.isNotEmpty) 'الرابط: $link',
    ];
    await SharePlus.instance.share(
      ShareParams(text: lines.join('\n')),
    );
    await _recordUsage('share');
  }

  Future<void> _visitStore() async {
    final raw = widget.coupon.web.trim();
    if (raw.isEmpty) return;

    Uri? uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (!uri.hasScheme) uri = Uri.tryParse('https://$raw');
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await _recordUsage('shop_now');
      unawaited(AnalyticsService.trackEvent(
        eventType: 'store_click',
        itemType: 'coupon',
        itemId: widget.coupon.id,
        storeId: widget.coupon.storeId,
      ));
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _recordUsage(String eventType) async {
    final sb = Supabase.instance.client;
    final userId = sb.auth.currentUser?.id;
    try {
      await sb.from('coupon_usage_events').insert({
        'coupon_id': widget.coupon.id,
        'user_id': userId,
        'event_type': eventType,
      });
      await sb.from('coupons').update({
        'last_used_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.coupon.id);
    } catch (_) {
      // Usage tracking should not block shopping, sharing, or copying.
    }
  }

  Future<void> _loadFollowState() async {
    final sb = Supabase.instance.client;
    final userId = sb.auth.currentUser?.id;
    if (userId == null || widget.coupon.storeId.trim().isEmpty) return;

    try {
      final row = await sb
          .from('store_follows')
          .select('id')
          .eq('user_id', userId)
          .eq('store_id', widget.coupon.storeId)
          .maybeSingle();
      if (mounted) setState(() => _isFollowing = row != null);
    } catch (_) {}
  }

  Future<bool?> _toggleFollow(BuildContext context) async {
    if (_followBusy) return _isFollowing;
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل الدخول أولاً لمتابعة المتجر')),
      );
      return null;
    }
    if (widget.coupon.storeId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن متابعة متجر غير معروف')),
      );
      return null;
    }

    setState(() => _followBusy = true);
    try {
      if (_isFollowing) {
        await sb
            .from('store_follows')
            .delete()
            .eq('user_id', user.id)
            .eq('store_id', widget.coupon.storeId);
      } else {
        await sb.from('store_follows').insert({
          'user_id': user.id,
          'store_id': widget.coupon.storeId,
        });
      }
      final newValue = !_isFollowing;
      if (mounted) setState(() => _isFollowing = newValue);
      return newValue;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        if (mounted) setState(() => _isFollowing = true);
        return true;
      }
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث متابعة المتجر: ${e.message}')),
      );
      return null;
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث متابعة المتجر: $e')),
      );
      return null;
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  void _openDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CouponDetailsSheet(
        coupon: widget.coupon,
        storeName: _storeName,
        cardImageUrl: _cardImageUrl,
        detailsImageUrl: _detailsImageUrl,
        isCopied: _copied,
        isFollowing: _isFollowing,
        followBusy: _followBusy,
        onCopy: _copyCode,
        onShare: _shareCoupon,
        onShop: _visitStore,
        onToggleFollow: () => _toggleFollow(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: Container(
        margin: widget.margin ??
            const EdgeInsets.only(top: 7, left: 15, right: 15, bottom: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Constants.primaryColor.withValues(alpha: 0.075),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openDetails,
            child: Container(
              height: widget.height ?? 124,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Constants.primaryColor.withValues(alpha: 0.22),
                  width: 1.15,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(112, 14, 14, 14),
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Constants.primaryColor
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: _StoreImage(
                                  imageUrl: _cardImageUrl, size: 72),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Constants.storeNameColor,
                                      height: 1.15,
                                    ),
                                  ),
                                  if (widget.coupon.description
                                      .trim()
                                      .isNotEmpty)
                                    const SizedBox(height: 7),
                                  if (widget.coupon.description
                                      .trim()
                                      .isNotEmpty)
                                    Text(
                                      widget.coupon.description.trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF817A96),
                                        height: 1.35,
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
                  Positioned(
                    left: 10,
                    top: 12,
                    bottom: 12,
                    child: Center(
                      child: _DiscountRibbon(
                        title: _ticketTitle,
                        value: _discountLabel,
                      ),
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
}

// شاشة تفاصيل الكوبون: تظهر عند الضغط على البطاقة وتعرض معلومات تفصيلية.
// تحتوي على الأزرار الخاصة بالمشاركة، المفضلة، المتابعة، وتحديد حالة الكوبون.
class _CouponDetailsSheet extends StatefulWidget {
  final Coupon coupon;
  final String storeName;
  final String cardImageUrl;
  final String detailsImageUrl;
  final bool isCopied;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShop;
  final Future<bool?> Function() onToggleFollow;

  const _CouponDetailsSheet({
    required this.coupon,
    required this.storeName,
    required this.cardImageUrl,
    required this.detailsImageUrl,
    required this.isCopied,
    required this.isFollowing,
    required this.followBusy,
    required this.onCopy,
    required this.onShare,
    required this.onShop,
    required this.onToggleFollow,
  });

  @override
  State<_CouponDetailsSheet> createState() => _CouponDetailsSheetState();
}

// حالة شاشة التفاصيل: تتحكم في حالة المتابعة والحالة الحالية للعرض داخل popup.
class _CouponDetailsSheetState extends State<_CouponDetailsSheet> {
  late bool _isFollowing = widget.isFollowing;
  late bool _followBusy = widget.followBusy;

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    final nextValue = await widget.onToggleFollow();
    if (!mounted) return;
    setState(() {
      if (nextValue != null) _isFollowing = nextValue;
      _followBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFavorite = favoriteProvider.isFavorite(widget.coupon.id);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isOffer = widget.coupon.couponType == 'offer' ||
        widget.coupon.couponType == 'عرض';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(top: 40, bottom: bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: Constants.primaryColor.withValues(alpha: 0.16),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Constants.primaryColor.withValues(alpha: 0.18),
                blurRadius: 34,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _StoreImage(
                            imageUrl: widget.cardImageUrl,
                            size: 82,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.storeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Constants.storeNameColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 116,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed:
                                        _followBusy ? null : _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFollowing
                                          ? Constants.primaryColor
                                          : Colors.white,
                                      foregroundColor: _isFollowing
                                          ? Colors.white
                                          : Constants.primaryColor,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: Constants.primaryColor,
                                          width: 1.4,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _isFollowing ? 'متابَع' : 'متابعة المتجر',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _CircleAction(
                                      icon: Icons.share_rounded,
                                      onTap: widget.onShare,
                                    ),
                                    _CircleAction(
                                      onTap: () =>
                                          favoriteProvider.toggleFavorite(
                                              widget.coupon, context),
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(
                                                scale: anim, child: child),
                                        child: isFavorite
                                            ? const _FavoriteStarIcon(
                                                key: ValueKey('fav_active'),
                                                active: true,
                                                size: 24,
                                              )
                                            : const _FavoriteStarIcon(
                                                key: ValueKey('fav_inactive'),
                                                active: false,
                                                size: 24,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isOffer)
                        _OfferDetailsImage(imageUrl: widget.detailsImageUrl)
                      else ...[
                        _CouponSummaryPanel(coupon: widget.coupon),
                        const SizedBox(height: 12),
                        _CouponActionBar(
                          children: [
                            _StatusActions(
                              couponId: widget.coupon.id,
                              initialIsActive: widget.coupon.isActive,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (widget.coupon.description.trim().isNotEmpty)
                        _InfoSection(
                          icon: Icons.notes_rounded,
                          title: 'الوصف',
                          body: widget.coupon.description,
                        ),
                      if (widget.coupon.terms.trim().isNotEmpty)
                        _InfoSection(
                          icon: Icons.rule_rounded,
                          title: 'شروط الاستخدام',
                          body: widget.coupon.terms,
                        ),
                      if (widget.coupon.code.trim().isNotEmpty) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: _LegacyCopyButton(
                              code: widget.coupon.code,
                              initialCopied: widget.isCopied,
                              onCopy: widget.onCopy,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (!isOffer) ...[
                        _MetaRow(
                          icon: Icons.history_rounded,
                          text: _lastUsedText(widget.coupon.lastUsedAt),
                          centered: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: ElevatedButton.icon(
                            onPressed: widget.coupon.web.trim().isEmpty
                                ? null
                                : widget.onShop,
                            icon: const Icon(Icons.shopping_bag_rounded),
                            label: const Text(
                              'تسوق الآن',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              backgroundColor: Constants.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  String _lastUsedText(DateTime? value) {
    if (value == null) return 'آخر استخدام: غير متوفر';
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) return 'آخر استخدام: الآن';
    if (diff.inMinutes < 60) return 'آخر استخدام منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'آخر استخدام منذ ${diff.inHours} ساعة';
    return 'آخر استخدام منذ ${diff.inDays} يوم';
  }
}

// زر نسخ الكود القديم: يعرض كود الخصم بشكل مخصص مع تأثير "تم النسخ".
class _LegacyCopyButton extends StatefulWidget {
  final String code;
  final bool initialCopied;
  final FutureOr<void> Function() onCopy;

  const _LegacyCopyButton({
    required this.code,
    required this.initialCopied,
    required this.onCopy,
  });

  @override
  State<_LegacyCopyButton> createState() => _LegacyCopyButtonState();
}

// حالة زر النسخ: تتبع إذا تم النسخ، ثم تعيد الحالة بعد فترة محددة.
class _LegacyCopyButtonState extends State<_LegacyCopyButton> {
  late bool _copied = widget.initialCopied;

  Future<void> _handleCopy() async {
    await widget.onCopy();
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 46.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: buttonHeight,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleCopy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Constants.primaryColor.withValues(alpha: 0.08),
                    foregroundColor: Constants.primaryColor,
                    disabledBackgroundColor:
                        Constants.primaryColor.withValues(alpha: 0.08),
                    disabledForegroundColor: Constants.primaryColor,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Constants.primaryColor.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.all(
                      Constants.primaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '  ${widget.code}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                right: null,
                left: 0,
                child: GestureDetector(
                  onTap: _handleCopy,
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          _copied ? Colors.green : Constants.primaryColor,
                          Colors.transparent,
                        ],
                        stops: const [0.97, 0.97],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return currentChild ?? const SizedBox.shrink();
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.98, end: 1)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _copied
                          ? Align(
                              key: const ValueKey('copied_check'),
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: constraints.maxWidth * 0.3,
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            )
                          : Align(
                              key: const ValueKey('copy_label'),
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: constraints.maxWidth * 0.55,
                                child: const Center(
                                  child: Text(
                                    'انسخ الكود',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// عنصر صورة المتجر: يعرض صورة المتجر أو أيقونة افتراضية إذا كانت الصورة غير موجودة.
class _StoreImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _StoreImage({
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 12.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: const Color(0xFF1F1B2D).withValues(alpha: 0.1),
            width: 1.1,
          ),
        ),
        child: imageUrl.trim().isEmpty
            ? Icon(Icons.store_rounded, color: Constants.primaryColor)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.store_rounded, color: Constants.primaryColor),
              ),
      ),
    );
  }
}

// صورة تفاصيل العرض: تستخدم عندما يكون نوع الكوبون عبارة عن عرض كبير.
class _OfferDetailsImage extends StatelessWidget {
  final String imageUrl;

  const _OfferDetailsImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageSide = (screenWidth * 0.72).clamp(220.0, 320.0);

    return Center(
      child: SizedBox(
        width: imageSide,
        height: imageSide,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Constants.primaryColor.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Constants.primaryColor.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: Constants.primaryColor.withValues(alpha: 0.045),
            child: imageUrl.trim().isEmpty
                ? Icon(
                    Icons.local_offer_rounded,
                    size: 52,
                    color: Constants.primaryColor.withValues(alpha: 0.35),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Constants.primaryColor.withValues(alpha: 0.55),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.local_offer_rounded,
                      size: 52,
                      color: Constants.primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// شريط الخصم: عرض قيمته بشكل مخصص في هيئة شريط/رداء يبرز النسبة أو القيمة.
class _DiscountRibbon extends StatelessWidget {
  final String title;
  final String value;

  const _DiscountRibbon({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TicketBadgePainter(),
      child: SizedBox(
        width: 82,
        height: 88,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final separatorY = constraints.maxHeight * 0.68;

            return Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: 5,
                  height: separatorY - 10,
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  right: 4,
                  top: separatorY + 6,
                  bottom: 6,
                  child: Center(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (title == 'خصم إضافي') ...[
                              Transform.translate(
                                offset: const Offset(0, -2),
                                child: SvgPicture.asset(
                                  'assets/icon/Saudi_Riyal_Symbol-2.svg',
                                  width: 25,
                                  height: 28,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
                            Transform.translate(
                              offset: title == 'خصم إضافي'
                                  ? const Offset(0, 2)
                                  : Offset.zero,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Tajawal',
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (title != 'عرض' && title != 'خصم إضافي')
                              const Text(
                                ' %',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Tajawal',
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// رسام شارة الخصم: يحافظ على شكل التذكرة مع فصل بصري واضح بين العنوان والقيمة.
class _TicketBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final paint = Paint()..color = const Color(0xFF6D5DF6);

    canvas.drawRRect(r, paint);

    final notchPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFF8B80F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRRect(r.deflate(0.7), borderPaint);

    final dashPaint = Paint()
      ..color = const Color.fromARGB(255, 245, 245, 246).withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const notchRadius = 8.0;
    canvas.drawCircle(Offset(0, size.height * 0.68), notchRadius, notchPaint);
    canvas.drawCircle(
        Offset(size.width, size.height * 0.68), notchRadius, notchPaint);

    const dashWidth = 4.0;
    const dashGap = 5.0;
    final y = size.height * 0.68;
    var x = 16.0;
    while (x < size.width - 16) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), dashPaint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// زر دائري صغير: يستخدم للأيقونات مثل المشاركة أو المفضلة في شاشة التفاصيل.
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Widget? child;

  const _CircleAction({
    this.icon = Icons.circle,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        shadowColor: Constants.primaryColor.withValues(alpha: 0.12),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.18),
              ),
            ),
            child: Center(
              child:
                  child ?? Icon(icon, color: Constants.primaryColor, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteStarIcon extends StatelessWidget {
  final bool active;
  final double size;

  const _FavoriteStarIcon({
    super.key,
    required this.active,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      active ? 'assets/icon/star_active.svg' : 'assets/icon/star.svg',
      width: size,
      height: size,
      colorFilter: active
          ? null
          : ColorFilter.mode(Constants.primaryColor, BlendMode.srcIn),
    );
  }
}

// شريط الإجراءات: يحتوي على سؤال "هل الكوبون يعمل؟" ويجمع أزرار تقييم الحالة.
class _CouponActionBar extends StatelessWidget {
  final List<Widget> children;

  const _CouponActionBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'هل الكوبون يعمل ؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Constants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                children[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// أزرار تقييم الكوبون: نعم يعمل / لا يعمل، وتسجل بلاغًا مفصلًا في قاعدة البيانات.
class _StatusActions extends StatefulWidget {
  final String couponId;
  final bool initialIsActive;

  const _StatusActions({
    required this.couponId,
    required this.initialIsActive,
  });

  @override
  State<_StatusActions> createState() => _StatusActionsState();
}

// حالة تقييم الكوبون: تتحكم في اختيار المستخدم وتسجيل البلاغ أثناء التحديث.
class _StatusActionsState extends State<_StatusActions> {
  late bool? _selectedStatus = widget.initialIsActive;
  bool _busy = false;

  Future<void> _submitStatusReport(bool value) async {
    if (_busy || _selectedStatus == value) return;

    final previousStatus = _selectedStatus;
    setState(() {
      _selectedStatus = value;
      _busy = true;
    });
    try {
      final sb = Supabase.instance.client;
      await _saveStatusReport(sb, value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              value ? 'تم تسجيل أن الكوبون يعمل' : 'تم تسجيل بلاغ لا يعمل'),
          backgroundColor: value ? Colors.green : const Color(0xFFE11D48),
        ),
      );
    } catch (error) {
      debugPrint('Coupon status report failed: $error');
      if (!mounted) return;
      setState(() => _selectedStatus = previousStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل تقييم الكوبون: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveStatusReport(SupabaseClient sb, bool value) async {
    final userId = sb.auth.currentUser?.id;
    try {
      await sb.from('coupon_status_reports').insert({
        'coupon_id': widget.couponId,
        'user_id': userId,
        'status': value ? 'working' : 'not_working',
      });
      return;
    } catch (error) {
      debugPrint(
          'coupon_status_reports insert failed, using analytics_events: $error');
    }

    await sb.from('analytics_events').insert({
      'event_type':
          value ? 'coupon_status_working' : 'coupon_status_not_working',
      'item_type': 'coupon',
      'item_id': widget.couponId,
      'user_id': userId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusIcon(
          assetPath: 'assets/icon/like.png',
          label: 'فعال',
          text: 'نعم يعمل',
          color: Colors.green,
          inactiveColor: Constants.primaryColor,
          selected: _selectedStatus == true,
          busy: _busy,
          onTap: () => _submitStatusReport(true),
        ),
        const SizedBox(width: 12),
        _StatusIcon(
          assetPath: 'assets/icon/nolike.png',
          label: 'غير فعال',
          text: 'لا يعمل',
          color: const Color(0xFFE11D48),
          inactiveColor: Constants.primaryColor,
          selected: _selectedStatus == false,
          busy: _busy,
          onTap: () => _submitStatusReport(false),
        ),
      ],
    );
  }
}

// أيقونة حالة الكوبون: تمثل خيارًا واحدًا مثل "فعال" أو "غير فعال".
class _StatusIcon extends StatelessWidget {
  final String assetPath;
  final String label;
  final String text;
  final Color color;
  final Color? inactiveColor;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  const _StatusIcon({
    required this.assetPath,
    required this.label,
    required this.text,
    required this.color,
    this.inactiveColor,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? color : inactiveColor ?? color;
    final baseColor = selected ? color : inactiveColor ?? color;

    return Tooltip(
      message: label,
      child: SizedBox(
        width: 104,
        height: 42,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          shadowColor: color.withValues(alpha: selected ? 0.18 : 0.08),
          elevation: selected ? 3 : 1,
          child: InkWell(
            onTap: busy ? null : onTap,
            borderRadius: BorderRadius.circular(13),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: selected ? 0.10 : 0.03),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: baseColor.withValues(alpha: selected ? 0.30 : 0.12),
                ),
              ),
              child: Center(
                child: busy && selected
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              iconColor,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              assetPath,
                              width: 17,
                              height: 17,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            text,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// لوحة ملخص الكوبون: تعرض نوع الكوبون وقيمته في هيئة صندوق صغير مرتب.
class _CouponSummaryPanel extends StatelessWidget {
  final Coupon coupon;

  const _CouponSummaryPanel({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final title = _typeLabel(coupon.couponType);
    final percent = _discountText(
      coupon.discountPercent,
      showPercent: coupon.couponType != 'extra_discount',
    );
    final valueLabel = percent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              coupon.couponType == 'offer'
                  ? Icons.local_mall_rounded
                  : Icons.percent_rounded,
              color: Constants.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Constants.textColor,
                    ),
                  ),
                ),
                if (valueLabel.trim().isNotEmpty) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (coupon.couponType == 'extra_discount') ...[
                            SvgPicture.asset(
                              'assets/icon/Saudi_Riyal_Symbol-2.svg',
                              width: 13,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            valueLabel,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'cashback':
        return 'رصيد مسترجع';
      case 'offer':
        return 'عرض';
      case 'extra_discount':
        return 'خصم إضافي';
      default:
        return 'كوبون خصم';
    }
  }

  String _discountText(String? value, {bool showPercent = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    return showPercent ? '$text%' : text;
  }
}

// قسم المعلومات: يعرض وصف الكوبون أو شروط الاستخدام بشكل منظم داخل تفاصيله.
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Constants.primaryColor, size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// سطر ميتا: يعرض معلومات إضافية صغيرة مثل آخر استخدام أو تاريخ النشاط.
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool centered;

  const _MetaRow({
    required this.icon,
    required this.text,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 7),
        Flexible(
          fit: centered ? FlexFit.loose : FlexFit.tight,
          child: Text(
            text,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
