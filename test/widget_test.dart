import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:machine_learning_flutter_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyApp()));
  }, skip: 'Requires Firebase + TFLite assets/config to be available in tests.');
}
