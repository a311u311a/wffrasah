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

class WebCouponCard extends StatefulWidget {
  final Coupon coupon;
  final String? storeName;
  final bool compact;

  const WebCouponCard({
    super.key,
    required this.coupon,
    this.storeName,
    this.compact = false,
  });

  @override
  State<WebCouponCard> createState() => _WebCouponCardState();
}

class _WebCouponCardState extends State<WebCouponCard> {
  bool _hovered = false;
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

  String get _imageUrl {
    final storeImage = widget.coupon.storeImage.trim();
    if (storeImage.isNotEmpty) return storeImage;
    return widget.coupon.image;
  }

  String get _discountLabel {
    return widget.coupon.discountPercent?.trim() ?? '';
  }

  String get _ticketTitle {
    switch (widget.coupon.couponType) {
      case 'cashback':
        return 'رصيد';
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
    } catch (_) {}
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
    showDialog(
      context: context,
      builder: (context) => _WebCouponDetailsDialog(
        coupon: widget.coupon,
        storeName: _storeName,
        imageUrl: _imageUrl,
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
    final cardHeight = widget.compact ? 136.0 : 156.0;
    final contentPadding = widget.compact
        ? const EdgeInsets.fromLTRB(138, 12, 14, 12)
        : const EdgeInsets.fromLTRB(144, 16, 16, 16);
    final logoSize = widget.compact ? 58.0 : 66.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: cardHeight,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDE9FE)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D5DF6)
                  .withValues(alpha: _hovered ? 0.16 : 0.08),
              blurRadius: _hovered ? 24 : 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openDetails,
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: contentPadding,
                  child: Row(
                    children: [
                      _StoreImage(imageUrl: _imageUrl, size: logoSize),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF25213B),
                                height: 1.15,
                              ),
                            ),
                            if (widget.coupon.description.trim().isNotEmpty)
                              const SizedBox(height: 8),
                            if (widget.coupon.description.trim().isNotEmpty)
                              Text(
                                widget.coupon.description.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7B7492),
                                  height: 1.25,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_left_rounded,
                        color: Constants.primaryColor.withValues(alpha: 0.55),
                        size: 28,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
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
    );
  }
}

class _WebCouponDetailsDialog extends StatefulWidget {
  final Coupon coupon;
  final String storeName;
  final String imageUrl;
  final bool isCopied;
  final bool isFollowing;
  final bool followBusy;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onShop;
  final Future<bool?> Function() onToggleFollow;

  const _WebCouponDetailsDialog({
    required this.coupon,
    required this.storeName,
    required this.imageUrl,
    required this.isCopied,
    required this.isFollowing,
    required this.followBusy,
    required this.onCopy,
    required this.onShare,
    required this.onShop,
    required this.onToggleFollow,
  });

  @override
  State<_WebCouponDetailsDialog> createState() =>
      _WebCouponDetailsDialogState();
}

class _WebCouponDetailsDialogState extends State<_WebCouponDetailsDialog> {
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 28, 30, 46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _StoreImage(imageUrl: widget.imageUrl, size: 100),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Text(
                        widget.storeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 118,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _followBusy ? null : _toggleFollow,
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
                                _isFollowing ? 'متابَع' : 'متابعة',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CircleAction(
                                icon: Icons.share_rounded,
                                onTap: widget.onShare,
                              ),
                              _CircleAction(
                                onTap: () => favoriteProvider.toggleFavorite(
                                    widget.coupon, context),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: isFavorite
                                      ? const _FavoriteStarIcon(
                                          key: ValueKey('fav_active'),
                                          active: true,
                                          size: 26,
                                        )
                                      : const _FavoriteStarIcon(
                                          key: ValueKey('fav_inactive'),
                                          active: false,
                                          size: 26,
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
                const SizedBox(height: 22),
                _CouponActionBar(
                  children: [
                    _StatusActions(
                      couponId: widget.coupon.id,
                      initialIsActive: widget.coupon.isActive,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                if (widget.coupon.description.trim().isNotEmpty)
                  _InfoSection(title: 'الوصف', body: widget.coupon.description),
                if (widget.coupon.terms.trim().isNotEmpty)
                  _InfoSection(
                      title: 'شروط الاستخدام', body: widget.coupon.terms),
                _MetaRow(
                  icon: Icons.history_rounded,
                  text: _lastUsedText(widget.coupon.lastUsedAt),
                ),
                const SizedBox(height: 22),
                if (widget.coupon.code.trim().isNotEmpty) ...[
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: _LegacyCopyButton(
                        code: widget.coupon.code,
                        initialCopied: widget.isCopied,
                        onCopy: widget.onCopy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
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
                const SizedBox(height: 26),
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
                                    'نسخ الكود',
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

class _StoreImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _StoreImage({
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: Constants.primaryColor.withValues(alpha: 0.07),
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
        width: 118,
        height: 108,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final separatorY = constraints.maxHeight * 0.68;

            return Stack(
              children: [
                Positioned(
                  left: 13,
                  right: 13,
                  top: 12,
                  height: separatorY - 16,
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontSize: title.length > 4 ? 12 : 16,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: separatorY + 5,
                  bottom: 8,
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
                                  width: 30,
                                  height: 35,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (title != 'عرض' && title != 'خصم إضافي')
                              const Text(
                                '%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Tajawal',
                                  fontSize: 38,
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

class _TicketBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFA78BFA),
          Color(0xFF6D5DF6),
        ],
      ).createShader(rect);

    canvas.drawRRect(r, paint);

    final notchPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = const Color(0xFF7C6BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRRect(r.deflate(0.7), borderPaint);

    final dashPaint = Paint()
      ..color = const Color(0xFF5F52DE).withValues(alpha: 0.45)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const notchRadius = 8.0;
    canvas.drawCircle(Offset(0, size.height * 0.68), notchRadius, notchPaint);
    canvas.drawCircle(
        Offset(size.width, size.height * 0.68), notchRadius, notchPaint);

    const dashWidth = 4.0;
    const dashGap = 5.0;
    final y = size.height * 0.68;
    var x = 17.0;
    while (x < size.width - 17) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), dashPaint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

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
      width: 48,
      height: 48,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Constants.primaryColor.withValues(alpha: 0.12),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.18),
              ),
            ),
            child: Center(
              child:
                  child ?? Icon(icon, color: Constants.primaryColor, size: 26),
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

class _CouponActionBar extends StatelessWidget {
  final List<Widget> children;

  const _CouponActionBar({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Constants.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                children[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

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
        width: 112,
        height: 46,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          shadowColor: color.withValues(alpha: selected ? 0.18 : 0.08),
          elevation: selected ? 3 : 1,
          child: InkWell(
            onTap: busy ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: selected ? 0.10 : 0.03),
                borderRadius: BorderRadius.circular(14),
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
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            text,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
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

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
