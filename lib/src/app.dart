import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/app_theme_settings.dart';
import 'pdf_crop_app.dart';
import 'state/theme_controller.dart';

class ProCropperPdfApp extends StatelessWidget {
  const ProCropperPdfApp({
    required this.themeController,
    this.initialPdfPath,
    super.key,
  });

  final ThemeController themeController;
  final String? initialPdfPath;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'ProCropper PDF',
          locale: themeController.appLocale,
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return const Locale('en');
            }
            if (locale.languageCode.toLowerCase().startsWith('zh')) {
              return const Locale('zh', 'CN');
            }
            return const Locale('en');
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
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
          home: PdfCropApp(
            themeController: themeController,
            initialPdfPath: initialPdfPath,
          ),
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
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamilyFallback: const ['Microsoft YaHei', 'PingFang SC', 'Noto Sans CJK SC'],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
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
