import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final String? message;
  final EdgeInsetsGeometry padding;
  final int itemCount;

  const CustomLoadingIndicator({
    super.key,
    this.message,
    this.padding = const EdgeInsets.symmetric(vertical: 34),
    this.itemCount = 3,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.message ?? 'جاري التحميل',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;
          final verticalPadding = widget.padding.vertical;
          final availableHeight = maxHeight.isFinite
              ? (maxHeight - verticalPadding).clamp(0.0, maxHeight)
              : double.infinity;
          const preferredCardHeight = 126.0;
          final hasTightHeight =
              availableHeight.isFinite && availableHeight < preferredCardHeight;

          if (hasTightHeight) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxHeight < 72 ? 0 : 8,
              ),
              child: Center(
                child: _SkeletonMiniCard(
                  animation: _controller,
                  height: availableHeight.clamp(48.0, 74.0),
                ),
              ),
            );
          }

          final gap = 16.0;
          final fitCount = availableHeight.isFinite
              ? ((availableHeight + gap) / (preferredCardHeight + gap)).floor()
              : widget.itemCount;
          final visibleCount = fitCount.clamp(1, widget.itemCount);

          return Padding(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(visibleCount, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == visibleCount - 1 ? 0 : gap,
                  ),
                  child: _SkeletonCard(
                    animation: _controller,
                    compact: index == 0 && visibleCount > 2,
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonMiniCard extends StatelessWidget {
  final Animation<double> animation;
  final double height;

  const _SkeletonMiniCard({
    required this.animation,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E8ED)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _SkeletonBlock(
              animation: animation,
              width: 44,
              height: 44,
              borderRadius: 15,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SkeletonBlock(
                animation: animation,
                width: double.infinity,
                height: 14,
                borderRadius: 999,
              ),
            ),
            const SizedBox(width: 42),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Animation<double> animation;
  final bool compact;

  const _SkeletonCard({
    required this.animation,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardHeight = compact ? 86.0 : 126.0;
    final imageSize = compact ? 58.0 : 76.0;
    final horizontalPadding = width < 380 ? 14.0 : 18.0;

    return Container(
      width: double.infinity,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E8ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1F2430),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _SkeletonBlock(
              animation: animation,
              width: imageSize,
              height: imageSize,
              borderRadius: compact ? 18 : 20,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _SkeletonBlock(
                      animation: animation,
                      width: compact ? 112 : 132,
                      height: compact ? 16 : 14,
                      borderRadius: 999,
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),
                  _SkeletonBlock(
                    animation: animation,
                    width: double.infinity,
                    height: compact ? 13 : 14,
                    borderRadius: 999,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 10),
                    FractionallySizedBox(
                      widthFactor: 0.82,
                      alignment: Alignment.centerRight,
                      child: _SkeletonBlock(
                        animation: animation,
                        width: double.infinity,
                        height: 14,
                        borderRadius: 999,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final Animation<double> animation;
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBlock({
    required this.animation,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              stops: const [0.12, 0.46, 0.82],
              colors: const [
                Color(0xFFE1E3E8),
                Color(0xFFF7F8FA),
                Color(0xFFE1E3E8),
              ],
              transform: _SlidingGradientTransform(animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double value;

  const _SlidingGradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (2 * value - 1), 0, 0);
  }
}
