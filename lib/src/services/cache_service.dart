import 'package:path_provider/path_provider.dart';

class CacheService {
  Future<int> clearTemporaryFiles() async {
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      return 0;
    }

    var deletedCount = 0;
    await for (final entity in tempDir.list(recursive: false, followLinks: false)) {
      try {
        await entity.delete(recursive: true);
        deletedCount++;
      } catch (_) {
        // Ignore individual cleanup failures and continue.
      }
    }
    return deletedCount;
  }
}
