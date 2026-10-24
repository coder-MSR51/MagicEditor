import 'package:flutter_test/flutter_test.dart';
import 'package:photo_magic/main.dart';

void main() {
  testWidgets('PhotoMagicApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoMagicApp());
    expect(find.text('PHOTO MAGIC'), findsOneWidget);
  });
}
