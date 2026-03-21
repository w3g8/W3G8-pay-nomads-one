import 'package:flutter_test/flutter_test.dart';
import 'package:nomads_wallet/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NomadsApp());
    expect(find.text('Sign In'), findsAny);
  });
}
