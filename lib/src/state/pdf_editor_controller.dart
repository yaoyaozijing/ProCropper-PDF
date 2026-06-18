import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cluster_settings.dart';
import '../models/crop_rect.dart';
import '../models/crop_clipboard.dart';
import '../models/page_cluster.dart';
import '../models/pdf_project.dart';
import '../services/pdf_export_service.dart';
import '../services/pdf_project_service.dart';

enum ApplyTarget {
  currentCluster,
  allClusters,
  evenClusters,
  oddClusters,
}

class PdfEditorController extends ChangeNotifier {
  PdfEditorController({
    PdfProjectService? projectService,
    PdfExportService? exportService,
  }) : _projectService = projectService ?? PdfProjectService(),
       _exportService = exportService ?? PdfExportService();

  final PdfProjectService _projectService;
  final PdfExportService _exportService;

  PdfProject? _project;
  int _selectedClusterIndex = 0;
  int _selectedRectIndex = 0;
  bool _isBusy = false;
  bool _isExporting = false;
  String? _status;
  String? _exportStatus;
  double? _exportProgress;
  String? _lastExportPath;
  String? _lastExportError;
  CropClipboard? _clipboard;

  PdfProject? get project => _project;
  bool get isBusy => _isBusy;
  bool get isExporting => _isExporting;
  String? get status => _status;
  String? get exportStatus => _exportStatus;
  double? get exportProgress => _exportProgress;
  String? get lastExportPath => _lastExportPath;
  String? get lastExportError => _lastExportError;
  bool get hasClipboard => _clipboard != null;
  ClusterSettings get settings => _project?.settings ?? const ClusterSettings();
  List<PageCluster> get clusters => _project?.clusters ?? const [];
  int get selectedClusterIndex => _selectedClusterIndex;
  int get selectedRectIndex => _selectedRectIndex;
  PageCluster? get selectedCluster =>
      clusters.isEmpty ? null : clusters[_selectedClusterIndex.clamp(0, clusters.length - 1)];

  Future<void> openFile(String filePath) async {
    await _runBusy('正在加载 PDF...', () async {
      final previousProject = _project;
      _project = null;
      notifyListeners();
      await previousProject?.dispose();
      _project = await _projectService.open(filePath);
      _selectedClusterIndex = 0;
      _selectedRectIndex = 0;
    });
  }

  void selectCluster(int index) {
    _selectedClusterIndex = index;
    _selectedRectIndex = 0;
    notifyListeners();
  }

  void selectRect(int index) {
    _selectedRectIndex = index;
    notifyListeners();
  }

  void updateSelectedRect(CropRect rect) {
    final cluster = selectedCluster;
    if (cluster == null || cluster.cropRects.isEmpty) {
      return;
    }
    final updatedRects = [...cluster.cropRects];
    updatedRects[_selectedRectIndex] = rect.normalized();
    _replaceCluster(cluster.copyWith(cropRects: updatedRects));
  }

  void addRect() {
    final cluster = selectedCluster;
    if (cluster == null) {
      return;
    }
    final updatedRects = [...cluster.cropRects, CropRect.full];
    _replaceCluster(cluster.copyWith(cropRects: updatedRects));
    _selectedRectIndex = updatedRects.length - 1;
    notifyListeners();
  }

  void removeSelectedRect() {
    final cluster = selectedCluster;
    if (cluster == null || cluster.cropRects.length <= 1) {
      return;
    }
    final updatedRects = [...cluster.cropRects]..removeAt(_selectedRectIndex);
    _replaceCluster(cluster.copyWith(cropRects: updatedRects));
    _selectedRectIndex = _selectedRectIndex.clamp(0, updatedRects.length - 1);
    notifyListeners();
  }

  void splitSelectedRectVertically() {
    final cluster = selectedCluster;
    if (cluster == null || cluster.cropRects.isEmpty) {
      return;
    }
    final rect = cluster.cropRects[_selectedRectIndex];
    final middle = (rect.left + rect.right) / 2;
    final split = [
      rect.copyWith(right: middle),
      rect.copyWith(left: middle),
    ].where((item) => item.isValid).toList();
    final updatedRects = [...cluster.cropRects]
      ..removeAt(_selectedRectIndex)
      ..insertAll(_selectedRectIndex, split);
    _replaceCluster(cluster.copyWith(cropRects: updatedRects));
    notifyListeners();
  }

  void splitSelectedRectHorizontally() {
    final cluster = selectedCluster;
    if (cluster == null || cluster.cropRects.isEmpty) {
      return;
    }
    final rect = cluster.cropRects[_selectedRectIndex];
    final middle = (rect.top + rect.bottom) / 2;
    final split = [
      rect.copyWith(bottom: middle),
      rect.copyWith(top: middle),
    ].where((item) => item.isValid).toList();
    final updatedRects = [...cluster.cropRects]
      ..removeAt(_selectedRectIndex)
      ..insertAll(_selectedRectIndex, split);
    _replaceCluster(cluster.copyWith(cropRects: updatedRects));
    notifyListeners();
  }

  void copyCurrentRects() {
    final cluster = selectedCluster;
    if (cluster == null) {
      return;
    }
    _clipboard = CropClipboard(
      cropRects: cluster.cropRects.map((rect) => rect.normalized()).toList(),
      sourceClusterId: cluster.id,
    );
    notifyListeners();
  }

  void pasteRectsToSelectedCluster() {
    final cluster = selectedCluster;
    if (cluster == null || _clipboard == null) {
      return;
    }
    _replaceCluster(
      cluster.copyWith(
        cropRects: _clipboard!.cropRects.map((rect) => rect.normalized()).toList(),
      ),
    );
  }

  Future<void> recalculateAutoCropForSelectedCluster() async {
    final cluster = selectedCluster;
    if (cluster == null) {
      return;
    }
    await _runBusy('正在重新计算当前分组的自动裁边...', () async {
      final rebuilt = await _projectService.rebuildAutoCropForCluster(cluster);
      _replaceCluster(rebuilt);
      _selectedRectIndex = 0;
    });
  }

  Future<void> recalculateAutoCropForAllClusters() async {
    if (_project == null) {
      return;
    }
    await _runBusy('正在重新计算全部分组的自动裁边...', () async {
      final rebuiltClusters = <PageCluster>[];
      for (final cluster in clusters) {
        rebuiltClusters.add(await _projectService.rebuildAutoCropForCluster(cluster));
      }
      _project = PdfProject(
        filePath: _project!.filePath,
        fileName: _project!.fileName,
        document: _project!.document,
        clusters: rebuiltClusters,
        pageCount: _project!.pageCount,
        settings: _project!.settings,
      );
      _selectedRectIndex = 0;
    });
  }

  void applyCurrentRectsTo(ApplyTarget target) {
    final source = selectedCluster;
    if (source == null) {
      return;
    }

    final sourceRects = source.cropRects.map((rect) => rect.normalized()).toList();
    final currentClusters = [...clusters];

    for (var i = 0; i < currentClusters.length; i++) {
      final cluster = currentClusters[i];
      final shouldApply = switch (target) {
        ApplyTarget.currentCluster => cluster.id == source.id,
        ApplyTarget.allClusters => true,
        ApplyTarget.evenClusters => cluster.parityLabel == '偶数',
        ApplyTarget.oddClusters => cluster.parityLabel == '奇数',
      };
      if (shouldApply) {
        currentClusters[i] = cluster.copyWith(cropRects: sourceRects);
      }
    }

    _project = PdfProject(
      filePath: _project!.filePath,
      fileName: _project!.fileName,
      document: _project!.document,
      clusters: currentClusters,
      pageCount: _project!.pageCount,
      settings: _project!.settings,
    );
    notifyListeners();
  }

  Future<void> regroup({
    required bool separateOddEven,
    required Set<int> excludedPages,
  }) async {
    if (_project == null) {
      return;
    }

    await _runBusy('正在重新分组...', () async {
      final nextSettings = ClusterSettings(
        separateOddEven: separateOddEven,
        excludedPages: {...excludedPages},
      );
      _project = await _projectService.rebuildProject(
        _project!,
        settings: nextSettings,
      );
      _selectedClusterIndex = 0;
      _selectedRectIndex = 0;
    });
  }

  Future<void> mergeClusters(List<int> selectedIndices) async {
    if (_project == null || selectedIndices.length < 2) {
      return;
    }

    await _runBusy('正在合并分组...', () async {
      final sortedIndices = [...selectedIndices]..sort();
      final sourceClusters = sortedIndices.map((index) => clusters[index]).toList();
      final mergedPages = sourceClusters.expand((cluster) => cluster.pages).toList()..sort();
      final newCluster = await _projectService.createManualClusterFromPages(
        _project!.document,
        pages: mergedPages,
        parityLabel: _mergedParityLabel(sourceClusters),
        cropRects: sourceClusters.first.cropRects.map((rect) => rect.normalized()).toList(),
      );

      final updatedClusters = <PageCluster>[];
      for (var i = 0; i < clusters.length; i++) {
        if (!sortedIndices.contains(i)) {
          updatedClusters.add(clusters[i]);
        }
      }
      updatedClusters.add(newCluster);
      updatedClusters.sort((a, b) => a.pages.first.compareTo(b.pages.first));

      _project = PdfProject(
        filePath: _project!.filePath,
        fileName: _project!.fileName,
        document: _project!.document,
        clusters: updatedClusters,
        pageCount: _project!.pageCount,
        settings: _project!.settings,
      );
      _selectedClusterIndex = updatedClusters.indexOf(newCluster);
      _selectedRectIndex = 0;
    });
  }

  Future<void> createClusterFromPages(Set<int> pageNumbers) async {
    if (_project == null || pageNumbers.isEmpty) {
      return;
    }

    await _runBusy('正在新建分组...', () async {
      final selectedPages = pageNumbers.toList()..sort();
      final newCluster = await _projectService.createManualClusterFromPages(
        _project!.document,
        pages: selectedPages,
        parityLabel: _parityLabelForPages(selectedPages),
      );

      final updatedClusters = <PageCluster>[];
      for (final cluster in clusters) {
        final remainingPages = cluster.pages.where((page) => !pageNumbers.contains(page)).toList()..sort();
        if (remainingPages.isEmpty) {
          continue;
        }
        if (remainingPages.length == cluster.pages.length) {
          updatedClusters.add(cluster);
          continue;
        }
        updatedClusters.add(
          await _projectService.createManualClusterFromPages(
            _project!.document,
            pages: remainingPages,
            parityLabel: _parityLabelForPages(remainingPages),
            cropRects: cluster.cropRects.map((rect) => rect.normalized()).toList(),
          ),
        );
      }

      updatedClusters.add(newCluster);
      updatedClusters.sort((a, b) => a.pages.first.compareTo(b.pages.first));

      _project = PdfProject(
        filePath: _project!.filePath,
        fileName: _project!.fileName,
        document: _project!.document,
        clusters: updatedClusters,
        pageCount: _project!.pageCount,
        settings: _project!.settings,
      );
      _selectedClusterIndex = updatedClusters.indexOf(newCluster);
      _selectedRectIndex = 0;
    });
  }

  Future<String?> export({String? destinationPath, String? destinationUri}) async {
    if (_project == null || _isExporting) {
      return null;
    }

    final currentProject = _project!;
    final pageCropMap = <int, List<CropRect>>{};
    for (final cluster in clusters) {
      final snapshotRects = cluster.cropRects.map((rect) => rect.normalized()).toList(growable: false);
      for (final pageNumber in cluster.pages) {
        pageCropMap[pageNumber] = snapshotRects;
      }
    }

    String? outputPath;
    _isExporting = true;
    _exportProgress = 0;
    _exportStatus = '正在准备导出...';
    _lastExportPath = null;
    _lastExportError = null;
    notifyListeners();
    try {
      outputPath = await _exportService.export(
        project: currentProject,
        pageCropMap: pageCropMap,
        destinationPath: destinationPath,
        destinationUri: destinationUri,
        onProgress: (progress, message) {
          _exportProgress = progress;
          _exportStatus = message;
          notifyListeners();
        },
      );
      _exportProgress = 1;
      _exportStatus = '导出完成';
      _lastExportPath = outputPath;
      _lastExportError = null;
      return outputPath;
    } catch (error) {
      _exportProgress = null;
      _exportStatus = '导出失败';
      _lastExportPath = null;
      _lastExportError = error.toString();
      rethrow;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void dismissExportFeedback() {
    _exportProgress = null;
    _exportStatus = null;
    _lastExportPath = null;
    _lastExportError = null;
    notifyListeners();
  }

  Future<void> disposeProject() async {
    final current = _project;
    _project = null;
    notifyListeners();
    await current?.dispose();
  }

  void _replaceCluster(PageCluster updatedCluster) {
    if (_project == null) {
      return;
    }
    final updatedClusters = [...clusters];
    updatedClusters[_selectedClusterIndex] = updatedCluster;
    _project = PdfProject(
      filePath: _project!.filePath,
      fileName: _project!.fileName,
      document: _project!.document,
      clusters: updatedClusters,
      pageCount: _project!.pageCount,
      settings: _project!.settings,
    );
    notifyListeners();
  }

  String _mergedParityLabel(List<PageCluster> clustersToMerge) {
    final labels = clustersToMerge.map((cluster) => cluster.parityLabel).toSet();
    return labels.length == 1 ? labels.first : '混合';
  }

  String _parityLabelForPages(List<int> pages) {
    final hasOdd = pages.any((page) => page.isOdd);
    final hasEven = pages.any((page) => page.isEven);
    if (hasOdd && hasEven) {
      return '混合';
    }
    return hasEven ? '偶数' : '奇数';
  }

  Future<void> _runBusy(String status, Future<void> Function() action) async {
    _isBusy = true;
    _status = status;
    notifyListeners();
    try {
      await action();
      _status = null;
    } catch (error) {
      _status = error.toString();
      rethrow;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(disposeProject());
    super.dispose();
  }

  Future<String?> createAndroidDocumentUri({
    required String fileName,
    String mimeType = 'application/pdf',
  }) {
    return _exportService.createDocumentUri(
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
