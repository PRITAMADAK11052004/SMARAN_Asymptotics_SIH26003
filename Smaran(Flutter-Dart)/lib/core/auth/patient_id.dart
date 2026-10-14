import 'dart:math';

/// Human-readable, unique Patient ID generator.
///
/// Format: SMRN-XXXX-XXXX
/// Charset: 23456789ABCDEFGHJKMNPQRSTUVWXYZ (removes 0, 1, I, L, O — the
/// characters most often confused when written down or read aloud).
///
/// Example: SMRN-7K3P-9X2Q
class PatientId {
  PatientId._();

  static const String _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const String _prefix = 'SMRN';
  static const int _bodyLength = 8;
  static const int _fullNormalizedLength = 12; // SMRN + 8

  static final Random _rng = Random.secure();

  /// Generate a fresh ID like `SMRN-7K3P-9X2Q`.
  static String generate() {
    final buf = StringBuffer(_prefix);
    buf.write('-'); // ← THE FIX: hyphen after SMRN
    for (int i = 0; i < _bodyLength; i++) {
      if (i == 4) buf.write('-'); // hyphen after first 4 body chars
      buf.write(_alphabet[_rng.nextInt(_alphabet.length)]);
    }
    return buf.toString();
  }

  /// Strip spaces, hyphens, and anything that is not A-Z or 0-9.
  static String normalize(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Format an unformatted ID back to display form.
  static String formatForDisplay(String raw) {
    final n = normalize(raw);
    if (n.length != _fullNormalizedLength) return raw;
    return '${n.substring(0, 4)}-${n.substring(4, 8)}-${n.substring(8, 12)}';
  }

  /// True if the ID has the correct prefix, length, and charset.
  static bool isValid(String raw) {
    final n = normalize(raw);
    if (n.length != _fullNormalizedLength) return false;
    if (!n.startsWith(_prefix)) return false;
    for (int i = _prefix.length; i < n.length; i++) {
      if (!_alphabet.contains(n[i])) return false;
    }
    return true;
  }
}