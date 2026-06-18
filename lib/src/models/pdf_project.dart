import 'package:pdfrx/pdfrx.dart';

import 'cluster_settings.dart';
import 'page_cluster.dart';

class PdfProject {
  PdfProject({
    required this.filePath,
    required this.fileName,
    required this.document,
    required this.clusters,
    required this.pageCount,
    required this.settings,
  });

  final String filePath;
  final String fileName;
  final PdfDocument document;
  final List<PageCluster> clusters;
  final int pageCount;
  final ClusterSettings settings;

  Future<void> dispose() => document.dispose();
}
