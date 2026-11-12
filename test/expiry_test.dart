import 'package:flutter_test/flutter_test.dart';
import 'package:wffrhasah/utils/expiry.dart';

void main() {
  // Expiry picked in the admin as 2026-11-15 and saved as a plain date.
  final expiry = DateTime.parse('2026-11-15T00:00:00Z');

  test('no expiry date never expires', () {
    expect(isExpiredDate(null), isFalse);
  });

  test('still visible during the last day in Saudi time', () {
    // 23:59 Riyadh on the 15th = 20:59 UTC.
    expect(isExpiredDate(expiry, now: DateTime.utc(2026, 11, 15, 20, 59)),
        isFalse);
  });

  test('hidden once the expiry day ends in Saudi time', () {
    // 00:00 Riyadh on the 16th = 21:00 UTC on the 15th.
    expect(
        isExpiredDate(expiry, now: DateTime.utc(2026, 11, 15, 21)), isTrue);
  });

  test('date picked in the admin round-trips to the same day', () {
    expect(expiryDayToDb(DateTime(2026, 11, 15)), '2026-11-15');
    expect(formatExpiryDay(expiry), '2026-11-15');
  });
}
