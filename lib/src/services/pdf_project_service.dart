import 'package:pdfrx/pdfrx.dart';

import '../models/cluster_settings.dart';
import '../models/crop_rect.dart';
import '../models/page_cluster.dart';
import '../models/pdf_project.dart';
import 'auto_crop_service.dart';
import 'preview_merge_service.dart';

class PdfProjectService {
  static const int _maxPreviewPages = 12;
  static const int _mergeVariability = 20;

  Future<PdfProject> open(
    String filePath, {
    ClusterSettings settings = const ClusterSettings(),
  }) async {
    final document = await PdfDocument.openFile(filePath);
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final clusters = await buildClusters(document, settings: settings);
    return PdfProject(
      filePath: filePath,
      fileName: fileName,
      document: document,
      clusters: clusters,
      pageCount: document.pages.length,
      settings: settings,
    );
  }

  Future<List<PageCluster>> buildClusters(
    PdfDocument document, {
    required ClusterSettings settings,
  }) async {
    final buckets = <String, _ClusterBucket>{};

    for (final page in document.pages) {
      if (settings.excludedPages.contains(page.pageNumber)) {
        continue;
      }
      final width = page.width;
      final height = page.height;
      final roundedWidth = (width / _mergeVariability).floor() * _mergeVariability;
      final roundedHeight = (height / _mergeVariability).floor() * _mergeVariability;
      final parityKey = settings.separateOddEven
          ? (page.pageNumber.isEven ? 'even' : 'odd')
          : 'all';
      final parityLabel = settings.separateOddEven
          ? (page.pageNumber.isEven ? '偶数' : '奇数')
          : '混合';
      final key = '$parityKey-$roundedWidth-$roundedHeight';
      final bucket = buckets.putIfAbsent(
        key,
        () => _ClusterBucket(
          id: key,
          parityLabel: parityLabel,
          pageWidth: width,
          pageHeight: height,
        ),
      );
      bucket.pages.add(page.pageNumber);
    }

    final clusters = <PageCluster>[];
    final sortedBuckets = buckets.values.toList()
      ..sort((a, b) => a.pages.first.compareTo(b.pages.first));

    for (final bucket in sortedBuckets) {
      final previewPages = _choosePreviewPages(bucket.pages);
      final preview = await PreviewMergeService.buildClusterPreview(
        document: document,
        pageNumbers: previewPages,
        pageWidth: bucket.pageWidth,
        pageHeight: bucket.pageHeight,
      );
      final autoCrop = AutoCropService.detectFromBgraPixels(
        pixels: preview.bgraBytes,
        width: preview.width,
        height: preview.height,
      );

      clusters.add(
        PageCluster(
          id: bucket.id,
          parityLabel: bucket.parityLabel,
          pageWidth: bucket.pageWidth,
          pageHeight: bucket.pageHeight,
          pages: List.unmodifiable(bucket.pages),
          previewImageBytes: preview.pngBytes,
          previewSize: preview.size,
          previewBgraBytes: preview.bgraBytes,
          previewPixelWidth: preview.width,
          previewPixelHeight: preview.height,
          cropRects: [autoCrop],
        ),
      );
    }

    return clusters;
  }

  Future<PdfProject> rebuildProject(
    PdfProject project, {
    required ClusterSettings settings,
  }) async {
    final clusters = await buildClusters(project.document, settings: settings);
    return PdfProject(
      filePath: project.filePath,
      fileName: project.fileName,
      document: project.document,
      clusters: clusters,
      pageCount: project.pageCount,
      settings: settings,
    );
  }

  Future<PageCluster> rebuildAutoCropForCluster(PageCluster cluster) async {
    final autoCrop = AutoCropService.detectFromBgraPixels(
      pixels: cluster.previewBgraBytes,
      width: cluster.previewPixelWidth,
      height: cluster.previewPixelHeight,
    );
    return cluster.copyWith(cropRects: [autoCrop]);
  }

  Future<PageCluster> createManualClusterFromPages(
    PdfDocument document, {
    required List<int> pages,
    required String parityLabel,
    List<CropRect>? cropRects,
  }) async {
    final sortedPages = [...pages]..sort();
    final firstPage = document.pages[sortedPages.first - 1];
    final previewPages = _choosePreviewPages(sortedPages);
    final preview = await PreviewMergeService.buildClusterPreview(
      document: document,
      pageNumbers: previewPages,
      pageWidth: firstPage.width,
      pageHeight: firstPage.height,
    );

    return PageCluster(
      id: 'manual-${sortedPages.join("-")}-${DateTime.now().microsecondsSinceEpoch}',
      parityLabel: parityLabel,
      pageWidth: firstPage.width,
      pageHeight: firstPage.height,
      pages: List.unmodifiable(sortedPages),
      previewImageBytes: preview.pngBytes,
      previewSize: preview.size,
      previewBgraBytes: preview.bgraBytes,
      previewPixelWidth: preview.width,
      previewPixelHeight: preview.height,
      cropRects:
          cropRects != null
              ? List.of(cropRects)
              : [AutoCropService.detectFromBgraPixels(
                  pixels: preview.bgraBytes,
                  width: preview.width,
                  height: preview.height,
                )],
    );
  }

  List<int> _choosePreviewPages(List<int> pages) {
    if (pages.length <= _maxPreviewPages) {
      return pages;
    }
    final result = <int>[];
    final step = pages.length / _maxPreviewPages;
    for (var i = 0; i < _maxPreviewPages; i++) {
      result.add(pages[(i * step).floor()]);
    }
    return result;
  }
}

class _ClusterBucket {
  _ClusterBucket({
    required this.id,
    required this.parityLabel,
    required this.pageWidth,
    required this.pageHeight,
  });

  final String id;
  final String parityLabel;
  final double pageWidth;
  final double pageHeight;
  final List<int> pages = [];
}
