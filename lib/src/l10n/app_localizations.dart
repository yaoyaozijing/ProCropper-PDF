import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations current = AppLocalizations(const Locale('zh', 'CN'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(value != null, 'No AppLocalizations found in context.');
    return value!;
  }

  bool get isZh => locale.languageCode.toLowerCase().startsWith('zh');

  String get appName => 'ProCropper PDF';
  String get settings => isZh ? '设置' : 'Settings';
  String get themeSettings => isZh ? '主题设置' : 'Theme Settings';
  String get appearanceSettings => isZh ? '外观设置' : 'Appearance Settings';
  String get tips => isZh ? '提示' : 'Tip';
  String get processing => isZh ? '正在处理' : 'Processing';
  String get processingTask => isZh ? '正在处理任务...' : 'Processing task...';
  String get editPdf => isZh ? '编辑 PDF' : 'Edit PDF';
  String get releaseToImportPdf =>
      isZh ? '松开即可导入 PDF' : 'Release to import PDF';
  String get dropPdfToOpen => isZh
      ? '把 PDF 文件拖到这个区域，松开后会直接进入编辑页。'
      : 'Drop a PDF file here to open it directly in the editor.';
  String get pickOrDropPdf => isZh
      ? '点击选择 PDF，或直接把 PDF 文件拖到这个区域开始编辑。'
      : 'Pick a PDF or drag one into this area to start editing.';
  String get openPdfFailedPrefix =>
      isZh ? '打开 PDF 失败：' : 'Failed to open PDF: ';
  String get pleaseDropPdf =>
      isZh ? '请拖入一个 PDF 文件。' : 'Please drop a PDF file.';
  String notPdfInLaunchArgs(String path) => isZh
      ? '启动参数中的文件不是 PDF：$path'
      : 'The launch argument is not a PDF: $path';
  String externalPdfFailed(String error) => isZh
      ? '接收外部 PDF 失败：$error'
      : 'Failed to receive external PDF: $error';
  String externalPdfOpenFailed(String error) => isZh
      ? '打开外部 PDF 失败：$error'
      : 'Failed to open external PDF: $error';
  String get close => isZh ? '关闭' : 'Close';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get apply => isZh ? '应用' : 'Apply';
  String get save => isZh ? '保存' : 'Save';
  String get share => isZh ? '分享' : 'Share';
  String get export => isZh ? '导出' : 'Export';
  String get open => isZh ? '打开' : 'Open';
  String get reopenPdf => isZh ? '重新打开 PDF' : 'Reopen PDF';
  String get openPdf => isZh ? '打开 PDF' : 'Open PDF';
  String get openDirectory => isZh ? '打开目录' : 'Open Folder';
  String get exportCompleted => isZh ? '导出完成' : 'Export Complete';
  String get exportFailed => isZh ? '导出失败' : 'Export Failed';
  String get exportingInBackground =>
      isZh ? '正在后台导出' : 'Exporting in Background';
  String get exportShareOpened =>
      isZh ? '分享窗口已打开。' : 'Share sheet opened.';
  String exportFailedWithError(String error) =>
      '${isZh ? '导出失败：' : 'Export failed: '}$error';
  String get chooseExportMethodTitle =>
      isZh ? '导出 PDF' : 'Export PDF';
  String get chooseExportMethodDescription => isZh
      ? '请选择导出方式。保存会写入你选择的位置，分享会先导出再打开系统分享窗口。'
      : 'Choose how to export. Save writes to your chosen location, while Share exports first and then opens the system share sheet.';
  String get doNotAskAgain => isZh ? '请勿询问' : "Don't ask again";
  String get rememberExportChoice => isZh
      ? '之后默认使用本次选择的导出方式。'
      : 'Use this export method by default from now on.';
  String get saveCroppedPdf =>
      isZh ? '保存裁边后的 PDF' : 'Save Cropped PDF';
  String get clusterPanelOpen =>
      isZh ? '打开分组面板' : 'Open Groups Panel';
  String get collapseClusterPanel =>
      isZh ? '收起分组栏' : 'Collapse Groups Panel';
  String get expandClusterPanel =>
      isZh ? '展开分组栏' : 'Expand Groups Panel';
  String get collapseToolbar =>
      isZh ? '收起工具栏' : 'Collapse Toolbar';
  String get expandToolbar =>
      isZh ? '展开工具栏' : 'Expand Toolbar';
  String get toolMenu => isZh ? '工具菜单' : 'Tools Menu';
  String get toolSection => isZh ? '工具' : 'Tools';
  String get zoomOut => isZh ? '缩小' : 'Zoom Out';
  String get zoomIn => isZh ? '放大' : 'Zoom In';
  String get recalculateCurrent => isZh ? '计算当前' : 'Recalculate Current';
  String get recalculateAll => isZh ? '计算全部' : 'Recalculate All';
  String get addCropRect => isZh ? '添加裁剪框' : 'Add Crop Box';
  String get removeCurrentRect => isZh ? '移除当前框' : 'Remove Current Box';
  String get splitHorizontal => isZh ? '水平拆分' : 'Split Horizontally';
  String get splitVertical => isZh ? '垂直拆分' : 'Split Vertically';
  String get copyPreset => isZh ? '复制方案' : 'Copy Preset';
  String get pastePreset => isZh ? '粘贴方案' : 'Paste Preset';
  String get applyToAll => isZh ? '应用到全部' : 'Apply to All';
  String get applyToEven => isZh ? '应用到偶数' : 'Apply to Even';
  String get applyToOdd => isZh ? '应用到奇数' : 'Apply to Odd';
  String summaryText({
    required int pageCount,
    required int clusterCount,
    required String excludedText,
    required String filterText,
  }) {
    return isZh
        ? '共 $pageCount 页，$clusterCount 个分组，排除$excludedText，过滤 $filterText'
        : '$pageCount pages, $clusterCount groups, excluded $excludedText, filter $filterText';
  }

  String get noExcludedPages => isZh ? '无' : 'none';
  String excludedPagesLabel(String ranges) =>
      isZh ? '第 $ranges 页' : 'pages $ranges';
  String get locatePageHint =>
      isZh ? '输入页码定位分组' : 'Enter a page number to locate its group';
  String get confirmLocate =>
      isZh ? '确认定位' : 'Confirm';
  String get locate => isZh ? '定位' : 'Locate';
  String get collapse => isZh ? '收起' : 'Collapse';
  String get reset => isZh ? '重置' : 'Reset';
  String get merge => isZh ? '合并' : 'Merge';
  String get create => isZh ? '新建' : 'Create';
  String get regroupSettings =>
      isZh ? '重新分组设置' : 'Regroup Settings';
  String get separateOddEven => isZh ? '区分奇偶页' : 'Separate Odd/Even Pages';
  String get separateOddEvenDescription => isZh
      ? '关闭后，奇偶页会按尺寸合并到同一类分组。'
      : 'When disabled, odd and even pages can be merged into the same size-based groups.';
  String get smartGroupingLevel =>
      isZh ? '智能分组等级' : 'Smart Grouping Level';
  String get edgeFilterPercentage =>
      isZh ? '四边过滤百分比' : 'Edge Filter Percentages';
  String get edgeFilterDescription => isZh
      ? '会先忽略页面四周对应比例的区域，再进行分组分析和自动识别。'
      : 'These edge percentages are ignored before grouping analysis and auto-detection.';
  String get ignoreHeaderFooter =>
      isZh ? '忽略页眉页脚' : 'Ignore Header/Footer';
  String get ignoreSideMarks =>
      isZh ? '忽略侧边标记' : 'Ignore Side Marks';
  String get gentleFilter => isZh ? '温和过滤' : 'Gentle Filter';
  String get leftPercent => isZh ? '左 %' : 'Left %';
  String get topPercent => isZh ? '上 %' : 'Top %';
  String get rightPercent => isZh ? '右 %' : 'Right %';
  String get bottomPercent => isZh ? '下 %' : 'Bottom %';
  String get excludedPages => isZh ? '排除页码' : 'Excluded Pages';
  String get pageRangeExample => isZh ? '例如：1, 3, 5-8' : 'For example: 1, 3, 5-8';
  String get excludedPagesDescription => isZh
      ? '这些页面不会参与自动分组与预览生成。'
      : 'These pages are excluded from automatic grouping and preview generation.';
  String regroupFailed(String error) =>
      '${isZh ? '重新分组失败：' : 'Failed to regroup: '}$error';
  String mergeFailed(String error) =>
      '${isZh ? '合并分组失败：' : 'Failed to merge groups: '}$error';
  String get createGroupTitle => isZh ? '新建分组' : 'Create Group';
  String get createGroupDescription => isZh
      ? '输入要归入新分组的页码。创建后，这些页会自动从其它分组中移除。'
      : 'Enter the pages to move into a new group. Those pages will be removed from other groups automatically.';
  String totalPagesHelper(int pageCount) =>
      isZh ? '总页数：$pageCount 页' : 'Total pages: $pageCount';
  String get createGroupAction => isZh ? '创建分组' : 'Create Group';
  String get invalidPageSelection =>
      isZh ? '请输入有效页码。' : 'Please enter valid page numbers.';
  String createGroupFailed(String error) =>
      '${isZh ? '新建分组失败：' : 'Failed to create group: '}$error';
  String pageOutOfRange(int pageCount) => isZh
      ? '页码超出范围，请输入 1 到 $pageCount 之间的数字。'
      : 'Page number out of range. Enter a number between 1 and $pageCount.';
  String get pageNotFoundInAnyGroup =>
      isZh ? '没有在任何分组中找到该页。' : 'That page was not found in any group.';
  String locatePageFailed(String error) =>
      '${isZh ? '查找页面失败：' : 'Failed to locate page: '}$error';
  String cropBoxTitle(int index) =>
      isZh ? '裁剪框 #$index' : 'Crop Box #$index';
  String pixelLeft(double value) =>
      isZh ? '左 ${_one(value)} px' : 'Left ${_one(value)} px';
  String pixelTop(double value) =>
      isZh ? '上 ${_one(value)} px' : 'Top ${_one(value)} px';
  String pixelRight(double value) =>
      isZh ? '右 ${_one(value)} px' : 'Right ${_one(value)} px';
  String pixelBottom(double value) =>
      isZh ? '下 ${_one(value)} px' : 'Bottom ${_one(value)} px';
  String pixelSize(double width, double height) => isZh
      ? '宽 ${_one(width)} px  高 ${_one(height)} px'
      : 'Width ${_one(width)} px  Height ${_one(height)} px';
  String get lockAspectRatio =>
      isZh ? '锁定纵横比' : 'Lock Aspect Ratio';
  String get lockAspectRatioDescription => isZh
      ? '拖动当前裁剪框时保持指定的长宽比例。'
      : 'Keep the selected crop box at the specified aspect ratio when dragging.';
  String get width => isZh ? '宽' : 'Width';
  String get height => isZh ? '高' : 'Height';
  String get aspectRatioPositive =>
      isZh ? '宽和高都必须大于 0。' : 'Width and height must both be greater than 0.';
  String aspectRatioFailed(String error) =>
      '${isZh ? '设置纵横比失败：' : 'Failed to set aspect ratio: '}$error';
  String invalidPageFormat(String part) =>
      '${isZh ? '页码格式不正确：' : 'Invalid page format: '}$part';
  String get groupingLevelBasic => isZh ? '基础' : 'Basic';
  String get groupingLevelBalanced => isZh ? '智能' : 'Smart';
  String get groupingLevelStrict => isZh ? '严格' : 'Strict';
  String get groupingLevelBasicDescription => isZh
      ? '仅按页面尺寸和奇偶页分组，速度最快。'
      : 'Groups only by page size and parity. Fastest option.';
  String get groupingLevelBalancedDescription => isZh
      ? '按尺寸粗分后，再结合页面版式指纹细分，适合大多数文档。'
      : 'Starts with page size and then refines using layout fingerprints. Good for most documents.';
  String get groupingLevelStrictDescription => isZh
      ? '更敏感地拆分不同版式页面，裁边更稳，但分组会更多。'
      : 'More aggressively separates layout variations. More stable crops, but more groups.';
  String invalidPercentFormat(String text) =>
      '${isZh ? '过滤百分比格式不正确：' : 'Invalid filter percentage: '}$text';
  String edgeFilterSummary({
    required String left,
    required String top,
    required String right,
    required String bottom,
  }) {
    return isZh
        ? '左$left 上$top 右$right 下$bottom'
        : 'L$left T$top R$right B$bottom';
  }

  String croppedFileName(String fileName) => isZh
      ? '${fileName.substring(0, fileName.length - 4)}_裁边后.pdf'
      : '${fileName.substring(0, fileName.length - 4)}_cropped.pdf';
  String croppedFileNameFallback(String fileName) =>
      isZh ? '${fileName}_裁边后.pdf' : '${fileName}_cropped.pdf';
  String get openDirectoryUnsupported =>
      isZh ? '当前平台暂不支持自动打开目录。' : 'Opening the export folder is not supported on this platform.';
  String openDirectoryFailed(String error) =>
      '${isZh ? '打开目录失败：' : 'Failed to open folder: '}$error';
  String get openPdfUnsupported =>
      isZh ? '当前平台暂不支持自动打开 PDF。' : 'Opening exported PDFs is not supported on this platform.';
  String openPdfFailed(String error) =>
      '${isZh ? '打开 PDF 失败：' : 'Failed to open PDF: '}$error';
  String get outlierPage => isZh ? '离群页' : 'Outlier';
  String pageCountLabel(int count) =>
      isZh ? '共 $count 页' : '$count pages';
  String get minimize => isZh ? '最小化' : 'Minimize';
  String get maximize => isZh ? '最大化' : 'Maximize';
  String get restore => isZh ? '还原' : 'Restore';
  String get darkMode => isZh ? '深色' : 'Dark';
  String get lightMode => isZh ? '浅色' : 'Light';
  String get systemMode => isZh ? '跟随系统' : 'Follow System';
  String get language => isZh ? '语言' : 'Language';
  String get simplifiedChinese => isZh ? '简体中文' : 'Simplified Chinese';
  String get english => isZh ? 'English' : 'English';
  String get languageSettingsDescription => isZh
      ? '默认跟随系统，也可以在应用内固定为中文或英文。'
      : 'Follows the system by default, or you can force Chinese or English in the app.';
  String get appearance => isZh ? '外观' : 'Appearance';
  String get themeColors => isZh ? '主题色' : 'Theme Colors';
  String get oledOptimization => isZh ? 'OLED 优化' : 'OLED Optimization';
  String get enableOledOptimization =>
      isZh ? '启用 OLED 优化' : 'Enable OLED Optimization';
  String get oledOnlyInDark =>
      isZh ? '仅在深色主题下生效' : 'Only takes effect in dark mode';
  String get jade => isZh ? '玉石绿' : 'Jade';
  String get amber => isZh ? '琥珀金' : 'Amber';
  String get ocean => isZh ? '海湾蓝' : 'Ocean';
  String get coral => isZh ? '珊瑚橙' : 'Coral';
  String get ruby => isZh ? '石榴红' : 'Ruby';
  String get graphite => isZh ? '石墨灰' : 'Graphite';
  String get documents => isZh ? '文档' : 'Documents';
  String get defaultGroupingMode =>
      isZh ? '默认分组模式' : 'Default Grouping Mode';
  String get defaultGroupingModeDescription => isZh
      ? '打开 PDF 时默认使用这个智能分组等级。'
      : 'This smart grouping level is used by default when opening PDFs.';
  String get defaultExportMode =>
      isZh ? '默认导出方式' : 'Default Export Mode';
  String get defaultExportModeDescription => isZh
      ? '用于安卓导出。可选择每次询问，或直接保存、直接分享。'
      : 'Used for Android export. Choose ask every time, save directly, or share directly.';
  String get clearCache => isZh ? '清理缓存' : 'Clear Cache';
  String get clearCacheDescription => isZh
      ? '清除应用临时目录中的导出缓存和残留文件。'
      : 'Remove export cache and leftover files from the app temporary directory.';
  String get about => isZh ? '关于' : 'About';
  String get versionLabel => isZh ? 'ProCropper PDF 版本' : 'ProCropper PDF Version';
  String get loading => isZh ? '读取中...' : 'Loading...';
  String get thirdPartyLicenses =>
      isZh ? 'Third Party Licences' : 'Third Party Licences';
  String get thirdPartyLicensesDescription =>
      isZh ? '查看第三方依赖许可信息' : 'View third-party dependency licenses';
  String cacheCleared(int count) => count > 0
      ? (isZh ? '已清理 $count 项缓存。' : 'Cleared $count cached item(s).')
      : (isZh ? '没有发现可清理的缓存。' : 'No cache found to clear.');
  String clearCacheFailed(String error) =>
      '${isZh ? '清理缓存失败：' : 'Failed to clear cache: '}$error';
  String get groupingModeBalanced => isZh ? '平衡' : 'Balanced';
  String get groupingModeBasicDescription => isZh
      ? '优先按基础尺寸分组，速度更快，细分更少。'
      : 'Prioritizes basic size grouping for higher speed and fewer splits.';
  String get groupingModeBalancedDescription => isZh
      ? '在准确度和分组数量之间保持平衡，适合作为默认模式。'
      : 'Balances accuracy and group count. Recommended as the default.';
  String get groupingModeStrictDescription => isZh
      ? '更积极地区分版式差异，适合页面结构变化较多的文档。'
      : 'More aggressively distinguishes layout differences. Best for documents with varied page structures.';
  String get askEveryTime => isZh ? '每次询问' : 'Ask Every Time';
  String get saveDirectly => isZh ? '直接保存' : 'Save Directly';
  String get shareDirectly => isZh ? '直接分享' : 'Share Directly';
  String get askEveryTimeDescription => isZh
      ? '每次导出时都先选择保存还是分享。'
      : 'Ask whether to save or share every time you export.';
  String get saveDirectlyDescription => isZh
      ? '直接进入保存流程，使用系统文档选择器。'
      : 'Go straight to the save flow using the system document picker.';
  String get shareDirectlyDescription => isZh
      ? '直接导出到临时文件，并打开系统分享窗口。'
      : 'Export directly to a temporary file and open the system share sheet.';
  String get loadingPdf => isZh ? '正在加载 PDF...' : 'Loading PDF...';
  String get recalculatingCurrentAutoCrop =>
      isZh ? '正在重新计算当前分组的自动裁边...' : 'Recalculating auto crop for the current group...';
  String get recalculatingAllAutoCrop =>
      isZh ? '正在重新计算全部分组的自动裁边...' : 'Recalculating auto crop for all groups...';
  String get regrouping => isZh ? '正在重新分组...' : 'Regrouping...';
  String get cannotMergeDifferentSizes =>
      isZh ? '不能合并不同页面尺寸的分组。' : 'Cannot merge groups with different page sizes.';
  String get mergingGroups => isZh ? '正在合并分组...' : 'Merging groups...';
  String get creatingGroup => isZh ? '正在新建分组...' : 'Creating group...';
  String get preparingExport => isZh ? '正在准备导出...' : 'Preparing export...';
  String get mixed => isZh ? '混合' : 'Mixed';
  String get even => isZh ? '偶数' : 'Even';
  String get odd => isZh ? '奇数' : 'Odd';
  String clusterTitle(
    String parityLabel,
    String layoutLabel,
    int pageCount,
    String samplePages,
    String suffix,
  ) {
    return isZh
        ? '$parityLabel · $layoutLabel（$pageCount页）[$samplePages$suffix]'
        : '$parityLabel · $layoutLabel ($pageCount pages) [$samplePages$suffix]';
  }

  String get mixedLayout => isZh ? '混合版式' : 'Mixed Layout';
  String get anomalyPage => isZh ? '异常页' : 'Anomalous Page';
  String get outlierSuffix => isZh ? '离群' : 'Outlier';
  String get manualSinglePage => isZh ? '手动单页' : 'Manual Single Page';
  String get manualMixedGroup => isZh ? '手动混合组' : 'Manual Mixed Group';
  String get manualGroup => isZh ? '手动分组' : 'Manual Group';
  String groupingReason({
    required String parityLabel,
    required String layoutLabel,
    required int roundedWidth,
    required int roundedHeight,
    required int pageCount,
    required bool smartGroupingApplied,
    required bool containsOutlierPage,
  }) {
    final parts = <String>[
      isZh ? '奇偶标签：$parityLabel' : 'Parity: $parityLabel',
      isZh ? '尺寸桶：$roundedWidth x $roundedHeight' : 'Size bucket: $roundedWidth x $roundedHeight',
      isZh ? '版式标签：$layoutLabel' : 'Layout label: $layoutLabel',
      isZh ? '页数：$pageCount' : 'Pages: $pageCount',
      smartGroupingApplied
          ? (isZh ? '细分方式：版式指纹智能细分' : 'Refinement: smart layout fingerprint split')
          : (isZh ? '细分方式：仅基础尺寸分组' : 'Refinement: basic size grouping only'),
    ];
    if (containsOutlierPage) {
      parts.add(
        isZh
            ? '特殊说明：该组由离群页自动拆出'
            : 'Note: this group was automatically split out as an outlier page',
      );
    }
    return parts.join('\n');
  }

  String manualGroupingReason({
    required String parityLabel,
    required int roundedWidth,
    required int roundedHeight,
    required int pageCount,
  }) {
    return [
      isZh ? '奇偶标签：$parityLabel' : 'Parity: $parityLabel',
      isZh ? '尺寸桶：$roundedWidth x $roundedHeight' : 'Size bucket: $roundedWidth x $roundedHeight',
      isZh ? '页数：$pageCount' : 'Pages: $pageCount',
      isZh ? '细分方式：手动创建分组' : 'Refinement: manually created group',
    ].join('\n');
  }

  String get writingSelectedLocation =>
      isZh ? '正在写入所选位置...' : 'Writing to the selected location...';
  String get readingSourceFile =>
      isZh ? '正在读取源文件...' : 'Reading source file...';
  String processingPage(int current, int total) => isZh
      ? '正在处理第 $current / $total 页...'
      : 'Processing page $current / $total...';
  String get generatingExportFile =>
      isZh ? '正在生成导出文件...' : 'Generating export file...';
  String get writingToDisk => isZh ? '正在写入磁盘...' : 'Writing to disk...';
  String get blankPage => isZh ? '空白页' : 'Blank Page';
  String get heavyContentPage => isZh ? '重内容页' : 'Dense Content Page';
  String get titlePage => isZh ? '标题页' : 'Title Page';
  String get headerProminent => isZh ? '页眉明显' : 'Prominent Header';
  String get footerProminent => isZh ? '页脚明显' : 'Prominent Footer';
  String get bodyPage => isZh ? '正文页' : 'Body Page';

  static String _one(double value) => value.toStringAsFixed(1);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) {
    final resolved = locale.languageCode == 'zh'
        ? const Locale('zh', 'CN')
        : const Locale('en');
    final value = AppLocalizations(resolved);
    AppLocalizations.current = value;
    return SynchronousFuture<AppLocalizations>(value);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
