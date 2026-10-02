import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('FixTrack inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const FixTrackApp());

    expect(find.text('Inicia sesión'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });
}