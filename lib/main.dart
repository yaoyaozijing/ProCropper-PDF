import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/state/theme_controller.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(
      windowOptions,
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  final initialPdfPath = _resolveInitialPdfPath(args);
  final themeController = await ThemeController.create();
  runApp(
    ProCropperPdfApp(
      themeController: themeController,
      initialPdfPath: initialPdfPath,
    ),
  );
}

String? _resolveInitialPdfPath(List<String> args) {
  for (final arg in args) {
    if (arg.toLowerCase().endsWith('.pdf')) {
      return arg;
    }
  }
  return null;
}
