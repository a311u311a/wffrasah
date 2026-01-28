import 'package:rbhan/constants.dart';
import 'package:flutter/material.dart';

class TextFieldInput extends StatefulWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final String hintText;
  final TextInputType textInputType;
  final IconData icon;

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.isPass = false,
    required this.hintText,
    required this.textInputType,
    required this.icon,
  });

  @override
  State<TextFieldInput> createState() => _TextFieldInputState();
}

class _TextFieldInputState extends State<TextFieldInput> {
  bool _isObscure = true; // ✅ للتحكم في إظهار/إخفاء النص

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: TextField(
        controller: widget.textEditingController,
        obscureText: widget.isPass
            ? _isObscure
            : false, // ✅ تفعيل الإخفاء فقط عند الحاجة
        keyboardType: widget.textInputType,
        decoration: InputDecoration(
          prefixIcon: Icon(widget.icon, color: Constants.primaryColor),
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.primaryColor, width: 2),
          ),
          // ✅ إضافة أيقونة العين لإظهار/إخفاء كلمة المرور
          suffixIcon: widget.isPass
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _isObscure = !_isObscure; // ✅ تبديل حالة الإخفاء/الإظهار
                    });
                  },
                  child: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                    color: Constants.primaryColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
