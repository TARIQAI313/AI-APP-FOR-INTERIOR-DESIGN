import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reverie/main.dart';
import 'package:reverie/models.dart';
import 'package:reverie/room_view.dart';
import 'package:reverie/theme.dart';

void main() {
  test('Photo format detection rejects disguised non-images', () {
    expect(
      imageMime(Uint8List.fromList([255, 216, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0])),
      'image/jpeg',
    );
    expect(
      imageMime(Uint8List.fromList('<html>bad image</html>'.codeUnits)),
      isNull,
    );
  });
  test('Shopping pins separate an overlapping small item and sofa', () {
    const items = [
      RoomItem(
        id: 'a',
        label: 'Sofa',
        category: 'Furniture',
        query: 'sofa',
        x: .1,
        y: .4,
        width: .8,
        height: .5,
      ),
      RoomItem(
        id: 'b',
        label: 'Vase',
        category: 'Decor',
        query: 'vase',
        x: .45,
        y: .6,
        width: .1,
        height: .1,
      ),
    ];
    final points = pinPositions(items, const Size(360, 270));
    expect((points[0] - points[1]).distance, greaterThanOrEqualTo(38));
    for (final p in points) {
      expect(p.dx, inInclusiveRange(17, 343));
      expect(p.dy, inInclusiveRange(17, 253));
    }
  });
  testWidgets('Urdu setup screen fits a narrow Android viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    urdu.value = true;
    await tester.pumpWidget(
      const ReverieApp(startupError: 'Build with config.json'),
    );
    await tester.pumpAndSettle();
    expect(find.text('reverie.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(urdu.value, isFalse);
    expect(find.text('اردو'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Sign-in and privacy fit a narrow phone in Urdu', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    urdu.value = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        locale: const Locale('ur'),
        supportedLocales: const [Locale('ur'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AuthPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    final privacy = find.text('آپ کی تصاویر اور رازداری');
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
