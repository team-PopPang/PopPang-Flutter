import 'package:flutter_test/flutter_test.dart';

import 'package:poppang_flutter/main_demo.dart';

void main() {
  testWidgets('demo entry renders module shell', (WidgetTester tester) async {
    await tester.pumpWidget(const PopPangDemoApp());

    expect(find.text('Demo Mode'), findsOneWidget);
    expect(find.text('PopPang Flutter Module'), findsOneWidget);
    expect(
      find.text('This default entry point boots the module in demo mode.'),
      findsOneWidget,
    );
  });
}
