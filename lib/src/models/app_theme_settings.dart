import 'package:flutter/material.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

enum AppStyleMode {
  material,
  cupertino,
  fluent,
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
    this.styleMode = AppStyleMode.material,
    this.accentMode = AppAccentMode.system,
    this.oledOptimized = false,
  });

  final AppThemeMode themeMode;
  final AppStyleMode styleMode;
  final AppAccentMode accentMode;
  final bool oledOptimized;

  AppThemeSettings copyWith({
    AppThemeMode? themeMode,
    AppStyleMode? styleMode,
    AppAccentMode? accentMode,
    bool? oledOptimized,
  }) {
    return AppThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      styleMode: styleMode ?? this.styleMode,
      accentMode: accentMode ?? this.accentMode,
      oledOptimized: oledOptimized ?? this.oledOptimized,
    );
  }
}
