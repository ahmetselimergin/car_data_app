import 'package:car_data_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CarDataApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Araçlarım'), findsWidgets);
  });
}
