import 'package:flutter_test/flutter_test.dart';
import 'package:wffrhasah/main.dart';

void main() {
  testWidgets('Bootstrap error screen renders message', (tester) async {
    const message = 'Configuration missing';

    await tester.pumpWidget(const BootstrapErrorApp(message: message));

    expect(find.text(message), findsOneWidget);
  });
}
