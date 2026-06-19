import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../l10n/app_localizations.dart';
import '../models/cluster_settings.dart';
import '../models/crop_aspect_ratio_lock.dart';
import '../models/crop_rect.dart';
import '../models/page_cluster.dart';
import '../models/pdf_project.dart';
import 'auto_crop_service.dart';
import 'page_analysis_service.dart';
import 'preview_merge_service.dart';

class PdfProjectService {
  static const int _maxPreviewPages = 12;
  static const int _mergeVariability = 20;

  AppLocalizations get _l10n => AppLocalizations.current;

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
    final coarseBuckets = <String, _ClusterSeedBucket>{};

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
          ? (page.pageNumber.isEven ? _l10n.even : _l10n.odd)
          : _l10n.mixed;
      final key = '$parityKey-$roundedWidth-$roundedHeight';
      final bucket = coarseBuckets.putIfAbsent(
        key,
        () => _ClusterSeedBucket(
          id: key,
          parityLabel: parityLabel,
          layoutLabel: _l10n.mixedLayout,
          groupingReason: '',
          pageWidth: width,
          pageHeight: height,
        ),
      );
      bucket.pages.add(page.pageNumber);
    }

    final analyzedPages = <int, PageAnalysis>{};
    if (settings.smartGroupingLevel != SmartGroupingLevel.basic) {
      for (final page in document.pages) {
        if (settings.excludedPages.contains(page.pageNumber)) {
          continue;
        }
        analyzedPages[page.pageNumber] = await PageAnalysisService.analyzePage(
          page,
          edgeFilter: settings.edgeFilter,
        );
      }
    }

    final seeds = <_ClusterSeedBucket>[];
    final sortedCoarseBuckets = coarseBuckets.values.toList()
      ..sort((a, b) => a.pages.first.compareTo(b.pages.first));

    for (final coarseBucket in sortedCoarseBuckets) {
      final splitBuckets = _splitBySmartGrouping(
        coarseBucket,
        analyzedPages,
        settings.smartGroupingLevel,
      );
      seeds.addAll(splitBuckets);
    }

    final clusters = <PageCluster>[];
    for (var i = 0; i < seeds.length; i++) {
      final bucket = seeds[i];
      final previewPages = _choosePreviewPages(bucket.pages);
      final preview = await PreviewMergeService.buildClusterPreview(
        document: document,
        pageNumbers: previewPages,
        pageWidth: bucket.pageWidth,
        pageHeight: bucket.pageHeight,
      );
      final autoCrop = _buildOverlayAutoCrop(
        previewBgraBytes: preview.bgraBytes,
        previewWidth: preview.width,
        previewHeight: preview.height,
        edgeFilter: settings.edgeFilter,
      );

      clusters.add(
        PageCluster(
          id: '${bucket.id}-$i',
          parityLabel: bucket.parityLabel,
          layoutLabel: bucket.layoutLabel,
          groupingReason: bucket.groupingReason,
          pageWidth: bucket.pageWidth,
          pageHeight: bucket.pageHeight,
          pages: List.unmodifiable(bucket.pages),
          previewImageBytes: preview.pngBytes,
          previewSize: preview.size,
          previewBgraBytes: preview.bgraBytes,
          previewPixelWidth: preview.width,
          previewPixelHeight: preview.height,
          cropRects: [autoCrop],
          aspectRatioLocks: const [null],
          containsOutlierPage: bucket.containsOutlierPage,
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

  Future<PageCluster> rebuildAutoCropForCluster(
    PdfDocument document,
    PageCluster cluster,
    EdgeFilterSettings edgeFilter,
  ) async {
    final autoCrop = AutoCropService.detectFromBgraPixels(
      pixels: cluster.previewBgraBytes,
      width: cluster.previewPixelWidth,
      height: cluster.previewPixelHeight,
      edgeFilter: edgeFilter,
    );
    return cluster.copyWith(
      cropRects: [_clampCropToPage(autoCrop)],
      aspectRatioLocks: const [null],
    );
  }

  Future<PageCluster> createManualClusterFromPages(
    PdfDocument document, {
    required List<int> pages,
    required String parityLabel,
    List<CropRect>? cropRects,
    List<CropAspectRatioLock?>? aspectRatioLocks,
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

    final suggestedCrop = _buildOverlayAutoCrop(
      previewBgraBytes: preview.bgraBytes,
      previewWidth: preview.width,
      previewHeight: preview.height,
      edgeFilter: const EdgeFilterSettings(),
    );

    return PageCluster(
      id: 'manual-${sortedPages.join("-")}-${DateTime.now().microsecondsSinceEpoch}',
      parityLabel: parityLabel,
      layoutLabel: _manualLayoutLabel(
        pages: sortedPages,
        parityLabel: parityLabel,
      ),
      groupingReason: _buildManualGroupingReason(
        parityLabel: parityLabel,
        pageWidth: firstPage.width,
        pageHeight: firstPage.height,
        pageCount: sortedPages.length,
      ),
      pageWidth: firstPage.width,
      pageHeight: firstPage.height,
      pages: List.unmodifiable(sortedPages),
      previewImageBytes: preview.pngBytes,
      previewSize: preview.size,
      previewBgraBytes: preview.bgraBytes,
      previewPixelWidth: preview.width,
      previewPixelHeight: preview.height,
      cropRects: cropRects != null ? List.of(cropRects) : [suggestedCrop],
      aspectRatioLocks: aspectRatioLocks != null
          ? List<CropAspectRatioLock?>.of(aspectRatioLocks)
          : List<CropAspectRatioLock?>.filled(
              cropRects != null ? cropRects.length : 1,
              null,
            ),
      containsOutlierPage: false,
    );
  }

  List<_ClusterSeedBucket> _splitBySmartGrouping(
    _ClusterSeedBucket bucket,
    Map<int, PageAnalysis> analyzedPages,
    SmartGroupingLevel level,
  ) {
    if (level == SmartGroupingLevel.basic || bucket.pages.length <= 1) {
      return [
        bucket.copyWith(
          layoutLabel: analyzedPages[bucket.pages.first]?.layoutLabel ?? _l10n.mixedLayout,
          groupingReason: _buildGroupingReason(
            parityLabel: bucket.parityLabel,
            layoutLabel: analyzedPages[bucket.pages.first]?.layoutLabel ?? _l10n.mixedLayout,
            pageWidth: bucket.pageWidth,
            pageHeight: bucket.pageHeight,
            pageCount: bucket.pages.length,
            smartGroupingApplied: false,
            containsOutlierPage: false,
          ),
          containsOutlierPage: false,
        ),
      ];
    }

    final threshold = switch (level) {
      SmartGroupingLevel.basic => 0.28,
      SmartGroupingLevel.balanced => 0.2,
      SmartGroupingLevel.strict => 0.13,
    };

    final sortedPages = [...bucket.pages]..sort();
    final smartBuckets = <_SmartClusterBucket>[];

    for (final pageNumber in sortedPages) {
      final analysis = analyzedPages[pageNumber];
      if (analysis == null) {
        smartBuckets.add(
          _SmartClusterBucket(
            pages: [pageNumber],
            fingerprint: null,
          ),
        );
        continue;
      }

      _SmartClusterBucket? bestBucket;
      var bestDistance = double.infinity;
      for (final candidate in smartBuckets) {
        if (candidate.fingerprint == null) {
          continue;
        }
        final distance = analysis.fingerprint.distanceTo(candidate.fingerprint!);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestBucket = candidate;
        }
      }

      if (bestBucket == null || bestDistance > threshold) {
        smartBuckets.add(
          _SmartClusterBucket(
            pages: [pageNumber],
            fingerprint: analysis.fingerprint,
          ),
        );
        continue;
      }

      bestBucket.pages.add(pageNumber);
      bestBucket.fingerprint = bestBucket.fingerprint!.mergeWith(
        analysis.fingerprint,
        bestBucket.pages.length - 1,
      );
    }

    final resolvedBuckets = smartBuckets.map((smartBucket) {
      final pages = [...smartBucket.pages]..sort();
      return _ClusterSeedBucket(
        id: '${bucket.id}-${pages.first}',
        parityLabel: bucket.parityLabel,
        layoutLabel: _resolveLayoutLabelForBucket(pages, analyzedPages),
        groupingReason: _buildGroupingReason(
          parityLabel: bucket.parityLabel,
          layoutLabel: _resolveLayoutLabelForBucket(pages, analyzedPages),
          pageWidth: bucket.pageWidth,
          pageHeight: bucket.pageHeight,
          pageCount: pages.length,
          smartGroupingApplied: true,
          containsOutlierPage: false,
        ),
        pageWidth: bucket.pageWidth,
        pageHeight: bucket.pageHeight,
        pages: pages,
      );
    }).toList()
      ..sort((a, b) => a.pages.first.compareTo(b.pages.first));

    return _splitOutlierPages(resolvedBuckets, analyzedPages);
  }

  CropRect _buildOverlayAutoCrop({
    required Uint8List previewBgraBytes,
    required int previewWidth,
    required int previewHeight,
    required EdgeFilterSettings edgeFilter,
  }) {
    final autoCrop = AutoCropService.detectFromBgraPixels(
      pixels: previewBgraBytes,
      width: previewWidth,
      height: previewHeight,
      edgeFilter: edgeFilter,
    );
    return _clampCropToPage(autoCrop);
  }

  CropRect _clampCropToPage(CropRect crop) {
    return CropRect(
      left: crop.left.clamp(0.0, 1.0).toDouble(),
      top: crop.top.clamp(0.0, 1.0).toDouble(),
      right: crop.right.clamp(0.0, 1.0).toDouble(),
      bottom: crop.bottom.clamp(0.0, 1.0).toDouble(),
    ).normalized();
  }

  double _median(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
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

  List<_ClusterSeedBucket> _splitOutlierPages(
    List<_ClusterSeedBucket> buckets,
    Map<int, PageAnalysis> analyzedPages,
  ) {
    final result = <_ClusterSeedBucket>[];
    for (final bucket in buckets) {
      if (bucket.pages.length <= 2) {
        result.add(bucket);
        continue;
      }

      final analyses = bucket.pages
          .map((page) => analyzedPages[page])
          .whereType<PageAnalysis>()
          .toList(growable: false);
      if (analyses.length <= 2) {
        result.add(bucket);
        continue;
      }

      final reference = analyses.first.fingerprint;
      final distances = analyses
          .map((analysis) => analysis.fingerprint.distanceTo(reference))
          .toList(growable: false);
      final medianDistance = _median(distances);
      final outlierPages = <int>[];
      final normalPages = <int>[];

      for (var i = 0; i < analyses.length; i++) {
        if (distances[i] > math.max(0.14, medianDistance * 2.4)) {
          outlierPages.add(analyses[i].pageNumber);
        } else {
          normalPages.add(analyses[i].pageNumber);
        }
      }

      if (outlierPages.isEmpty || normalPages.isEmpty) {
        result.add(bucket);
        continue;
      }

      result.add(
        bucket.copyWith(
          pages: normalPages,
          containsOutlierPage: false,
          layoutLabel: _resolveLayoutLabelForBucket(normalPages, analyzedPages),
          groupingReason: _buildGroupingReason(
            parityLabel: bucket.parityLabel,
            layoutLabel: _resolveLayoutLabelForBucket(normalPages, analyzedPages),
            pageWidth: bucket.pageWidth,
            pageHeight: bucket.pageHeight,
            pageCount: normalPages.length,
            smartGroupingApplied: true,
            containsOutlierPage: false,
          ),
        ),
      );
      for (final pageNumber in outlierPages) {
        result.add(
          bucket.copyWith(
            id: '${bucket.id}-outlier-$pageNumber',
            pages: [pageNumber],
            layoutLabel:
                '${analyzedPages[pageNumber]?.layoutLabel ?? _l10n.anomalyPage} · ${_l10n.outlierSuffix}',
            groupingReason: _buildGroupingReason(
              parityLabel: bucket.parityLabel,
              layoutLabel:
                  '${analyzedPages[pageNumber]?.layoutLabel ?? _l10n.anomalyPage} · ${_l10n.outlierSuffix}',
              pageWidth: bucket.pageWidth,
              pageHeight: bucket.pageHeight,
              pageCount: 1,
              smartGroupingApplied: true,
              containsOutlierPage: true,
            ),
            containsOutlierPage: true,
          ),
        );
      }
    }
    result.sort((a, b) => a.pages.first.compareTo(b.pages.first));
    return result;
  }

  String _resolveLayoutLabelForBucket(
    List<int> pages,
    Map<int, PageAnalysis> analyzedPages,
  ) {
    final counts = <String, int>{};
    for (final page in pages) {
      final label = analyzedPages[page]?.layoutLabel ?? _l10n.mixedLayout;
      counts.update(label, (value) => value + 1, ifAbsent: () => 1);
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isEmpty ? _l10n.mixedLayout : sorted.first.key;
  }

  String _manualLayoutLabel({
    required List<int> pages,
    required String parityLabel,
  }) {
    if (pages.length == 1) {
      return _l10n.manualSinglePage;
    }
    return parityLabel == _l10n.mixed ? _l10n.manualMixedGroup : _l10n.manualGroup;
  }

  static String _buildGroupingReason({
    required String parityLabel,
    required String layoutLabel,
    required double pageWidth,
    required double pageHeight,
    required int pageCount,
    required bool smartGroupingApplied,
    required bool containsOutlierPage,
  }) {
    final roundedWidth = (pageWidth / _mergeVariability).floor() * _mergeVariability;
    final roundedHeight = (pageHeight / _mergeVariability).floor() * _mergeVariability;
    return AppLocalizations.current.groupingReason(
      parityLabel: parityLabel,
      layoutLabel: layoutLabel,
      roundedWidth: roundedWidth,
      roundedHeight: roundedHeight,
      pageCount: pageCount,
      smartGroupingApplied: smartGroupingApplied,
      containsOutlierPage: containsOutlierPage,
    );
  }

  String _buildManualGroupingReason({
    required String parityLabel,
    required double pageWidth,
    required double pageHeight,
    required int pageCount,
  }) {
    final roundedWidth = (pageWidth / _mergeVariability).floor() * _mergeVariability;
    final roundedHeight = (pageHeight / _mergeVariability).floor() * _mergeVariability;
    return AppLocalizations.current.manualGroupingReason(
      parityLabel: parityLabel,
      roundedWidth: roundedWidth,
      roundedHeight: roundedHeight,
      pageCount: pageCount,
    );
  }
}

class _ClusterSeedBucket {
  _ClusterSeedBucket({
    required this.id,
    required this.parityLabel,
    required this.layoutLabel,
    required this.groupingReason,
    required this.pageWidth,
    required this.pageHeight,
    List<int>? pages,
    this.containsOutlierPage = false,
  }) : pages = pages ?? <int>[];

  final String id;
  final String parityLabel;
  final String layoutLabel;
  final String groupingReason;
  final double pageWidth;
  final double pageHeight;
  final List<int> pages;
  final bool containsOutlierPage;

  _ClusterSeedBucket copyWith({
    String? id,
    String? parityLabel,
    String? layoutLabel,
    String? groupingReason,
    double? pageWidth,
    double? pageHeight,
    List<int>? pages,
    bool? containsOutlierPage,
  }) {
    return _ClusterSeedBucket(
      id: id ?? this.id,
      parityLabel: parityLabel ?? this.parityLabel,
      layoutLabel: layoutLabel ?? this.layoutLabel,
      groupingReason: groupingReason ?? this.groupingReason,
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      pages: pages ?? this.pages,
      containsOutlierPage: containsOutlierPage ?? this.containsOutlierPage,
    );
  }
}

class _SmartClusterBucket {
  _SmartClusterBucket({
    required this.pages,
    required this.fingerprint,
  });

  final List<int> pages;
  PageFingerprint? fingerprint;
}
