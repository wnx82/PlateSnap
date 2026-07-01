import '../../../core/constants/app_constants.dart';
import '../../../domain/services/plate_recognition_service.dart';
import 'ocr_text_cleaner.dart';

enum _Slot { digit, letter }

class _PlateFormat {
  const _PlateFormat({
    required this.country,
    required this.slots,
    required this.dashPositions,
  });

  final PlateCountry country;
  final List<_Slot> slots;

  /// Indexes (in the compact 0-based string) *after* which a dash is
  /// inserted when formatting the detected plate for display.
  final List<int> dashPositions;

  bool matchesSlotType(int index, String char) {
    final _Slot expected = slots[index];
    final bool isDigit = RegExp(r'^[0-9]$').hasMatch(char);
    return expected == _Slot.digit ? isDigit : !isDigit;
  }
}

/// Pure, side-effect-free plate detection over already-extracted OCR text.
///
/// Kept independent from the OCR engine itself (see
/// `PlateRecognitionServiceImpl`) so the format-matching and cleanup rules
/// can be unit-tested without any platform channel / ML Kit dependency.
class PlateRecognitionEngine {
  const PlateRecognitionEngine();

  static const _PlateFormat _belgian = _PlateFormat(
    country: PlateCountry.be,
    slots: <_Slot>[_Slot.digit, _Slot.letter, _Slot.letter, _Slot.letter, _Slot.digit, _Slot.digit, _Slot.digit],
    dashPositions: <int>[0, 3],
  );

  static const _PlateFormat _french = _PlateFormat(
    country: PlateCountry.fr,
    slots: <_Slot>[_Slot.letter, _Slot.letter, _Slot.digit, _Slot.digit, _Slot.digit, _Slot.letter, _Slot.letter],
    dashPositions: <int>[1, 4],
  );

  static final List<_PlateFormat> _formats = <_PlateFormat>[_belgian, _french];

  /// Analyzes [rawOcrText] (the full, unmodified OCR output) and returns the
  /// best plate match found, if any.
  PlateRecognitionResult analyzeText(String rawOcrText) {
    final List<String> candidateLines = _buildCandidateLines(rawOcrText);
    final List<PlateCandidate> matches = <PlateCandidate>[];
    final Set<String> seen = <String>{};

    for (final String line in candidateLines) {
      for (final _PlateFormat format in _formats) {
        final PlateCandidate? candidate = _tryMatch(line, format);
        if (candidate != null && seen.add(candidate.text)) {
          matches.add(candidate);
        }
      }
    }

    matches.sort((PlateCandidate a, PlateCandidate b) => b.confidence.compareTo(a.confidence));

    if (matches.isEmpty) {
      return PlateRecognitionResult(
        rawOcrText: rawOcrText,
        detectedPlate: '',
        countryCode: PlateCountry.unknown,
        confidence: null,
        candidates: const <PlateCandidate>[],
      );
    }

    final PlateCandidate best = matches.first;
    return PlateRecognitionResult(
      rawOcrText: rawOcrText,
      detectedPlate: best.text,
      countryCode: best.countryCode,
      confidence: best.confidence,
      candidates: matches,
    );
  }

  /// Builds the set of strings worth testing against a plate format: every
  /// non-empty line, plus the whole text with line breaks collapsed (OCR
  /// sometimes splits a plate across two lines).
  List<String> _buildCandidateLines(String rawOcrText) {
    final List<String> lines = rawOcrText
        .split(RegExp(r'\r?\n'))
        .map(OcrTextCleaner.stripNoise)
        .where((String l) => l.isNotEmpty)
        .toList();
    final String joined = OcrTextCleaner.stripNoise(rawOcrText.replaceAll(RegExp(r'\r?\n'), ' '));
    if (joined.isNotEmpty && !lines.contains(joined)) {
      lines.add(joined);
    }
    return lines;
  }

  PlateCandidate? _tryMatch(String line, _PlateFormat format) {
    final String compact = OcrTextCleaner.toCompact(line);
    if (compact.length != format.slots.length) {
      return null;
    }
    final bool hadDashes = line.contains('-');

    // Pass 1: strict match, no character substitution.
    if (_allSlotsMatch(compact, format)) {
      return PlateCandidate(
        text: _format(compact, format),
        countryCode: format.country,
        confidence: hadDashes ? 0.95 : 0.85,
      );
    }

    // Pass 2: attempt confusion corrections only on mismatching slots.
    final StringBuffer corrected = StringBuffer();
    int corrections = 0;
    bool correctable = true;
    for (int i = 0; i < compact.length; i++) {
      final String char = compact[i];
      if (format.matchesSlotType(i, char)) {
        corrected.write(char);
        continue;
      }
      final String? fixed = format.slots[i] == _Slot.digit
          ? OcrTextCleaner.letterLooksLikeDigit[char]
          : OcrTextCleaner.digitLooksLikeLetter[char];
      if (fixed == null) {
        correctable = false;
        break;
      }
      corrected.write(fixed);
      corrections++;
    }

    if (!correctable || corrections == 0) {
      return null;
    }

    final String correctedCompact = corrected.toString();
    final double base = hadDashes ? 0.95 : 0.85;
    final double confidence = (base - (corrections * 0.1)).clamp(0.5, base);
    return PlateCandidate(
      text: _format(correctedCompact, format),
      countryCode: format.country,
      confidence: confidence,
    );
  }

  bool _allSlotsMatch(String compact, _PlateFormat format) {
    for (int i = 0; i < compact.length; i++) {
      if (!format.matchesSlotType(i, compact[i])) {
        return false;
      }
    }
    return true;
  }

  String _format(String compact, _PlateFormat format) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < compact.length; i++) {
      buffer.write(compact[i]);
      if (format.dashPositions.contains(i) && i != compact.length - 1) {
        buffer.write('-');
      }
    }
    return buffer.toString();
  }
}
