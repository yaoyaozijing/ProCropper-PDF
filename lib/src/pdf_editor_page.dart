import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'models/page_cluster.dart';
import 'state/pdf_editor_controller.dart';
import 'widgets/crop_editor.dart';
import 'widgets/status_corner_card.dart';

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
  static const double _clusterPanelWidth = 350;
  static const double _toolPanelWidth = 188;
  String? _statusMessage;
  bool _showClusterPanel = true;
  bool _showToolPanel = true;

  PdfEditorController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
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

  @override
  Widget build(BuildContext context) {
    final project = _controller.project;
    final cluster = _controller.selectedCluster;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 108,
        leading: Row(
          children: [
            const BackButton(),
            IconButton(
              tooltip: _showClusterPanel ? '收起分组栏' : '展开分组栏',
              onPressed: () {
                setState(() {
                  _showClusterPanel = !_showClusterPanel;
                });
              },
              icon: Icon(Icons.menu),
            ),
          ],
        ),
        title: Text(
          project?.fileName ?? '未加载 PDF',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: '缩小',
            onPressed: project == null ? null : _viewportController.zoomOut,
            icon: const Icon(Icons.zoom_out_rounded),
          ),
          IconButton(
            tooltip: '放大',
            onPressed: project == null ? null : _viewportController.zoomIn,
            icon: const Icon(Icons.zoom_in_rounded),
          ),
          IconButton(
            tooltip: _showToolPanel ? '收起工具栏' : '展开工具栏',
            onPressed: () {
              setState(() {
                _showToolPanel = !_showToolPanel;
              });
            },
            icon: Icon(Icons.info),
          ),
          TextButton.icon(
            onPressed: _controller.isBusy ? null : _pickPdf,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('打开'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: project == null || _controller.isBusy ? null : _exportPdf,
            icon: const Icon(Icons.download_rounded),
            label: const Text('导出'),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: Stack(
        children: [
          if (project != null && cluster != null) _buildEditor(cluster) else _buildMissingProject(),
          if (_statusMessage != null)
            StatusCornerCard(
              title: '提示',
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
              title: '正在处理',
              message: _controller.status ?? '正在处理任务...',
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
    return Center(
      child: FilledButton.icon(
        onPressed: _pickPdf,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('重新打开 PDF'),
      ),
    );
  }

  Widget _buildEditor(PageCluster cluster) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: CropEditor(
            previewBytes: cluster.previewImageBytes,
            previewSize: cluster.previewSize,
            cropRects: cluster.cropRects,
            selectedRectIndex: _controller.selectedRectIndex,
            colorScheme: colorScheme,
            onRectSelected: _controller.selectRect,
            onRectChanged: _controller.updateSelectedRect,
            onRectInfoRequested: _showRectInfoDialog,
            contentPadding: EdgeInsets.fromLTRB(
              _showClusterPanel ? _clusterPanelWidth + 36 : 18,
              18,
              _showToolPanel ? _toolPanelWidth + 36 : 18,
              18,
            ),
            viewportController: _viewportController,
          ),
        ),
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
                  child: Column(
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
                              onTap: () => _controller.selectCluster(index),
                              onCheckChanged: (value) => _toggleClusterSelection(index, value),
                            );
                          },
                        ),
                      ),
                      _buildSidebarFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

  Widget _buildSidebarFooter() {
    final project = _controller.project!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '共 ${project.pageCount} 页， ${project.clusters.length} 个分组',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: _showLocatePageDialog,
            icon: const Icon(Icons.search_rounded),
            label: const Text('定位'),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterActionsBar() {
    final canMerge = _selectedClusterIndices.length >= 2;
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
                  label: const Text('重置'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canMerge ? _mergeSelectedClusters : null,
                  icon: const Icon(Icons.merge_type_rounded),
                  label: Text('合并'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSplitPagesDialog,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('新建'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarPanel() {
    final theme = Theme.of(context);
    return _buildFloatingPanel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '工具',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildToolbarButton(
                onPressed: _controller.recalculateAutoCropForSelectedCluster,
                icon: Icons.auto_awesome_rounded,
                label: '计算当前',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.recalculateAutoCropForAllClusters,
                icon: Icons.auto_awesome_rounded,
                label: '计算全部',
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: _controller.addRect,
                icon: Icons.add_rounded,
                label: '添加裁剪框',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.removeSelectedRect,
                icon: Icons.delete_outline,
                label: '移除当前框',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.splitSelectedRectVertically,
                icon: Icons.view_week_outlined,
                label: '水平拆分',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.splitSelectedRectHorizontally,
                icon: Icons.view_agenda_outlined,
                label: '垂直拆分',
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: _controller.copyCurrentRects,
                icon: Icons.copy_all_outlined,
                label: '复制方案',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: _controller.hasClipboard ? _controller.pasteRectsToSelectedCluster : null,
                icon: Icons.assignment_return_outlined,
                label: '粘贴方案',
              ),
              const SizedBox(height: 14),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 14),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.currentCluster),
                icon: Icons.vertical_align_center_rounded,
                label: '应用到当前',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.allClusters),
                icon: Icons.select_all_rounded,
                label: '应用到全部',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.evenClusters),
                icon: Icons.filter_2_rounded,
                label: '应用到偶数',
              ),
              const SizedBox(height: 10),
              _buildToolbarButton(
                onPressed: () => _controller.applyCurrentRectsTo(ApplyTarget.oddClusters),
                icon: Icons.filter_1_rounded,
                label: '应用到奇数',
              ),
            ],
          ),
        ),
      ),
    );
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
    final theme = Theme.of(context);
    final progress = _controller.exportProgress;
    final isDone = !_controller.isExporting && _controller.lastExportPath != null;
    final hasError = !_controller.isExporting && _controller.lastExportError != null;
    final title = isDone
        ? '导出完成'
        : hasError
            ? '导出失败'
            : '正在后台导出';
    final message = isDone
        ? _controller.lastExportPath!
        : hasError
            ? _controller.lastExportError!
            : (_controller.exportStatus ?? '正在处理导出任务...');

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
                    tooltip: '关闭',
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
                const SizedBox(height: 8),
                Text(
                  '导出期间仍可继续浏览当前界面。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (isDone && !Platform.isAndroid) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _openExportedPdf(_controller.lastExportPath!),
                      icon: const Icon(Icons.file_open_rounded),
                      label: const Text('打开 PDF'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonalIcon(
                      onPressed: () => _openExportDirectory(_controller.lastExportPath!),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('打开目录'),
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
                    child: const Text('关闭'),
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
      _showMessage('打开 PDF 失败：$error');
    }
  }

  Future<void> _exportPdf() async {
    try {
      if (Platform.isAndroid) {
        final destinationUri = await _controller.createAndroidDocumentUri(
          fileName: _suggestedOutputFileName(),
        );
        if (destinationUri == null) {
          return;
        }
        await _controller.export(destinationUri: destinationUri);
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
      _showMessage('导出失败：$error');
    }
  }

  Future<String?> _resolveExportDestinationPath() async {
    final result = await FilePicker.saveFile(
      dialogTitle: '保存裁边后的 PDF',
      fileName: _suggestedOutputFileName(),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return result;
  }

  Future<void> _showRegroupDialog() async {
    final currentSettings = _controller.settings;
    final oddEven = ValueNotifier<bool>(currentSettings.separateOddEven);
    final excludedText = TextEditingController(
      text: _formatExcludedPages(currentSettings.excludedPages),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重新分组设置'),
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
                      title: const Text('区分奇偶页'),
                      subtitle: const Text('关闭后，奇偶页会按尺寸合并到同一类分组。'),
                      value: value,
                      onChanged: (next) => oddEven.value = next,
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text('排除页码'),
                const SizedBox(height: 6),
                TextField(
                  controller: excludedText,
                  decoration: const InputDecoration(
                    hintText: '例如：1, 3, 5-8',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '这些页面不会参与自动分组与预览生成。',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('应用'),
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
        );
        _selectedClusterIndices.clear();
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage('重新分组失败：$error');
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
      _showMessage('合并分组失败：$error');
    }
  }

  Future<void> _showSplitPagesDialog() async {
    final project = _controller.project;
    if (project == null) {
      return;
    }

    final pageTextController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建分组'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('输入要归入新分组的页码。创建后，这些页会自动从其它分组中移除。'),
                const SizedBox(height: 12),
                TextField(
                  controller: pageTextController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '例如：1, 3, 5-8',
                    border: const OutlineInputBorder(),
                    helperText: '总页数：${project.pageCount} 页',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('创建分组'),
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
          throw const FormatException('请输入有效页码。');
        }
        await _controller.createClusterFromPages(selectedPages);
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage('新建分组失败：$error');
      }
    }

    pageTextController.dispose();
  }

  Future<void> _showLocatePageDialog() async {
    final project = _controller.project;
    if (project == null) {
      return;
    }

    final pageTextController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('定位页面所在分组'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('输入页码后，将自动定位到包含该页的分组。'),
                const SizedBox(height: 12),
                TextField(
                  controller: pageTextController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '例如：12',
                    border: const OutlineInputBorder(),
                    helperText: '总页数：${project.pageCount} 页',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('定位'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final page = int.parse(pageTextController.text.trim());
        if (page < 1 || page > project.pageCount) {
          throw FormatException('页码超出范围，请输入 1 到 ${project.pageCount} 之间的数字。');
        }
        final clusterIndex = _controller.clusters.indexWhere((cluster) => cluster.pages.contains(page));
        if (clusterIndex == -1) {
          throw const FormatException('没有在任何分组中找到该页。');
        }
        _controller.selectCluster(clusterIndex);
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage('查找页面失败：$error');
      }
    }

    pageTextController.dispose();
  }

  void _showRectInfoDialog(int index) {
    final cluster = _controller.selectedCluster;
    if (cluster == null || index < 0 || index >= cluster.cropRects.length) {
      return;
    }
    final rect = cluster.cropRects[index];
    _controller.selectRect(index);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('裁剪框 #${index + 1}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '左 ${(rect.left * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 8),
                Text(
                  '上 ${(rect.top * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 8),
                Text(
                  '右 ${(rect.right * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 8),
                Text(
                  '下 ${(rect.bottom * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 12),
                Text(
                  '宽 ${(rect.width * 100).toStringAsFixed(1)}%  高 ${(rect.height * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
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
          throw FormatException('页码格式不正确：$part');
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
          throw FormatException('页码格式不正确：$part');
        }
        result.add(page);
      }
    }
    return result;
  }

  String _formatExcludedPages(Set<int> pages) {
    final sorted = pages.toList()..sort();
    return sorted.join(', ');
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

  String _suggestedOutputFileName() {
    final fileName = _controller.project?.fileName ?? 'output.pdf';
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return '${fileName.substring(0, fileName.length - 4)}_裁边后.pdf';
    }
    return '${fileName}_裁边后.pdf';
  }

  Future<void> _openExportDirectory(String outputPath) async {
    final directoryPath = p.dirname(outputPath);
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [directoryPath]);
        return;
      }
      if (Platform.isMacOS) {
        await Process.run('open', [directoryPath]);
        return;
      }
      if (Platform.isLinux) {
        await Process.run('xdg-open', [directoryPath]);
        return;
      }
      _showMessage('当前平台暂不支持自动打开目录。');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('打开目录失败：$error');
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
      _showMessage('当前平台暂不支持自动打开 PDF。');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('打开 PDF 失败：$error');
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
                        Text(
                          cluster.parityLabel,
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '共 ${cluster.pages.length} 页',
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
