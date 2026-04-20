extension StringExtensions on String {
  /// Returns true if the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Returns false if the string is empty or only whitespace.
  bool get isNotBlank => !isBlank;

  /// Capitalises the first character, leaves the rest unchanged.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Converts the string to lowercase and trims whitespace.
  /// Used when storing tag names.
  String get normalised => toLowerCase().trim();

  /// Truncates to [maxLength] and appends '…' if the string exceeds it.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}

extension NullableStringExtensions on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}
