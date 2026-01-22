import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';

class SearchWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onSearch;

  const SearchWidget({
    super.key,
    required this.hintText,
    required this.onSearch,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      widget.onSearch(query.trim());
    });
    setState(() {}); // لتحديث ظهور زر المسح
  }

  void _clear() {
    _searchController.clear();
    widget.onSearch('');
    setState(() {});
  }

  void _cancel() {
    _clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8, top: 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 46, // ✅ ثابت لتجنب الاهتزاز
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFocused
                      ? Constants.primaryColor.withOpacity(0.35)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isFocused ? 0.08 : 0.04),
                    blurRadius: _isFocused ? 16 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,

                // ✅ يخلي النص والهينت في المنتصف تمامًا
                textAlignVertical: TextAlignVertical.center,

                style: TextStyle(
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.0, // ✅ يساعد على تثبيت المحاذاة
                ),

                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.black.withOpacity(0.35),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.0, // ✅ مهم للهينت
                  ),
                  border: InputBorder.none,

                  // ✅ قللي العمودي + زيدي أفقي
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),

                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 4, top: 4, bottom: 4),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: Constants.primaryColor,
                        size: 25,
                      ),
                    ),
                  ),

                  // ✅ تثبيت مقاس الأيقونة بحيث ما يزحزح النص
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 54,
                    minHeight: 46,
                  ),

                  suffixIcon: hasText
                      ? IconButton(
                          onPressed: _clear,
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.black.withOpacity(0.45),
                          ),
                          splashRadius: 18,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // ✅ زر إلغاء يظهر عند التركيز (عصري ومفيد)
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _isFocused
                ? Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: TextButton(
                      onPressed: _cancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Constants.primaryColor,
                        textStyle: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
