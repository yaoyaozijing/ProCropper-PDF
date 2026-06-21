import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import '../models/app_theme_settings.dart';

class WindowEffectService {
  WindowEffectService._();

  static final WindowEffectService instance = WindowEffectService._();

  bool _initialized = false;
  WindowEffect? _lastEffect;
  bool? _lastDark;

  Future<void> initializeIfNeeded() async {
    if (!Platform.isWindows || _initialized) {
      return;
    }
    await Window.initialize();
    _initialized = true;
  }

  Future<void> sync(
    AppThemeSettings settings, {
    required Brightness platformBrightness,
  }) async {
    if (!Platform.isWindows) {
      return;
    }
    await initializeIfNeeded();

    final effectiveBrightness = switch (settings.themeMode) {
      AppThemeMode.system => platformBrightness,
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
    };
    final eInkActive =
        settings.eInkOptimized && effectiveBrightness == Brightness.light;
    final wantsMica = settings.windowsMicaEnabled && !eInkActive;
    final effect = wantsMica ? WindowEffect.tabbed : WindowEffect.disabled;
    final dark = effectiveBrightness == Brightness.dark;

    if (_lastEffect == effect && _lastDark == dark) {
      return;
    }

    try {
      if (wantsMica) {
        await Window.setEffect(
          effect: WindowEffect.tabbed,
          dark: dark,
        );
      } else {
        await Window.setEffect(effect: WindowEffect.disabled);
      }
    } catch (_) {
      try {
        await Window.setEffect(effect: WindowEffect.disabled);
      } catch (_) {}
    }

    _lastEffect = effect;
    _lastDark = dark;
  }
}
