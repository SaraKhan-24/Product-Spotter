import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:product_spotter/main.dart';

void main() {
  testWidgets('Smoke test for ProductSpotterApp', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProductSpotterApp());

    // Verify that our app starts and displays the header.
    expect(find.text('Snap & Recognize Products'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });
}

