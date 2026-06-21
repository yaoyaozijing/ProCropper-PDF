import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/app_theme_settings.dart';
import 'pdf_crop_app.dart';
import 'services/window_effect_service.dart';
import 'services/windowing_service.dart';
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
        final platformBrightness =
            View.of(context).platformDispatcher.platformBrightness;
        final materialThemeMode = themeController.materialThemeMode;
        final effectiveBrightness = switch (materialThemeMode) {
          ThemeMode.system => platformBrightness,
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
        };
        _scheduleWindowEffectSync(
          settings: themeController.settings,
          platformBrightness: platformBrightness,
        );
        return wrapWithWindowManager(
          MaterialApp(
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
            themeAnimationDuration: _disableThemeAnimations(themeController)
                ? Duration.zero
                : kThemeAnimationDuration,
            themeAnimationCurve: Curves.linear,
            themeMode: themeController.materialThemeMode,
            theme: _buildTheme(
              brightness: Brightness.light,
              settings: themeController.settings,
            ),
            darkTheme: _buildTheme(
              brightness: Brightness.dark,
              settings: themeController.settings,
            ),
            builder: (context, child) {
              final content = child ?? const SizedBox.shrink();
              if (!Platform.isMacOS) {
                return _wrapWindowsMicaSurface(
                  content: content,
                  settings: themeController.settings,
                  effectiveBrightness: effectiveBrightness,
                );
              }
              final mediaQuery = MediaQuery.of(context);
              final topInset = math.max(28.0, mediaQuery.viewPadding.top);
              final macosContent = MediaQuery(
                data: mediaQuery.copyWith(
                  padding: EdgeInsets.fromLTRB(
                    mediaQuery.padding.left,
                    topInset,
                    mediaQuery.padding.right,
                    mediaQuery.padding.bottom,
                  ),
                  viewPadding: EdgeInsets.fromLTRB(
                    mediaQuery.viewPadding.left,
                    topInset,
                    mediaQuery.viewPadding.right,
                    mediaQuery.viewPadding.bottom,
                  ),
                ),
                child: content,
              );
              return _wrapWindowsMicaSurface(
                content: macosContent,
                settings: themeController.settings,
                effectiveBrightness: effectiveBrightness,
              );
            },
            home: PdfCropApp(
              themeController: themeController,
              initialPdfPath: initialPdfPath,
            ),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required AppThemeSettings settings,
  }) {
    final eInkOptimized =
        brightness == Brightness.light && settings.eInkOptimized;
    final seedColor = eInkOptimized
        ? Colors.black
        : _resolveSeedColor(settings.accentMode, brightness);
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final oledOptimized =
        brightness == Brightness.dark && settings.oledOptimized;
    final windowsMicaActive =
        Platform.isWindows &&
        settings.windowsMicaEnabled &&
        !(brightness == Brightness.light && settings.eInkOptimized);
    final colorScheme = eInkOptimized
        ? baseColorScheme.copyWith(
            primary: Colors.black,
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFFF2F2F2),
            onPrimaryContainer: Colors.black,
            secondary: Colors.black,
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFCCCCCC),
            onSecondaryContainer: Colors.black,
            tertiary: Colors.black,
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFAAAAAA),
            onTertiaryContainer: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
            surfaceDim: Colors.white,
            surfaceBright: Colors.white,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: Colors.white,
            surfaceContainer: const Color(0xFFF8F8F8),
            surfaceContainerHigh: const Color(0xFFF2F2F2),
            surfaceContainerHighest: const Color(0xFFEDEDED),
            onSurfaceVariant: Colors.black87,
            outline: Colors.black54,
            outlineVariant: Colors.black26,
            shadow: Colors.black,
            scrim: Colors.black,
          )
        : oledOptimized
        ? baseColorScheme.copyWith(
            surface: const Color(0xFF000000),
            surfaceDim: const Color(0xFF000000),
            surfaceBright: const Color(0xFF141414),
            surfaceContainerLowest: const Color(0xFF000000),
            surfaceContainerLow: const Color(0xFF050505),
            surfaceContainer: const Color(0xFF090909),
            surfaceContainerHigh: const Color(0xFF101010),
            surfaceContainerHighest: const Color(0xFF181818),
          )
        : windowsMicaActive
        ? baseColorScheme.copyWith(
            surface: Colors.transparent,
            surfaceDim: const Color(0x00FFFFFF),
            surfaceBright: const Color(0x00FFFFFF),
            surfaceContainerLowest: Colors.transparent,
            surfaceContainerLow: _micaTint(brightness, 0.54),
            surfaceContainer: _micaTint(brightness, 0.64),
            surfaceContainerHigh: _micaTint(brightness, 0.74),
            surfaceContainerHighest: _micaTint(brightness, 0.82),
          )
        : baseColorScheme;
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: windowsMicaActive
          ? Colors.transparent
          : colorScheme.surface,
      canvasColor: windowsMicaActive ? Colors.transparent : colorScheme.surface,
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll<Color>(
            colorScheme.surfaceContainerLow,
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
        ),
      ),
      fontFamilyFallback: const [
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans CJK SC',
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      pageTransitionsTheme: _disableThemeAnimationsForSettings(
        settings,
        brightness,
      )
          ? const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
                TargetPlatform.fuchsia: _NoAnimationPageTransitionsBuilder(),
              },
            )
          : const PageTransitionsTheme(),
    );
  }

  bool _disableThemeAnimations(ThemeController controller) {
    final mode = controller.settings.themeMode;
    return controller.settings.eInkOptimized &&
        mode != AppThemeMode.dark;
  }

  bool _disableThemeAnimationsForSettings(
    AppThemeSettings settings,
    Brightness brightness,
  ) {
    return settings.eInkOptimized && brightness == Brightness.light;
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

  void _scheduleWindowEffectSync({
    required AppThemeSettings settings,
    required Brightness platformBrightness,
  }) {
    if (!Platform.isWindows) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WindowEffectService.instance.sync(
        settings,
        platformBrightness: platformBrightness,
      );
    });
  }

  Widget _wrapWindowsMicaSurface({
    required Widget content,
    required AppThemeSettings settings,
    required Brightness effectiveBrightness,
  }) {
    final micaActive =
        Platform.isWindows &&
        settings.windowsMicaEnabled &&
        !(settings.eInkOptimized && effectiveBrightness == Brightness.light);
    if (!micaActive) {
      return content;
    }
    final overlayColor = effectiveBrightness == Brightness.dark
        ? const Color(0x66101010)
        : const Color(0x33FFFFFF);
    return ColoredBox(
      color: overlayColor,
      child: content,
    );
  }

  Color _micaTint(Brightness brightness, double opacity) {
    final base = brightness == Brightness.dark
        ? const Color(0xFF181818)
        : const Color(0xFFF7F7F7);
    return base.withValues(alpha: opacity);
  }
}

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
