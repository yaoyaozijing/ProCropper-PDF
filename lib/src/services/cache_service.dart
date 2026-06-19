import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CacheService {
  static const String exportCacheDirectoryName = 'procropper_pdf_exports';

  Future<Directory> getExportCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(
      p.join(tempDir.path, exportCacheDirectoryName),
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  Future<int> clearTemporaryFiles() async {
    final exportDir = await getExportCacheDirectory();
    if (!await exportDir.exists()) {
      return 0;
    }

    var deletedCount = 0;
    await for (final entity in exportDir.list(recursive: false, followLinks: false)) {
      try {
        await entity.delete(recursive: true);
        deletedCount++;
      } catch (_) {
        // Ignore individual cleanup failures and continue.
      }
    }
    return deletedCount;
  }

  Future<void> deleteTemporaryFile(String path) async {
    if (!await isManagedTemporaryFile(path)) {
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      return;
    }
    await file.delete();
  }

  Future<bool> isManagedTemporaryFile(String path) async {
    final exportDir = await getExportCacheDirectory();
    final normalizedDirectory = p.normalize(exportDir.path);
    final normalizedPath = p.normalize(path);
    return normalizedPath == normalizedDirectory ||
        p.isWithin(normalizedDirectory, normalizedPath);
  }
}
