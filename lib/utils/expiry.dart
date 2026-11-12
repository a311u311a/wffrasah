import 'package:flutter/material.dart';

/// Expiry rule shared by coupons, offers and banners.
///
/// An item stays visible until the END of its expiry day in Saudi time
/// (UTC+3, no daylight saving) and is hidden after that. Items without an
/// expiry date never expire. Matches `public.is_not_expired` in
/// hide_expired_content_rls.sql.
const Duration _riyadhOffset = Duration(hours: 3);

bool isExpiredDate(DateTime? expiry, {DateTime? now}) {
  if (expiry == null) return false;
  final riyadh = expiry.toUtc().add(_riyadhOffset);
  final endOfDayUtc = DateTime.utc(riyadh.year, riyadh.month, riyadh.day + 1)
      .subtract(_riyadhOffset);
  return !(now ?? DateTime.now()).toUtc().isBefore(endOfDayUtc);
}

DateTime? parseExpiryDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

/// Saudi calendar day of an expiry date, as yyyy-MM-dd.
String formatExpiryDay(DateTime expiry) {
  final riyadh = expiry.toUtc().add(_riyadhOffset);
  return '${riyadh.year}-${riyadh.month.toString().padLeft(2, '0')}-'
      '${riyadh.day.toString().padLeft(2, '0')}';
}

/// Value to save in an `expiry_date` column for a day picked in the admin.
/// Saved as a plain date, so the database reads it as that calendar day.
String? expiryDayToDb(DateTime? day) {
  if (day == null) return null;
  return '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

/// Small red "منتهي" badge for admin lists.
class ExpiredBadge extends StatelessWidget {
  const ExpiredBadge({super.key, this.label = 'منتهي'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Optional expiry-day picker used in the banner admin forms.
class ExpiryDayField extends StatelessWidget {
  const ExpiryDayField({
    super.key,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final current = value;
    final text = current == null
        ? 'تاريخ الانتهاء (اختياري)'
        : 'ينتهي بنهاية يوم ${expiryDayToDb(current)}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: current == null ? Colors.black54 : Colors.black87,
                ),
              ),
            ),
            if (current != null)
              IconButton(
                tooltip: 'إزالة التاريخ',
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: () => onChanged(null),
              )
            else
              const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
