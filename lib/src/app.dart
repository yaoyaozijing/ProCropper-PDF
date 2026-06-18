import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';

import 'models/app_theme_settings.dart';
import 'pdf_crop_app.dart';
import 'state/theme_controller.dart';

class BrissFlutterApp extends StatelessWidget {
  const BrissFlutterApp({
    required this.themeController,
    super.key,
  });

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Briss',
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeController.materialThemeMode,
          theme: _buildTheme(
            brightness: Brightness.light,
            settings: themeController.settings,
          ),
          darkTheme: _buildTheme(
            brightness: Brightness.dark,
            settings: themeController.settings,
          ),
          home: PdfCropApp(themeController: themeController),
        );
      },
    );
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeSettings settings,
  }) {
    final seedColor = _resolveSeedColor(settings.accentMode, brightness);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final isOled = settings.oledOptimized && brightness == Brightness.dark;
    final tintedSurface = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.05),
      colorScheme.surface,
    );
    final tintedCardSurface = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: 0.03),
      colorScheme.surfaceContainerLow,
    );
    final scaffoldColor = isOled
        ? Colors.black
        : tintedSurface;
    final cardColor = isOled
        ? const Color(0xFF050505)
        : tintedCardSurface;

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: settings.styleMode == AppStyleMode.material,
      scaffoldBackgroundColor: scaffoldColor,
      canvasColor: scaffoldColor,
      cardColor: cardColor,
      dividerColor: colorScheme.outlineVariant,
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isOled ? const Color(0xFF101010) : colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isOled ? const Color(0xFF090909) : colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'Noto Sans CJK SC'],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colorScheme.primary,
        barBackgroundColor: scaffoldColor,
        scaffoldBackgroundColor: scaffoldColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: colorScheme.primary,
          textStyle: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: settings.styleMode == AppStyleMode.cupertino
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
            : null,
        iconColor: settings.styleMode == AppStyleMode.cupertino ? colorScheme.primary : null,
      ),
    );
  }

  Color _resolveSeedColor(AppAccentMode accentMode, Brightness brightness) {
    switch (accentMode) {
      case AppAccentMode.system:
        return brightness == Brightness.dark ? const Color(0xFF7BC4B3) : const Color(0xFF0E6B5C);
      case AppAccentMode.jade:
        return const Color(0xFF0E6B5C);
      case AppAccentMode.amber:
        return const Color(0xFF9A6A14);
      case AppAccentMode.ocean:
        return const Color(0xFF0B6E8A);
      case AppAccentMode.coral:
        return const Color(0xFFB85C38);
      case AppAccentMode.ruby:
        return const Color(0xFF9F2F4F);
      case AppAccentMode.graphite:
        return const Color(0xFF4A5568);
    }
  }
}
