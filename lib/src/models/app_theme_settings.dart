import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

enum AppLanguageMode {
  system,
  zhCn,
  en,
}

enum AppAccentMode {
  system,
  jade,
  amber,
  ocean,
  coral,
  ruby,
  graphite,
}

@immutable
class AppThemeSettings {
  const AppThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.languageMode = AppLanguageMode.system,
    this.accentMode = AppAccentMode.system,
    this.oledOptimized = false,
    this.eInkOptimized = false,
    this.multiWindowMode = false,
    this.windowsMicaEnabled = false,
  });

  final AppThemeMode themeMode;
  final AppLanguageMode languageMode;
  final AppAccentMode accentMode;
  final bool oledOptimized;
  final bool eInkOptimized;
  final bool multiWindowMode;
  final bool windowsMicaEnabled;

  AppThemeSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguageMode? languageMode,
    AppAccentMode? accentMode,
    bool? oledOptimized,
    bool? eInkOptimized,
    bool? multiWindowMode,
    bool? windowsMicaEnabled,
  }) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      languageMode: languageMode ?? this.languageMode,
      accentMode: accentMode ?? this.accentMode,
      oledOptimized: oledOptimized ?? this.oledOptimized,
      eInkOptimized: eInkOptimized ?? this.eInkOptimized,
      multiWindowMode: multiWindowMode ?? this.multiWindowMode,
      windowsMicaEnabled: windowsMicaEnabled ?? this.windowsMicaEnabled,
    );
  }
}
