import 'package:flutter/material.dart';

import '../constants.dart';

class SavingsCalculator extends StatefulWidget {
  final String? discountPercent;
  final String couponType;

  const SavingsCalculator({
    super.key,
    required this.discountPercent,
    required this.couponType,
  });

  @override
  State<SavingsCalculator> createState() => _SavingsCalculatorState();
}

class _SavingsCalculatorState extends State<SavingsCalculator> {
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? get _discountValue {
    final text = _normalizeDigits(widget.discountPercent ?? '')
        .replaceAll(',', '.')
        .trim();
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(text);
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  @override
  Widget build(BuildContext context) {
    final discount = _discountValue;
    final amount = double.tryParse(
      _normalizeDigits(_amountController.text).replaceAll(',', '.').trim(),
    );
    final isFixed = widget.couponType == 'extra_discount';
    final saving = discount == null || amount == null || amount <= 0
        ? null
        : (isFixed ? discount : amount * discount / 100).clamp(0, amount);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _amountFocusNode.unfocus(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Constants.primaryColor.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Constants.primaryColor.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_rounded, color: Constants.primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'احسب التوفير المتوقع',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (discount != null)
                  Text(
                    isFixed ? '$discount ر.س' : '$discount%',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Constants.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _amountFocusNode.unfocus(),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'قيمة السلة بالريال',
                      suffixText: 'ر.س',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_amountFocusNode.hasFocus) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _amountFocusNode.unfocus(),
                    icon: const Icon(Icons.keyboard_hide_rounded, size: 18),
                    label: const Text('تم'),
                    style: TextButton.styleFrom(
                      foregroundColor: Constants.primaryColor,
                      textStyle: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            if (saving != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('التوفير المتوقع',
                      style: TextStyle(fontFamily: 'Tajawal')),
                  Text(
                    '${saving.toStringAsFixed(2)} ر.س',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF168447),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            const Text(
              'تقدير تقريبي إذا شمل الخصم جميع منتجات السلة.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: Color(0xFF817A96),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      final arabicIndex = arabic.indexOf(char);
      final persianIndex = persian.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
      } else if (persianIndex >= 0) {
        buffer.write(persianIndex);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
