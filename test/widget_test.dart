import 'package:bookslane_app/features/splash/presentation/pages/splash_page.dart';
import 'package:bookslane_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the app boots into the splash screen', (tester) async {
    await tester.pumpWidget(const BooksLane());
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text('Your book, your business'), findsOneWidget);

    // The splash routes on a timer; let it fire so the test doesn't end with a
    // pending timer.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
