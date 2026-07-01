/// Pure text-cleaning helpers applied to raw OCR output before plate-format
/// matching. Never destructive of the original text: callers are expected to
/// keep the untouched OCR output alongside any cleaned candidate.
class OcrTextCleaner {
  const OcrTextCleaner._();

  /// Upper-cases, trims and strips characters that can't be part of a plate
  /// (parasite punctuation, symbols) while keeping letters, digits, dashes
  /// and spaces so structure can still be reasoned about downstream.
  static String stripNoise(String input) {
    final String upper = input.toUpperCase();
    final String stripped = upper.replaceAll(RegExp(r'[^A-Z0-9\-\s]'), '');
    return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Removes every non-alphanumeric character (spaces and dashes included),
  /// producing the compact form used to test "no dashes" plate variants.
  static String toCompact(String input) {
    return stripNoise(input).replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Frequent single-character OCR confusions: a letter that looks like a
  /// digit, keyed by the misread letter.
  static const Map<String, String> letterLooksLikeDigit = <String, String>{
    'O': '0',
    'I': '1',
    'B': '8',
    'S': '5',
    'Z': '2',
  };

  /// The reverse mapping: a digit that looks like a letter.
  static const Map<String, String> digitLooksLikeLetter = <String, String>{
    '0': 'O',
    '1': 'I',
    '8': 'B',
    '5': 'S',
    '2': 'Z',
  };
}
