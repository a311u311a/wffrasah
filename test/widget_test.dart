import 'package:flutter_test/flutter_test.dart';
import 'package:wffrhasah/main.dart';
import 'package:wffrhasah/screens/offers_screen.dart';

void main() {
  testWidgets('Bootstrap error screen renders message', (tester) async {
    const message = 'Configuration missing';

    await tester.pumpWidget(const BootstrapErrorApp(message: message));

    expect(find.text(message), findsOneWidget);
  });

  test('Featured brands include the main e-commerce stores', () {
    expect(
      OffersScreen.featuredStoreSlugs,
      containsAll(['aliexpress', 'temu', 'shein', 'amazon']),
    );
  });
}
