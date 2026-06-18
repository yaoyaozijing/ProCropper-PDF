class ClusterSettings {
  const ClusterSettings({
    this.separateOddEven = true,
    this.excludedPages = const <int>{},
  });

  final bool separateOddEven;
  final Set<int> excludedPages;

  ClusterSettings copyWith({
    bool? separateOddEven,
    Set<int>? excludedPages,
  }) {
    return ClusterSettings(
      separateOddEven: separateOddEven ?? this.separateOddEven,
      excludedPages: excludedPages ?? this.excludedPages,
    );
  }
}
