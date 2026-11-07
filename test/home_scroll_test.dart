import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wffrhasah/screens/home_screen.dart';
import 'package:wffrhasah/widgets/carouse.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://scroll-test.invalid',
      publishableKey: 'test-key',
      authOptions: FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('home keeps async sections mounted while scrolling back',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump();

    final carouselState = tester.state(find.byType(CustomCarousel));
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final position = scrollable.position;
    expect(position.maxScrollExtent, greaterThan(0));
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();

    expect(carouselState.mounted, isTrue,
        reason: 'Offscreen sections must not restart their async loads.');
    final bottomOffset = position.pixels;
    await tester.dragFrom(const Offset(210, 220), const Offset(0, 90));
    await tester.pump(const Duration(milliseconds: 100));
    expect(position.pixels, lessThan(bottomOffset));

    position.jumpTo(0);
    await tester.pump();
    expect(tester.state(find.byType(CustomCarousel)), same(carouselState));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    // Supabase delays disconnecting the last realtime channel by 50 seconds.
    await tester.pump(const Duration(seconds: 60));
  });
}
