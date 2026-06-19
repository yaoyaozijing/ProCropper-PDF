import 'dart:io';

import 'package:flutter/services.dart';

class AndroidIncomingPdfService {
  static const MethodChannel _channel =
      MethodChannel('procropper_pdf/android_incoming_pdf');

  Future<void> bind({
    required Future<void> Function(String path) onIncomingPdf,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'incomingPdfPath') {
        return;
      }
      final path = call.arguments as String?;
      if (path == null || path.isEmpty) {
        return;
      }
      await onIncomingPdf(path);
    });

    final initialPath =
        await _channel.invokeMethod<String>('getInitialIncomingPdfPath');
    if (initialPath == null || initialPath.isEmpty) {
      return;
    }
    await onIncomingPdf(initialPath);
  }

  Future<void> unbind() async {
    if (!Platform.isAndroid) {
      return;
    }
    _channel.setMethodCallHandler(null);
  }
}
