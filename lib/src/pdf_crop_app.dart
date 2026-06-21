import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import 'l10n/app_localizations.dart';
import 'models/app_grouping_settings.dart';
import 'models/app_theme_settings.dart';
import 'models/cluster_settings.dart';
import 'pdf_editor_page.dart';
import 'services/android_incoming_pdf_service.dart';
import 'services/android_document_tree_service.dart';
import 'services/app_settings_service.dart';
import 'services/cache_service.dart';
import 'services/windowing_service.dart';
import 'settings_page.dart';
import 'state/pdf_editor_controller.dart';
import 'state/theme_controller.dart';
import 'widgets/status_corner_card.dart';
import 'widgets/windows_window_controls.dart';

class PdfCropApp extends StatefulWidget {
  const PdfCropApp({
    required this.themeController,
    this.initialPdfPath,
    super.key,
  });

  final ThemeController themeController;
  final String? initialPdfPath;

  @override
  State<PdfCropApp> createState() => _PdfCropAppState();
}

class _PdfCropAppState extends State<PdfCropApp> {
  late final PdfEditorController _controller;
  late final AppSettingsService _appSettingsService;
  late final AndroidIncomingPdfService _incomingPdfService;
  late final AndroidDocumentTreeService _androidDocumentTreeService;
  late final CacheService _cacheService;
  bool _draggingPdf = false;
  bool _handledInitialPdf = false;
  String? _statusMessage;
  AppGroupingSettings _groupingSettings = const AppGroupingSettings();
  bool _isBatchCropping = false;
  double? _batchProgress;
  String? _batchStatus;

  bool get _supportsHomeDropTarget =>
      defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS;
  bool get _supportsBatchCrop =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _controller = PdfEditorController();
    _appSettingsService = AppSettingsService();
    _incomingPdfService = AndroidIncomingPdfService();
    _androidDocumentTreeService = AndroidDocumentTreeService();
    _cacheService = CacheService();
    _controller.addListener(_onControllerChanged);
    _loadGroupingSettings();
    _bindIncomingPdfService();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _incomingPdfService.unbind();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadGroupingSettings() async {
    await _appSettingsService.init();
    final settings = _appSettingsService.loadGroupingSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _groupingSettings = settings;
    });
    await _maybeOpenInitialPdf();
  }

  Future<void> _maybeOpenInitialPdf() async {
    if (_handledInitialPdf) {
      return;
    }
    final path = widget.initialPdfPath;
    if (path == null || path.isEmpty) {
      return;
    }
    _handledInitialPdf = true;
    if (!_isPdfPath(path)) {
      _showMessage(context.l10n.notPdfInLaunchArgs(path));
      return;
    }
    if (!mounted) {
      return;
    }
    await _openPdfAndNavigate(path);
  }

  Future<void> _bindIncomingPdfService() async {
    try {
      await _incomingPdfService.bind(
        onIncomingPdf: _handleIncomingPdfPath,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.externalPdfFailed(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const WindowsDragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('ProCropper PDF'),
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            onPressed: _openSettingsPage,
            icon: const Icon(Icons.settings_outlined),
          ),
          const WindowsWindowControls(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: _supportsHomeDropTarget
                        ? DropTarget(
                            onDragEntered: (_) {
                              if (!_draggingPdf) {
                                setState(() => _draggingPdf = true);
                              }
                            },
                            onDragExited: (_) {
                              if (_draggingPdf) {
                                setState(() => _draggingPdf = false);
                              }
                            },
                            onDragDone: (detail) => _handleDropFiles(detail.files),
                            child: _buildHomeCard(context),
                          )
                        : _buildHomeCard(context),
                  ),
                ),
              );
            },
          ),
          if (_statusMessage != null)
            StatusCornerCard(
              title: l10n.tips,
              message: _statusMessage!,
              icon: Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
              ),
              bottom: _controller.isBusy ? 186 : 18,
              onClose: _dismissStatusMessage,
            ),
          if (_controller.isBusy)
            StatusCornerCard(
              title: l10n.processing,
              message: _controller.status ?? l10n.processingTask,
              bottom: _statusMessage != null ? 186 : 18,
            ),
          if (_isBatchCropping)
            StatusCornerCard(
              title: l10n.batching,
              message: _batchStatus ?? l10n.batchPreparing,
              progress: _batchProgress,
              bottom: _statusMessage != null
                  ? (_controller.isBusy ? 354 : 186)
                  : (_controller.isBusy ? 186 : 18),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeCard(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: _draggingPdf ? 0.24 : 0.16),
              colorScheme.surfaceContainerLow,
            ),
            colorScheme.surfaceContainerLowest,
          ],
        ),
        border: Border.all(
          color: _draggingPdf ? colorScheme.primary : colorScheme.outlineVariant,
          width: _draggingPdf ? 2.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: _draggingPdf ? 0.18 : 0.12),
            blurRadius: 36,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _draggingPdf ? Icons.file_download_done_rounded : Icons.picture_as_pdf_rounded,
              size: 54,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _draggingPdf ? l10n.releaseToImportPdf : l10n.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _draggingPdf
                ? l10n.dropPdfToOpen
                : (_supportsHomeDropTarget ? l10n.pickOrDropPdf : l10n.pickPdfOnly),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _pickPdfAndOpenEditor,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(l10n.cropPdf),
          ),
          if (_supportsBatchCrop) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isBatchCropping ? null : _runBatchCrop,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: Text(l10n.batchCrop),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickPdfAndOpenEditor() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null || !mounted) {
        return;
      }
      await _openPdfAndNavigate(path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.openPdfFailedPrefix + error.toString());
    }
  }

  Future<void> _runBatchCrop() async {
    final l10n = context.l10n;
    if (!_supportsBatchCrop) {
      _showMessage(l10n.batchCropUnsupported);
      return;
    }

    if (Platform.isAndroid) {
      await _runAndroidBatchCrop();
      return;
    }

    final inputDirectory = await _pickDirectory(
      title: l10n.selectBatchInputDirectory,
    );
    if (inputDirectory == null || inputDirectory.isEmpty) {
      return;
    }

    final outputDirectory = await _pickDirectory(
      title: l10n.selectBatchOutputDirectory,
    );
    if (outputDirectory == null || outputDirectory.isEmpty) {
      return;
    }

    setState(() {
      _isBatchCropping = true;
      _batchProgress = null;
      _batchStatus = l10n.batchPreparing;
      _statusMessage = null;
    });

    try {
      setState(() {
        _batchStatus = l10n.batchScanningDirectory(inputDirectory);
      });

      final normalizedInputDirectory = p.normalize(p.absolute(inputDirectory));
      final normalizedOutputDirectory = p.normalize(p.absolute(outputDirectory));
      final shouldExcludeOutputDirectory =
          normalizedInputDirectory != normalizedOutputDirectory &&
          _isPathInsideDirectory(
            normalizedOutputDirectory,
            normalizedInputDirectory,
          );
      final pdfFiles = Directory(inputDirectory)
          .listSync(
            recursive: _groupingSettings.batchCropRecursive,
            followLinks: false,
          )
          .whereType<File>()
          .where(
            (file) =>
                !shouldExcludeOutputDirectory ||
                !_isPathInsideDirectory(
                  file.path,
                  normalizedOutputDirectory,
                ),
          )
          .where((file) => _isPdfPath(file.path))
          .toList()
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

      if (pdfFiles.isEmpty) {
        _showMessage(l10n.batchNoPdfFound(inputDirectory));
        return;
      }

      var successCount = 0;
      final failures = <String>[];

      for (var index = 0; index < pdfFiles.length; index++) {
        final file = pdfFiles[index];
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : file.path.split(RegExp(r'[\\/]')).last;

        if (!mounted) {
          return;
        }

        setState(() {
          _batchProgress = index / pdfFiles.length;
          _batchStatus = l10n.batchProcessingFile(
            index + 1,
            pdfFiles.length,
            fileName,
          );
        });

        final batchController = PdfEditorController();
        try {
          await batchController.openFile(
            file.path,
            initialSettings: ClusterSettings(
              smartGroupingLevel: _groupingSettings.defaultSmartGroupingLevel,
              separateOddEven: _groupingSettings.defaultSeparateOddEven,
            ),
            passwordProvider: _buildPasswordProvider(
              file.path,
              dialogTitle: l10n.batchPasswordPromptTitle(fileName),
            ),
          );
          final outputPath = _buildBatchOutputPath(
            inputDirectory: normalizedInputDirectory,
            sourcePath: file.path,
            outputDirectory: normalizedOutputDirectory,
          );
          await Directory(p.dirname(outputPath)).create(recursive: true);
          await batchController.export(destinationPath: outputPath);
          successCount++;
        } catch (error) {
          failures.add('$fileName: ${_normalizeBatchFailure(error)}');
        } finally {
          await batchController.disposeProject();
          batchController.dispose();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _batchProgress = 1;
        _batchStatus = l10n.batchCompleted(
          successCount,
          failures.length,
        );
      });

      if (failures.isEmpty) {
        _showMessage(l10n.batchCompleted(successCount, 0));
      } else {
        _showMessage(
          l10n.batchPartialFailureSummary(
            successCount,
            failures.length,
            failures.take(5).join('\n'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.batchFailedWithDetails(error.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isBatchCropping = false;
        });
      }
    }
  }

  Future<void> _runAndroidBatchCrop() async {
    final l10n = context.l10n;
    final confirmedInput = await _showBatchDirectoryPrompt(
      title: l10n.batchInputDirectoryPromptTitle,
      description: l10n.batchInputDirectoryPromptDescription,
    );
    if (confirmedInput != true) {
      return;
    }

    final inputTreeUri = await _androidDocumentTreeService.pickDirectoryTree();
    if (inputTreeUri == null || inputTreeUri.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }
    final confirmedOutput = await _showBatchDirectoryPrompt(
      title: l10n.batchOutputDirectoryPromptTitle,
      description: l10n.batchOutputDirectoryPromptDescription,
    );
    if (confirmedOutput != true) {
      return;
    }

    final outputTreeUri = await _androidDocumentTreeService.pickDirectoryTree();
    if (outputTreeUri == null || outputTreeUri.isEmpty) {
      return;
    }

    setState(() {
      _isBatchCropping = true;
      _batchProgress = null;
      _batchStatus = l10n.batchPreparing;
      _statusMessage = null;
    });

    try {
      setState(() {
        _batchStatus = l10n.batchScanningDirectory(l10n.selectBatchInputDirectory);
      });

      final pdfFiles = await _androidDocumentTreeService.listPdfFilesInTree(
        treeUri: inputTreeUri,
        recursive: _groupingSettings.batchCropRecursive,
      );

      if (pdfFiles.isEmpty) {
        _showMessage(l10n.batchNoPdfFound(l10n.selectBatchInputDirectory));
        return;
      }

      final sortedFiles = [...pdfFiles]
        ..sort((a, b) {
          final aPath = '${a.relativeDirectory}/${a.fileName}'.toLowerCase();
          final bPath = '${b.relativeDirectory}/${b.fileName}'.toLowerCase();
          return aPath.compareTo(bPath);
        });

      var successCount = 0;
      final failures = <String>[];

      for (var index = 0; index < sortedFiles.length; index++) {
        final file = sortedFiles[index];
        if (!mounted) {
          return;
        }

        setState(() {
          _batchProgress = index / sortedFiles.length;
          _batchStatus = l10n.batchProcessingFile(
            index + 1,
            sortedFiles.length,
            file.fileName,
          );
        });

        final cachedInputPath = await _androidDocumentTreeService.copyTreeFileToCache(
          documentUri: file.uri,
          fileName: file.fileName,
        );
        if (cachedInputPath == null || cachedInputPath.isEmpty) {
          failures.add('${file.fileName}: ${l10n.batchFailedToReadSourceFile}');
          continue;
        }

        final batchController = PdfEditorController();
        String? temporaryExportPath;
        try {
          await batchController.openFile(
            cachedInputPath,
            initialSettings: ClusterSettings(
              smartGroupingLevel: _groupingSettings.defaultSmartGroupingLevel,
              separateOddEven: _groupingSettings.defaultSeparateOddEven,
            ),
            passwordProvider: _buildPasswordProvider(
              cachedInputPath,
              dialogTitle: l10n.batchPasswordPromptTitle(file.fileName),
            ),
          );
          temporaryExportPath = await batchController.createTemporaryExportPath();
          if (temporaryExportPath == null || temporaryExportPath.isEmpty) {
            throw StateError('Failed to create temporary export path.');
          }
          await batchController.export(destinationPath: temporaryExportPath);
          await _androidDocumentTreeService.writeFileToTree(
            treeUri: outputTreeUri,
            relativeDirectory: file.relativeDirectory,
            fileName: _suggestedOutputFileName(file.fileName),
            sourcePath: temporaryExportPath,
          );
          successCount++;
        } catch (error) {
          failures.add('${file.fileName}: ${_normalizeBatchFailure(error)}');
        } finally {
          if (temporaryExportPath != null) {
            try {
              await batchController.deleteTemporaryExport(temporaryExportPath);
            } catch (_) {
              // Ignore per-file temp export cleanup failure.
            }
          }
          try {
            final cachedInputFile = File(cachedInputPath);
            if (await cachedInputFile.exists()) {
              await cachedInputFile.delete();
            }
          } catch (_) {
            // Ignore per-file input cache cleanup failure.
          }
          await batchController.disposeProject();
          batchController.dispose();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _batchProgress = 1;
        _batchStatus = l10n.batchCompleted(
          successCount,
          failures.length,
        );
      });

      if (failures.isEmpty) {
        _showMessage(l10n.batchCompleted(successCount, 0));
      } else {
        _showMessage(
          l10n.batchPartialFailureSummary(
            successCount,
            failures.length,
            failures.take(5).join('\n'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(l10n.batchFailedWithDetails(error.toString()));
    } finally {
      if (mounted) {
        setState(() {
          _isBatchCropping = false;
        });
      }
      await _clearExportCacheSilently();
    }
  }

  Future<bool?> _showBatchDirectoryPrompt({
    required String title,
    required String description,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.continueToSelectFolder),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDropFiles(List<dynamic> files) async {
    if (!_supportsHomeDropTarget) {
      return;
    }
    if (_draggingPdf && mounted) {
      setState(() => _draggingPdf = false);
    }
    final dynamic droppedPdf = files.cast<dynamic>().firstWhere(
          (file) => file != null && _isPdfPath(file.path as String),
          orElse: () => null,
        );
    final path = droppedPdf?.path as String?;
    if (path == null) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.pleaseDropPdf);
      return;
    }
    await _openPdfAndNavigate(path);
  }

  Future<void> _openPdfAndNavigate(String path) async {
    final passwordProvider = _buildPasswordProvider(path);
    if (widget.themeController.settings.multiWindowMode &&
        isFlutterWindowingAvailable) {
      final windowController = PdfEditorController();
      try {
        await windowController.openFile(
          path,
          initialSettings: ClusterSettings(
            smartGroupingLevel: _groupingSettings.defaultSmartGroupingLevel,
            separateOddEven: _groupingSettings.defaultSeparateOddEven,
          ),
          passwordProvider: passwordProvider,
        );
        if (!mounted || windowController.project == null) {
          windowController.dispose();
          return;
        }
        final opened = openRegularEditorWindow(
          context: context,
          title: windowController.project!.fileName,
          onClosed: () async {
            await windowController.disposeProject();
            windowController.dispose();
            await _clearExportCacheSilently();
          },
          builder: (context) => PdfEditorPage(
            controller: windowController,
            disablePanelTransparency: _shouldDisableEditorPanelTransparency(),
          ),
        );
        if (opened) {
          return;
        }
        await windowController.disposeProject();
        windowController.dispose();
      } catch (_) {
        windowController.dispose();
        rethrow;
      }
    }

    await _controller.openFile(
      path,
      initialSettings: ClusterSettings(
        smartGroupingLevel: _groupingSettings.defaultSmartGroupingLevel,
        separateOddEven: _groupingSettings.defaultSeparateOddEven,
      ),
      passwordProvider: passwordProvider,
    );
    if (!mounted || _controller.project == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PdfEditorPage(
          controller: _controller,
          disablePanelTransparency: _shouldDisableEditorPanelTransparency(),
        ),
      ),
    );
    await _clearExportCacheSilently();
  }

  Future<void> _handleIncomingPdfPath(String path) async {
    if (!mounted) {
      return;
    }
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (!mounted) {
        return;
      }
      await _openPdfAndNavigate(path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context.l10n.externalPdfOpenFailed(error.toString()));
    }
  }

  bool _isPdfPath(String path) => path.toLowerCase().endsWith('.pdf');

  String _buildBatchOutputPath({
    required String inputDirectory,
    required String sourcePath,
    required String outputDirectory,
  }) {
    final normalizedSourcePath = p.normalize(p.absolute(sourcePath));
    final relativeSourcePath = p.relative(
      normalizedSourcePath,
      from: inputDirectory,
    );
    final sourceDirectory = p.dirname(relativeSourcePath);
    final sourceFileName = p.basename(relativeSourcePath);
    final outputFileName = _suggestedOutputFileName(sourceFileName);
    return sourceDirectory == '.' || sourceDirectory.isEmpty
        ? p.join(outputDirectory, outputFileName)
        : p.join(outputDirectory, sourceDirectory, outputFileName);
  }

  Future<String?> _pickDirectory({required String title}) async {
    if (Platform.isMacOS) {
      final result = await FilePicker.pickFileAndDirectoryPaths(
        type: FileType.any,
      );
      if (result == null || result.isEmpty) {
        return null;
      }
      final selectedPath = result.first;
      final entityType = FileSystemEntity.typeSync(selectedPath);
      if (entityType == FileSystemEntityType.directory) {
        return selectedPath;
      }
      return p.dirname(selectedPath);
    }
    return FilePicker.getDirectoryPath(dialogTitle: title);
  }

  bool _isPathInsideDirectory(String targetPath, String directoryPath) {
    final normalizedTargetPath = p.normalize(p.absolute(targetPath));
    final normalizedDirectoryPath = p.normalize(p.absolute(directoryPath));
    return normalizedTargetPath == normalizedDirectoryPath ||
        p.isWithin(normalizedDirectoryPath, normalizedTargetPath);
  }

  String _suggestedOutputFileName(String fileName) {
    if (_groupingSettings.useOriginalFileNameForExport) {
      return fileName;
    }
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return AppLocalizations.current.croppedFileName(fileName);
    }
    return AppLocalizations.current.croppedFileNameFallback(fileName);
  }

  PdfPasswordProvider _buildPasswordProvider(
    String path, {
    String? dialogTitle,
  }) {
    var attemptCount = 0;
    return () async {
      if (!mounted) {
        return null;
      }
      if (attemptCount == 0) {
        attemptCount++;
        return '';
      }
      final password = await _promptPdfPassword(
        path,
        dialogTitle: dialogTitle,
        wrongPassword: attemptCount > 1,
      );
      if (password != null) {
        attemptCount++;
      }
      return password;
    };
  }

  Future<String?> _promptPdfPassword(
    String path, {
    String? dialogTitle,
    bool wrongPassword = false,
  }) async {
    final passwordController = TextEditingController();
    final fileName = p.basename(path);
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(dialogTitle ?? l10n.passwordProtectedPdf),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.passwordRequiredForPdf(fileName)),
              if (wrongPassword) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.wrongPdfPassword,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                onSubmitted: (value) =>
                    Navigator.of(context).pop(value.trim().isEmpty ? null : value),
                decoration: InputDecoration(
                  labelText: l10n.pdfPassword,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final value = passwordController.text.trim();
                Navigator.of(context).pop(value.isEmpty ? null : value);
              },
              child: Text(l10n.open),
            ),
          ],
        );
      },
    );
    passwordController.dispose();
    return password;
  }

  String _normalizeBatchFailure(Object error) {
    if (error is PdfPasswordException) {
      return context.l10n.batchPasswordSkipped;
    }
    return error.toString();
  }

  Future<void> _openSettingsPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsPage(
          themeController: widget.themeController,
        ),
      ),
    );
    await _loadGroupingSettings();
  }

  Future<void> _clearExportCacheSilently() async {
    try {
      await _cacheService.clearTemporaryFiles();
    } catch (_) {
      // Ignore cache cleanup failures when returning to the home page.
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

  bool _shouldDisableEditorPanelTransparency() {
    if (!Platform.isWindows) {
      return false;
    }
    final settings = widget.themeController.settings;
    final brightness = switch (settings.themeMode) {
      AppThemeMode.system =>
        View.of(context).platformDispatcher.platformBrightness,
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
    };
    final eInkActive =
        settings.eInkOptimized && brightness == Brightness.light;
    return settings.windowsMicaEnabled && !eInkActive;
  }
}
