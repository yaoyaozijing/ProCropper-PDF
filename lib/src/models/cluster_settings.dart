enum SmartGroupingLevel {
  basic,
  balanced,
  strict,
}

class EdgeFilterSettings {
  const EdgeFilterSettings({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  EdgeFilterSettings copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeFilterSettings(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }
}

class ClusterSettings {
  const ClusterSettings({
    this.separateOddEven = true,
    this.excludedPages = const <int>{},
    this.smartGroupingLevel = SmartGroupingLevel.balanced,
    this.edgeFilter = const EdgeFilterSettings(),
  });

  final bool separateOddEven;
  final Set<int> excludedPages;
  final SmartGroupingLevel smartGroupingLevel;
  final EdgeFilterSettings edgeFilter;

  ClusterSettings copyWith({
    bool? separateOddEven,
    Set<int>? excludedPages,
    SmartGroupingLevel? smartGroupingLevel,
    EdgeFilterSettings? edgeFilter,
  }) {
    return ClusterSettings(
      separateOddEven: separateOddEven ?? this.separateOddEven,
      excludedPages: excludedPages ?? this.excludedPages,
      smartGroupingLevel: smartGroupingLevel ?? this.smartGroupingLevel,
      edgeFilter: edgeFilter ?? this.edgeFilter,
    );
  }
}
