import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.create();
  runApp(BrissFlutterApp(themeController: themeController));
}
