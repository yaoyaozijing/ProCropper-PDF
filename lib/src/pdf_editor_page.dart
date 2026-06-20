import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'l10n/app_localizations.dart';
import 'models/app_grouping_settings.dart';
import 'models/cluster_settings.dart';
import 'models/crop_aspect_ratio_lock.dart';
import 'models/page_cluster.dart';
import 'services/app_settings_service.dart';
import 'state/pdf_editor_controller.dart';
import 'widgets/crop_editor.dart';
import 'widgets/status_corner_card.dart';
import 'widgets/windows_window_controls.dart';

class PdfEditorPage extends StatefulWidget {
  const PdfEditorPage({
    required this.controller,
    super.key,
  });

  final PdfEditorController controller;

  @override
  State<PdfEditorPage> createState() => _PdfEditorPageState();
}

class _PdfEditorPageState extends State<PdfEditorPage> {
  final Set<int> _selectedClusterIndices = <int>{};
  final CropViewportController _viewportController = CropViewportController();
  final TextEditingController _locatePageController = TextEditingController();
  final FocusNode _locatePageFocusNode = FocusNode();
  late final AppSettingsService _appSettingsService;
  static const double _clusterPanelWidth = 350;
  static const double _toolPanelWidth = 188;
  String? _statusMessage;
  bool _showClusterPanel = true;
  bool _showToolPanel = true;
  bool _showLocatePageField = false;

  PdfEditorController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _appSettingsService = AppSettingsService();
    _controller.addListener(_onControllerChanged);
    _loadDocumentSettings();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _locatePageController.dispose();
    _locatePageFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_selectedClusterIndices.any((index) => index >= _controller.clusters.length)) {
      _selectedClusterIndices.removeWhere((index) => index >= _controller.clusters.length);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDocumentSettings() async {
    await _appSettingsService.init();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final project = _controller.project;
    final cluster = _controller.selectedCluster;
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 108,
        leading: Row(
          children: [
            const BackButton(),
            IconButton(
              tooltip: isCompact
                  ? l10n.clusterPanelOpen
                  : (_showClusterPanel ? l10n.collapseClusterPanel : l10n.expandClusterPanel),
              onPressed: isCompact ? _showClusterBottomSheet : _toggleClusterPanel,
              icon: Icon(Icons.menu),
            ),
          ],
        ),
        title: WindowsDragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              project?.fileName ?? l10n.openPdf,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        actions: [
          _buildToolActionsButton(isCompact),
          if (!isCompact)
            TextButton.icon(
              onPressed: _controller.isBusy ? null : _pickPdf,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(l10n.open),
            ),
          const SizedBox(width: 8),
          if (isCompact)
            FilledButton(
              onPressed: project == null || _controller.isBusy ? null : _exportPdf,
              style: FilledButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Icon(Icons.download_rounded),
            )
          else
            FilledButton.icon(
              onPressed: project == null || _controller.isBusy ? null : _exportPdf,
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.export),
            ),
          const WindowsWindowControls(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (project != null && cluster != null)
            _buildEditor(
              cluster,
              isCompact: isCompact,
            )
          else
            _buildMissingProject(),
          if (_statusMessage != null)
            StatusCornerCard(
              title: l10n.tips,
              message: _statusMessage!,
              icon: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              bottom: _shouldShowExportOverlay ? 186 : 18,
              onClose: _dismissStatusMessage,
            ),
          if (_controller.isBusy)
            StatusCornerCard(
              title: l10n.processing,
              message: _controller.status ?? l10n.processingTask,
              bottom: _statusMessage != null ? (_shouldShowExportOverlay ? 354 : 186) : (_shouldShowExportOverlay ? 186 : 18),
            ),
          if (_shouldShowExportOverlay) _buildExportOverlay(),
        ],
      ),
    );
  }

  bool get _shouldShowExportOverlay =>
      _controller.isExporting ||
      _controller.lastExportPath != null ||
      _controller.lastExportError != null;

  Widget _buildMissingProject() {
    final l10n = context.l10n;
    return Center(
      child: FilledButton.icon(
        onPressed: _pickPdf,
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(l10n.reopenPdf),
      ),
    );
  }

  Widget _buildEditor(PageCluster cluster, {required bool isCompact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showClusterPanel = !isCompact && _showClusterPanel;
    final showToolPanel = !isCompact && _showToolPanel;

    return Stack(
      children: [
        Positioned.fill(
          child: CropEditor(
            previewBytes: cluster.previewImageBytes,
            previewSize: cluster.previewSize,
            cropRects: cluster.cropRects,
            aspectRatioLocks: cluster.aspectRatioLocks,
            selectedRectIndex: _controller.selectedRectIndex,
            colorScheme: colorScheme,
            onRectSelected: _controller.selectRect,
            onRectChanged: _controller.updateSelectedRect,
            onRectDeleteRequested: _removeRectByIndex,
            onRectInfoRequested: _showRectInfoDialog,
            contentPadding: EdgeInsets.fromLTRB(
              showClusterPanel ? _clusterPanelWidth + 36 : 18,
              18,
              showToolPanel ? _toolPanelWidth + 36 : 18,
              18,
            ),
            viewportController: _viewportController,
          ),
        ),
        if (!isCompact)
          Positioned(
            left: _showClusterPanel ? 18 : -(_clusterPanelWidth + 24),
            top: 18,
            bottom: 18,
            child: IgnorePointer(
              ignoring: !_showClusterPanel,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showClusterPanel ? 1 : 0,
                child: SizedBox(
                  width: _clusterPanelWidth,
                  child: _buildFloatingPanel(
                    child: _buildClusterPanelContent(),
                  ),
                ),
              ),
            ),
          ),
        if (!isCompact)
          Positioned(
            top: 18,
            right: _showToolPanel ? 18 : -(_toolPanelWidth + 24),
            bottom: 18,
            child: IgnorePointer(
              ignoring: !_showToolPanel,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showToolPanel ? 1 : 0,
                child: SizedBox(
                  width: _toolPanelWidth,
                  child: _buildToolbarPanel(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolActionsButton(bool isCompact) {
    final l10n = context.l10n;
    if (!isCompact) {
      return IconButton(
        tooltip: _showToolPanel ? l10n.collapseToolbar : l10n.expandToolbar,
        onPressed: _toggleToolPanel,
        icon: const Icon(Icons.info),
      );
    }

    return PopupMenuButton<_CompactToolbarAction>(
      tooltip: l10n.toolMenu,
      icon: const Icon(Icons.info),
      onSelected: _handleCompactToolbarAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CompactToolbarAction.openPdf,
          child: Text(l10n.openPdf),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _CompactToolbarAction.zoomOut,
          child: Text(l10n.zoomOut),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.zoomIn,
          child: Text(l10n.zoomIn),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _CompactToolbarAction.recalculateCurrent,
          child: Text(l10n.recalculateCurrent),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.recalculateAll,
          child: Text(l10n.recalculateAll),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _CompactToolbarAction.addRect,
          child: Text(l10n.addCropRect),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.removeRect,
          child: Text(l10n.removeCurrentRect),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.splitVertical,
          child: Text(l10n.splitHorizontal),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.splitHorizontal,
          child: Text(l10n.splitVertical),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _CompactToolbarAction.copyRects,
          child: Text(l10n.copyPreset),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.pasteRects,
          child: Text(l10n.pastePreset),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _CompactToolbarAction.applyAll,
          child: Text(l10n.applyToAll),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.applyEven,
          child: Text(l10n.applyToEven),
        ),
        PopupMenuItem(
          value: _CompactToolbarAction.applyOdd,
          child: Text(l10n.applyToOdd),
        ),
      ],
    );
  }

  Widget _buildClusterPanelContent({
    VoidCallback? onClusterSelected,
  }) {
    return Column(
      children: [
        _buildClusterActionsBar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: _controller.clusters.length,
            itemBuilder: (context, index) {
              final item = _controller.clusters[index];
              return _ClusterTile(
                cluster: item,
                pageLabel: _formatPageRanges(item.pages),
                selected: index == _controller.selectedClusterIndex,
                multiSelected: _selectedClusterIndices.contains(index),
                onTap: () {
                  _controller.selectCluster(index);
                  onClusterSelected?.call();
                },
                onCheckChanged: (value) => _toggleClusterSelection(index, value),
              );
            },
          ),
        ),
        _buildSidebarFooter(),
      ],
    );
  }

  Widget _buildSidebarFooter() {
    final l10n = context.l10n;
    final project = _controller.project!;
    final excludedPages = _controller.settings.excludedPages.toList()..sort();
    final edgeFilterText = _formatEdgeFilterSummary(_controller.settings.edgeFilter);
    final summaryText = excludedPages.isEmpty
        ? l10n.summaryText(
            pageCount: project.pageCount,
            clusterCount: project.clusters.length,
            excludedText: l10n.noExcludedPages,
            filterText: edgeFilterText,
          )
        : l10n.summaryText(
            pageCount: project.pageCount,
            clusterCount: project.clusters.length,
            excludedText: l10n.excludedPagesLabel(_formatPageRanges(excludedPages)),
            filterText: edgeFilterText,
          );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showLocatePageField) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locatePageController,
                    focusNode: _locatePageFocusNode,
                    autofocus: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _locatePageFromField(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.locatePageHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.confirmLocate,
                  onPressed: _locatePageFromField,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
        children: [
          Expanded(
            child: Text(
              summaryText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
                onPressed: _showLocatePageField ? _hideLocatePageField : _showLocatePageFieldInput,
                icon: Icon(_showLocatePageField ? Icons.keyboard_hide_rounded : Icons.search_rounded),
                label: Text(_showLocatePageField ? l10n.collapse : l10n.locate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClusterActionsBar() {
    final l10n = context.l10n;
    final canMerge = _canMergeSelectedClusters();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showRegroupDialog,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.reset),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canMerge ? _mergeSelectedClusters : null,
                  icon: const Icon(Icons.merge_type_rounded),
                  label: Text(l10n.merge),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSplitPagesDialog,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: Text(l10n.create),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canMergeSelectedClusters() {
    if (_selectedClusterIndices.length < 2) {
      return false;
    }
    final selectedClusters = _selectedClusterIndices
        .map((index) => _controller.clusters[index])
        .toList(growable: false);
    final firstCluster = selectedClusters.first;
    return selectedClusters.every((cluster) {
      return cluster.pageWidth == firstCluster.pageWidth &&
          cluster.pageHeight == firstCluster.pageHeight;
    });
  }

  Widget _buildToolbarPanel() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return _buildFloatingPanel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.toolSection,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildToolbarButton(
                onPressed: _viewportController.zoomOut,
                icon: Icons.zoom_out_rounded,
                label: l10n.zoomOut,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _viewportController.zoomIn,
                icon: Icons.zoom_in_rounded,
                label: l10n.zoomIn,
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: _controller.recalculateAutoCropForSelectedCluster,
                icon: Icons.auto_awesome_rounded,
                label: l10n.recalculateCurrent,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.recalculateAutoCropForAllClusters,
                icon: Icons.auto_awesome_rounded,
                label: l10n.recalculateAll,
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: _controller.addRect,
                icon: Icons.add_rounded,
                label: l10n.addCropRect,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.removeSelectedRect,
                icon: Icons.delete_outline,
                label: l10n.removeCurrentRect,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.splitSelectedRectVertically,
                icon: Icons.view_week_outlined,
                label: l10n.splitHorizontal,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.splitSelectedRectHorizontally,
                icon: Icons.view_agenda_outlined,
                label: l10n.splitVertical,
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: _controller.copyCurrentRects,
                icon: Icons.copy_all_outlined,
                label: l10n.copyPreset,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.hasClipboard ? _controller.pasteRectsToSelectedCluster : null,
                icon: Icons.assignment_return_outlined,
                label: l10n.pastePreset,
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.allClusters),
                icon: Icons.select_all_rounded,
                label: l10n.applyToAll,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.evenClusters),
                icon: Icons.filter_2_rounded,
                label: l10n.applyToEven,
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.oddClusters),
                icon: Icons.filter_1_rounded,
                label: l10n.applyToOdd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showClusterBottomSheet() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildFloatingPanel(
              child: Theme(
                data: theme,
                child: _buildClusterPanelContent(
                  onClusterSelected: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleClusterPanel() {
    setState(() {
      _showClusterPanel = !_showClusterPanel;
    });
  }

  void _toggleToolPanel() {
    setState(() {
      _showToolPanel = !_showToolPanel;
    });
  }

  void _handleCompactToolbarAction(_CompactToolbarAction action) {
    switch (action) {
      case _CompactToolbarAction.openPdf:
        _pickPdf();
      case _CompactToolbarAction.zoomOut:
        _viewportController.zoomOut();
      case _CompactToolbarAction.zoomIn:
        _viewportController.zoomIn();
      case _CompactToolbarAction.recalculateCurrent:
        _controller.recalculateAutoCropForSelectedCluster();
      case _CompactToolbarAction.recalculateAll:
        _controller.recalculateAutoCropForAllClusters();
      case _CompactToolbarAction.addRect:
        _controller.addRect();
      case _CompactToolbarAction.removeRect:
        _controller.removeSelectedRect();
      case _CompactToolbarAction.splitVertical:
        _controller.splitSelectedRectVertically();
      case _CompactToolbarAction.splitHorizontal:
        _controller.splitSelectedRectHorizontally();
      case _CompactToolbarAction.copyRects:
        _controller.copyCurrentRects();
      case _CompactToolbarAction.pasteRects:
        if (_controller.hasClipboard) {
          _controller.pasteRectsToSelectedCluster();
        }
      case _CompactToolbarAction.applyAll:
        _controller.applyCurrentRectsTo(ApplyTarget.allClusters);
      case _CompactToolbarAction.applyEven:
        _controller.applyCurrentRectsTo(ApplyTarget.evenClusters);
      case _CompactToolbarAction.applyOdd:
        _controller.applyCurrentRectsTo(ApplyTarget.oddClusters);
    }
  }

  Widget _buildFloatingPanel({required Widget child}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final panelColor = Color.alphaBlend(
      colorScheme.surface.withValues(alpha: 0.78),
      colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.88)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildExportOverlay() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = _controller.exportProgress;
    final isDone = !_controller.isExporting && _controller.lastExportPath != null;
    final hasError = !_controller.isExporting && _controller.lastExportError != null;
    final title = isDone
        ? l10n.exportCompleted
        : hasError
            ? l10n.exportFailed
            : l10n.exportingInBackground;
    final message = isDone
        ? _controller.lastExportPath!
        : hasError
            ? _controller.lastExportError!
            : (_controller.exportStatus ?? l10n.processingTask);

    return Positioned(
      right: 18,
      bottom: 18,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (_controller.isExporting)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        value: progress != null && progress > 0 && progress < 1 ? progress : null,
                      ),
                    )
                  else
                    Icon(
                      hasError ? Icons.error_outline_rounded : Icons.task_alt_rounded,
                      color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: _controller.dismissExportFeedback,
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (_controller.isExporting) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: progress),
                ),
              ],
              if (isDone && Platform.isWindows) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _openExportedPdf(_controller.lastExportPath!),
                      icon: const Icon(Icons.file_open_rounded),
                      label: Text(l10n.openPdf),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonalIcon(
                      onPressed: () => _openExportDirectory(_controller.lastExportPath!),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(l10n.openDirectory),
                    ),
                  ],
                ),
              ],
              if (hasError) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _controller.dismissExportFeedback,
                    child: Text(l10n.close),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) {
        return;
      }
      _selectedClusterIndices.clear();
      await _controller.openFile(path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.openPdfFailed(error.toString()));
    }
  }

  Future<void> _exportPdf() async {
    try {
      if (Platform.isAndroid) {
        await _appSettingsService.init();
        final currentSettings = _appSettingsService.loadGroupingSettings();
        final exportMode = currentSettings.androidExportMode;
        if (exportMode == AndroidExportMode.askEveryTime) {
          final exportDecision = await _showAndroidExportActionDialog();
          if (exportDecision == null) {
            return;
          }
          if (exportDecision.doNotAskAgain) {
            final nextSettings = currentSettings.copyWith(
              androidExportMode: switch (exportDecision.action) {
                _AndroidExportAction.save => AndroidExportMode.save,
                _AndroidExportAction.share => AndroidExportMode.share,
              },
            );
            await _appSettingsService.saveGroupingSettings(nextSettings);
          }
          await _performAndroidExport(exportDecision.action);
          return;
        }
        await _performAndroidExport(
          exportMode == AndroidExportMode.save
              ? _AndroidExportAction.save
              : _AndroidExportAction.share,
        );
      } else {
        final destinationPath = await _resolveExportDestinationPath();
        if (destinationPath == null) {
          return;
        }
        await _controller.export(destinationPath: destinationPath);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.exportFailedWithError(error.toString()));
    }
  }

  Future<_AndroidExportDecision?> _showAndroidExportActionDialog() {
    return showDialog<_AndroidExportDecision>(
      context: context,
      builder: (context) {
        var doNotAskAgain = false;
        return AlertDialog(
          title: Text(context.l10n.chooseExportMethodTitle),
          content: StatefulBuilder(
            builder: (context, setState) {
              final l10n = context.l10n;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.chooseExportMethodDescription),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: doNotAskAgain,
                    onChanged: (value) {
                      setState(() {
                        doNotAskAgain = value ?? false;
                      });
                    },
                    title: Text(l10n.doNotAskAgain),
                    subtitle: Text(l10n.rememberExportChoice),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.cancel),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).pop(
                  _AndroidExportDecision(
                    action: _AndroidExportAction.share,
                    doNotAskAgain: doNotAskAgain,
                  ),
                );
              },
              child: Text(context.l10n.share),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _AndroidExportDecision(
                    action: _AndroidExportAction.save,
                    doNotAskAgain: doNotAskAgain,
                  ),
                );
              },
              child: Text(context.l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performAndroidExport(_AndroidExportAction action) async {
    final l10n = context.l10n;
    if (action == _AndroidExportAction.save) {
      final destinationUri = await _controller.createAndroidDocumentUri(
        fileName: _suggestedOutputFileName(),
      );
      if (destinationUri == null) {
        return;
      }
      await _controller.export(destinationUri: destinationUri);
      return;
    }

    final outputPath = await _controller.createTemporaryExportPath();
    if (outputPath == null) {
      return;
    }
    try {
      await _controller.export(destinationPath: outputPath);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(outputPath, mimeType: 'application/pdf')],
          text: _suggestedOutputFileName(),
        ),
      );
      _controller.dismissExportFeedback();
      _showMessage(l10n.exportShareOpened);
    } finally {
      await _controller.deleteTemporaryExport(outputPath);
    }
  }

  Future<String?> _resolveExportDestinationPath() async {
    final result = await FilePicker.saveFile(
      dialogTitle: context.l10n.saveCroppedPdf,
      fileName: _suggestedOutputFileName(),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return result;
  }

  Future<void> _showRegroupDialog() async {
    final currentSettings = _controller.settings;
    final oddEven = ValueNotifier<bool>(currentSettings.separateOddEven);
    final smartGroupingLevel = ValueNotifier<SmartGroupingLevel>(
      currentSettings.smartGroupingLevel,
    );
    final leftFilterController = TextEditingController(
      text: _formatPercentValue(currentSettings.edgeFilter.left),
    );
    final topFilterController = TextEditingController(
      text: _formatPercentValue(currentSettings.edgeFilter.top),
    );
    final rightFilterController = TextEditingController(
      text: _formatPercentValue(currentSettings.edgeFilter.right),
    );
    final bottomFilterController = TextEditingController(
      text: _formatPercentValue(currentSettings.edgeFilter.bottom),
    );
    final excludedText = TextEditingController(
      text: _formatPageRanges(currentSettings.excludedPages.toList()..sort()),
    );

    void applyEdgeFilterPreset({
      required double left,
      required double top,
      required double right,
      required double bottom,
    }) {
      if (left > 0) {
        leftFilterController.text = _formatPercentValue(left);
      }
      if (top > 0) {
        topFilterController.text = _formatPercentValue(top);
      }
      if (right > 0) {
        rightFilterController.text = _formatPercentValue(right);
      }
      if (bottom > 0) {
        bottomFilterController.text = _formatPercentValue(bottom);
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.regroupSettings),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: oddEven,
                  builder: (context, value, child) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.separateOddEven),
                      subtitle: Text(l10n.separateOddEvenDescription),
                      value: value,
                      onChanged: (next) => oddEven.value = next,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(l10n.smartGroupingLevel),
                const SizedBox(height: 8),
                ValueListenableBuilder<SmartGroupingLevel>(
                  valueListenable: smartGroupingLevel,
                  builder: (context, value, child) {
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: SmartGroupingLevel.values.map((level) {
                        return ChoiceChip(
                          label: Text(_smartGroupingLevelLabel(level)),
                          selected: value == level,
                          onSelected: (_) => smartGroupingLevel.value = level,
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _smartGroupingLevelDescription(smartGroupingLevel.value),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Text(l10n.edgeFilterPercentage),
                const SizedBox(height: 6),
                Text(
                  l10n.edgeFilterDescription,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => applyEdgeFilterPreset(
                        left: 0,
                        top: 0.06,
                        right: 0,
                        bottom: 0.06,
                      ),
                      child: Text(l10n.ignoreHeaderFooter),
                    ),
                    OutlinedButton(
                      onPressed: () => applyEdgeFilterPreset(
                        left: 0.10,
                        top: 0,
                        right: 0.10,
                        bottom: 0,
                      ),
                      child: Text(l10n.ignoreSideMarks),
                    ),
                    OutlinedButton(
                      onPressed: () => applyEdgeFilterPreset(
                        left: 0.04,
                        top: 0.05,
                        right: 0.04,
                        bottom: 0.05,
                      ),
                      child: Text(l10n.gentleFilter),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: leftFilterController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.leftPercent,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: topFilterController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.topPercent,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rightFilterController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.rightPercent,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: bottomFilterController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.bottomPercent,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(l10n.excludedPages),
                const SizedBox(height: 6),
                TextField(
                  controller: excludedText,
                  decoration: InputDecoration(
                    hintText: l10n.pageRangeExample,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.excludedPagesDescription,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _controller.regroup(
          separateOddEven: oddEven.value,
          excludedPages: _parsePageSelection(excludedText.text),
          smartGroupingLevel: smartGroupingLevel.value,
          edgeFilter: EdgeFilterSettings(
            left: _parsePercentValue(leftFilterController.text),
            top: _parsePercentValue(topFilterController.text),
            right: _parsePercentValue(rightFilterController.text),
            bottom: _parsePercentValue(bottomFilterController.text),
          ),
        );
        _selectedClusterIndices.clear();
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage(context.l10n.regroupFailed(error.toString()));
      }
    }
  }

  Future<void> _mergeSelectedClusters() async {
    try {
      await _controller.mergeClusters(_selectedClusterIndices.toList());
      _selectedClusterIndices.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.mergeFailed(error.toString()));
    }
  }

  Future<void> _showSplitPagesDialog() async {
    final l10n = context.l10n;
    final project = _controller.project;
    if (project == null) {
      return;
    }

    final pageTextController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.createGroupTitle),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.createGroupDescription),
                const SizedBox(height: 12),
                TextField(
                  controller: pageTextController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.pageRangeExample,
                    border: const OutlineInputBorder(),
                    helperText: l10n.totalPagesHelper(project.pageCount),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.createGroupAction),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final selectedPages = _parsePageSelection(pageTextController.text)
            .where((page) => page >= 1 && page <= project.pageCount)
            .toSet();
        if (selectedPages.isEmpty) {
          throw FormatException(l10n.invalidPageSelection);
        }
        await _controller.createClusterFromPages(selectedPages);
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage(l10n.createGroupFailed(error.toString()));
      }
    }

    pageTextController.dispose();
  }

  void _showLocatePageFieldInput() {
    if (_showLocatePageField) {
      return;
    }
    setState(() {
      _showLocatePageField = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _locatePageFocusNode.requestFocus();
      _locatePageController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _locatePageController.text.length,
      );
    });
  }

  void _hideLocatePageField() {
    _locatePageFocusNode.unfocus();
    setState(() {
      _showLocatePageField = false;
    });
  }

  void _locatePageFromField() {
    final project = _controller.project;
    if (project == null) {
      return;
    }
    try {
      final page = int.parse(_locatePageController.text.trim());
      if (page < 1 || page > project.pageCount) {
        throw FormatException(context.l10n.pageOutOfRange(project.pageCount));
      }
      final clusterIndex = _controller.clusters.indexWhere((cluster) => cluster.pages.contains(page));
      if (clusterIndex == -1) {
        throw FormatException(context.l10n.pageNotFoundInAnyGroup);
      }
      _controller.selectCluster(clusterIndex);
      _hideLocatePageField();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.locatePageFailed(error.toString()));
    }
  }

  void _showRectInfoDialog(int index) {
    final cluster = _controller.selectedCluster;
    if (cluster == null || index < 0 || index >= cluster.cropRects.length) {
      return;
    }
    final rect = cluster.cropRects[index];
    final left = rect.left * cluster.pageWidth;
    final top = rect.top * cluster.pageHeight;
    final right = rect.right * cluster.pageWidth;
    final bottom = rect.bottom * cluster.pageHeight;
    final width = rect.width * cluster.pageWidth;
    final height = rect.height * cluster.pageHeight;
    final currentLock = cluster.aspectRatioLocks[index];
    final lockEnabled = ValueNotifier<bool>(currentLock != null);
    final lockWidthController = TextEditingController(
      text: currentLock?.width.toStringAsFixed(currentLock.width == currentLock.width.roundToDouble() ? 0 : 1) ?? '',
    );
    final lockHeightController = TextEditingController(
      text: currentLock?.height.toStringAsFixed(currentLock.height == currentLock.height.roundToDouble() ? 0 : 1) ?? '',
    );
    _controller.selectRect(index);

    showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.cropBoxTitle(index + 1)),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.pixelLeft(left)),
                const SizedBox(height: 8),
                Text(l10n.pixelTop(top)),
                const SizedBox(height: 8),
                Text(l10n.pixelRight(right)),
                const SizedBox(height: 8),
                Text(l10n.pixelBottom(bottom)),
                const SizedBox(height: 12),
                Text(
                  l10n.pixelSize(width, height),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                ValueListenableBuilder<bool>(
                  valueListenable: lockEnabled,
                  builder: (context, enabled, child) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      onChanged: (value) => lockEnabled.value = value ?? false,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l10n.lockAspectRatio),
                      subtitle: Text(l10n.lockAspectRatioDescription),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: lockEnabled,
                  builder: (context, enabled, child) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lockWidthController,
                            enabled: enabled,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.width,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: lockHeightController,
                            enabled: enabled,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.height,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                try {
                  CropAspectRatioLock? nextLock;
                  if (lockEnabled.value) {
                    final lockWidth = double.parse(lockWidthController.text.trim());
                    final lockHeight = double.parse(lockHeightController.text.trim());
                    if (lockWidth <= 0 || lockHeight <= 0) {
                      throw FormatException(l10n.aspectRatioPositive);
                    }
                    nextLock = CropAspectRatioLock(
                      width: lockWidth,
                      height: lockHeight,
                    );
                  }
                  _controller.updateSelectedRectAspectRatioLock(nextLock);
                  Navigator.of(context).pop();
                } catch (error) {
                  _showMessage(l10n.aspectRatioFailed(error.toString()));
                }
              },
              child: Text(l10n.apply),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  void _toggleClusterSelection(int index, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedClusterIndices.add(index);
      } else {
        _selectedClusterIndices.remove(index);
      }
    });
  }

  void _removeRectByIndex(int index) {
    final cluster = _controller.selectedCluster;
    if (cluster == null || cluster.cropRects.length <= 1) {
      return;
    }
    _controller.selectRect(index);
    _controller.removeSelectedRect();
  }

  Set<int> _parsePageSelection(String text) {
    final result = <int>{};
    for (final rawPart in text.split(',')) {
      final part = rawPart.trim();
      if (part.isEmpty) {
        continue;
      }
      if (part.contains('-')) {
        final bounds = part.split('-').map((item) => int.tryParse(item.trim())).toList();
        if (bounds.length != 2 || bounds[0] == null || bounds[1] == null) {
          throw FormatException(context.l10n.invalidPageFormat(part));
        }
        final start = bounds[0]!;
        final end = bounds[1]!;
        final min = start < end ? start : end;
        final max = start > end ? start : end;
        for (var page = min; page <= max; page++) {
          result.add(page);
        }
      } else {
        final page = int.tryParse(part);
        if (page == null) {
          throw FormatException(context.l10n.invalidPageFormat(part));
        }
        result.add(page);
      }
    }
    return result;
  }

  String _formatPageRanges(List<int> pages) {
    if (pages.isEmpty) {
      return '';
    }

    final sorted = [...pages]..sort();
    final parts = <String>[];
    var start = sorted.first;
    var end = sorted.first;

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      if (current == end + 1) {
        end = current;
        continue;
      }
      parts.add(start == end ? '$start' : '$start-$end');
      start = current;
      end = current;
    }

    parts.add(start == end ? '$start' : '$start-$end');
    return parts.join(', ');
  }

  String _smartGroupingLevelLabel(SmartGroupingLevel level) {
    final l10n = AppLocalizations.current;
    switch (level) {
      case SmartGroupingLevel.basic:
        return l10n.groupingLevelBasic;
      case SmartGroupingLevel.balanced:
        return l10n.groupingLevelBalanced;
      case SmartGroupingLevel.strict:
        return l10n.groupingLevelStrict;
    }
  }

  String _smartGroupingLevelDescription(SmartGroupingLevel level) {
    final l10n = AppLocalizations.current;
    switch (level) {
      case SmartGroupingLevel.basic:
        return l10n.groupingLevelBasicDescription;
      case SmartGroupingLevel.balanced:
        return l10n.groupingLevelBalancedDescription;
      case SmartGroupingLevel.strict:
        return l10n.groupingLevelStrictDescription;
    }
  }

  String _formatPercentValue(double value) {
    final percent = value * 100;
    final rounded = percent.roundToDouble();
    return rounded == percent ? rounded.toStringAsFixed(0) : percent.toStringAsFixed(1);
  }

  double _parsePercentValue(String text) {
    final value = double.tryParse(text.trim());
    if (value == null) {
      throw FormatException(AppLocalizations.current.invalidPercentFormat(text));
    }
    return (value / 100).clamp(0.0, 45.0 / 100).toDouble();
  }

  String _formatEdgeFilterSummary(EdgeFilterSettings settings) {
    return AppLocalizations.current.edgeFilterSummary(
      left: _formatPercentValue(settings.left),
      top: _formatPercentValue(settings.top),
      right: _formatPercentValue(settings.right),
      bottom: _formatPercentValue(settings.bottom),
    );
  }

  String _suggestedOutputFileName() {
    final fileName = _controller.project?.fileName ?? 'output.pdf';
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return AppLocalizations.current.croppedFileName(fileName);
    }
    return AppLocalizations.current.croppedFileNameFallback(fileName);
  }

  Future<void> _openExportDirectory(String outputPath) async {
    final directoryPath = p.dirname(outputPath);
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [directoryPath]);
        return;
      }
      // if (Platform.isMacOS) {
      //   await Process.run('open', [directoryPath]);
      //   return;
      // }
      // if (Platform.isLinux) {
      //   await Process.run('xdg-open', [directoryPath]);
      //   return;
      // }
      _showMessage(context.l10n.openDirectoryUnsupported);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.openDirectoryFailed(error.toString()));
    }
  }

  Future<void> _openExportedPdf(String outputPath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', outputPath]);
        return;
      }
      if (Platform.isMacOS) {
        await Process.run('open', [outputPath]);
        return;
      }
      if (Platform.isLinux) {
        await Process.run('xdg-open', [outputPath]);
        return;
      }
      _showMessage(context.l10n.openPdfUnsupported);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.openPdfFailed(error.toString()));
    }
  }

  void _showMessage(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  void _dismissStatusMessage() {
    if (_statusMessage == null) {
      return;
    }
    setState(() {
      _statusMessage = null;
    });
  }
}

enum _AndroidExportAction {
  save,
  share,
}

class _AndroidExportDecision {
  const _AndroidExportDecision({
    required this.action,
    required this.doNotAskAgain,
  });

  final _AndroidExportAction action;
  final bool doNotAskAgain;
}

enum _CompactToolbarAction {
  openPdf,
  zoomOut,
  zoomIn,
  recalculateCurrent,
  recalculateAll,
  addRect,
  removeRect,
  splitVertical,
  splitHorizontal,
  copyRects,
  pasteRects,
  applyAll,
  applyEven,
  applyOdd,
}

class _ClusterTile extends StatelessWidget {
  const _ClusterTile({
    required this.cluster,
    required this.pageLabel,
    required this.selected,
    required this.multiSelected,
    required this.onTap,
    required this.onCheckChanged,
  });

  final PageCluster cluster;
  final String pageLabel;
  final bool selected;
  final bool multiSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onCheckChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.72)
          : Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      cluster.previewImageBytes,
                      width: 64,
                      height: 86,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _ClusterBadge(
                              label: cluster.parityLabel,
                              selected: selected,
                              emphasized: false,
                            ),
                            _ClusterBadge(
                              label: cluster.layoutLabel,
                              selected: selected,
                              emphasized: true,
                            ),
                            if (cluster.containsOutlierPage)
                              _ClusterBadge(
                                label: l10n.outlierPage,
                                selected: selected,
                                emphasized: false,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.pageCountLabel(cluster.pages.length),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pageLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: multiSelected,
                  onChanged: onCheckChanged,
                  visualDensity: VisualDensity.compact,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.primary;
                    }
                    return Colors.transparent;
                  }),
                  side: BorderSide(
                    color: multiSelected ? colorScheme.primary : colorScheme.outline,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClusterBadge extends StatelessWidget {
  const _ClusterBadge({
    required this.label,
    required this.selected,
    required this.emphasized,
  });

  final String label;
  final bool selected;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = emphasized
        ? colorScheme.primary.withValues(alpha: selected ? 0.18 : 0.12)
        : colorScheme.surfaceContainerHighest.withValues(alpha: selected ? 0.62 : 0.82);
    final foregroundColor = emphasized
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
