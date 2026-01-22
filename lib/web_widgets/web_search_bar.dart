import 'package:flutter/material.dart';
import '../constants.dart';

/// شريط البحث البارز للصفحة الرئيسية
class WebSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final String? hintText;

  const WebSearchBar({
    super.key,
    this.onSearch,
    this.hintText,
  });

  @override
  State<WebSearchBar> createState() => _WebSearchBarState();
}

class _WebSearchBarState extends State<WebSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
      child: TextField(
        controller: _controller,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'ابحث عن الكوبونات والمتاجر...',
          hintStyle: TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Constants.primaryColor,
            size: 24,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Constants.primaryColor, width: 2),
          ),
        ),
        onSubmitted: (value) {
          if (widget.onSearch != null && value.isNotEmpty) {
            widget.onSearch!(value);
          }
        },
      ),
    );
  }
}
