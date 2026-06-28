import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/game_theme_model.dart';
import 'services/admob_service.dart';
import 'services/theme_manager.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdmobService.instance.initialize();
  final ThemeManager themeManager = ThemeManager();
  await themeManager.load();
  runApp(MyApp(themeManager: themeManager));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeManager});

  final ThemeManager themeManager;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>.value(
      value: themeManager,
      child: MaterialApp(
        title: 'Block Puzzle',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF55D6FF),
            onPrimary: Color(0xFF03223E),
            secondary: Color(0xFF7CF7B8),
            onSecondary: Color(0xFF032C20),
            surface: Color(0xCC081A3F),
            onSurface: Color(0xFFF3F8FF),
            error: Color(0xFFE53935),
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFFF3F8FF),
            elevation: 0,
            centerTitle: false,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: GameThemeCatalog.classic.panelColor,
            contentTextStyle: const TextStyle(
              color: Color(0xFFF3F8FF),
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: GameThemeCatalog.classic.panelBorderColor,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          dividerTheme: const DividerThemeData(color: Color(0x443FA3F7)),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2458FF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF5A6B95),
              disabledForegroundColor: const Color(0xFFE8EDFF),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
