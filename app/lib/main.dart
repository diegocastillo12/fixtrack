import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://bmkfeksmxacideyxfhyq.supabase.co',
    ),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_NBH8_frj2rt1El1lR7Irig_Fulp_hlC',
    ),
  );

  // Carga el tema guardado antes de mostrar nada
  await ThemeController.instance.load();

  runApp(const FixTrackApp());
}

class FixTrackApp extends StatefulWidget {
  const FixTrackApp({super.key});

  @override
  State<FixTrackApp> createState() => _FixTrackAppState();
}

class _FixTrackAppState extends State<FixTrackApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixTrack',
      themeMode: ThemeController.instance.mode,
      theme:     AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const SplashPage(),
    );
  }
}