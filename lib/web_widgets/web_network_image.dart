import 'dart:async';

import 'package:flutter/material.dart';

/// صورة من الإنترنت للموقع.
///
/// تستخدم Image.network بدل CachedNetworkImage لأن الأخيرة على الويب
/// (CanvasKit) ترسم الصور المحمّلة سابقاً كمربعات سوداء عند إعادة بناء
/// الشبكة (مثلاً بعد اختيار فئة). وتعيد المحاولة تلقائياً إذا فشل التحميل.
class WebNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? error;

  const WebNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.error,
  });

  @override
  State<WebNetworkImage> createState() => _WebNetworkImageState();
}

class _WebNetworkImageState extends State<WebNetworkImage> {
  static const int _maxRetries = 3;
  int _attempt = 0;
  Timer? _retryTimer;

  @override
  void didUpdateWidget(covariant WebNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryTimer?.cancel();
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  String get _urlForAttempt {
    final url = widget.url.trim();
    if (_attempt == 0) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      '_retry': '$_attempt',
    }).toString();
  }

  void _scheduleRetry() {
    if (_attempt >= _maxRetries || _retryTimer?.isActive == true) return;
    final next = _attempt + 1;
    _retryTimer = Timer(Duration(milliseconds: 700 * next), () {
      if (mounted) setState(() => _attempt = next);
    });
  }

  Widget _placeholder(BuildContext context) =>
      widget.placeholder?.call(context) ??
      Container(color: const Color(0xFFF1F0F7));

  @override
  Widget build(BuildContext context) {
    if (widget.url.trim().isEmpty) {
      return widget.error?.call(context) ?? _placeholder(context);
    }
    return Image.network(
      _urlForAttempt,
      key: ValueKey('${widget.url}#$_attempt'),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(context),
      errorBuilder: (context, error, stack) {
        _scheduleRetry();
        if (_attempt < _maxRetries) return _placeholder(context);
        return widget.error?.call(context) ?? _placeholder(context);
      },
    );
  }
}
