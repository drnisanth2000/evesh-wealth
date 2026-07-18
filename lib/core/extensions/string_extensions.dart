extension StringDisplayExtension on String {
  /// Title-cases ALL-CAPS words for display ("SMITA NISANTH" → "Smita Nisanth").
  /// Words that already contain lowercase letters are left untouched.
  String get toDisplayCase => split(' ').map((w) {
        if (w.length < 2 || w != w.toUpperCase()) return w;
        return w[0] + w.substring(1).toLowerCase();
      }).join(' ');

  /// Human-readable financial year: "FY2627" → "FY 2026–27".
  /// Non-matching strings pass through unchanged.
  String get fyDisplay {
    final m = RegExp(r'^FY(\d{2})(\d{2})$').firstMatch(this);
    if (m == null) return this;
    return 'FY 20${m.group(1)}–${m.group(2)}';
  }
}
