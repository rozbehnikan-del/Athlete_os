import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AthleteOS starts on onboarding and enters app', (tester) async {
    await tester.pumpWidget(const AthleteOSApp());

    expect(find.text('Train.\nProgress.\nCompete.'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text("Today's Workout"), findsOneWidget);
  });
}
