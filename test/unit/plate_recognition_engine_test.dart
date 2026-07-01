import 'package:flutter_test/flutter_test.dart';
import 'package:platesnap/core/constants/app_constants.dart';
import 'package:platesnap/data/services/plate/plate_recognition_engine.dart';
import 'package:platesnap/domain/services/plate_recognition_service.dart';

void main() {
  const PlateRecognitionEngine engine = PlateRecognitionEngine();

  group('Belgian plates', () {
    test('detects "1-ABC-123" with dashes', () {
      final PlateRecognitionResult result = engine.analyzeText('1-ABC-123');

      expect(result.detectedPlate, '1-ABC-123');
      expect(result.countryCode, PlateCountry.be);
      expect(result.confidence, closeTo(0.95, 0.0001));
      expect(result.rawOcrText, '1-ABC-123');
    });

    test('detects "1ABC123" without dashes and normalizes the display form', () {
      final PlateRecognitionResult result = engine.analyzeText('1ABC123');

      expect(result.detectedPlate, '1-ABC-123');
      expect(result.countryCode, PlateCountry.be);
      expect(result.confidence, closeTo(0.85, 0.0001));
    });

    test('detects "2-ABC-123"', () {
      final PlateRecognitionResult result = engine.analyzeText('2-ABC-123');

      expect(result.detectedPlate, '2-ABC-123');
      expect(result.countryCode, PlateCountry.be);
    });
  });

  group('French SIV plates', () {
    test('detects "AB-123-CD" with dashes', () {
      final PlateRecognitionResult result = engine.analyzeText('AB-123-CD');

      expect(result.detectedPlate, 'AB-123-CD');
      expect(result.countryCode, PlateCountry.fr);
      expect(result.confidence, closeTo(0.95, 0.0001));
    });

    test('detects "AB123CD" without dashes and normalizes the display form', () {
      final PlateRecognitionResult result = engine.analyzeText('AB123CD');

      expect(result.detectedPlate, 'AB-123-CD');
      expect(result.countryCode, PlateCountry.fr);
      expect(result.confidence, closeTo(0.85, 0.0001));
    });
  });

  group('No match', () {
    test('returns unknown when no known format matches', () {
      final PlateRecognitionResult result = engine.analyzeText('BONJOUR TOUT LE MONDE');

      expect(result.countryCode, PlateCountry.unknown);
      expect(result.detectedPlate, isEmpty);
      expect(result.confidence, isNull);
      expect(result.candidates, isEmpty);
      // The raw OCR text must always be preserved, even on failure.
      expect(result.rawOcrText, 'BONJOUR TOUT LE MONDE');
    });

    test('returns unknown for an empty string', () {
      final PlateRecognitionResult result = engine.analyzeText('');

      expect(result.countryCode, PlateCountry.unknown);
      expect(result.hasDetectedPlate, isFalse);
    });
  });

  group('Cleanup of whitespace and parasite characters', () {
    test('trims stray spaces and punctuation around a Belgian plate', () {
      final PlateRecognitionResult result = engine.analyzeText('  1 - ABC - 123 !!  ');

      expect(result.detectedPlate, '1-ABC-123');
      expect(result.countryCode, PlateCountry.be);
    });

    test('collapses a plate split across two OCR lines', () {
      final PlateRecognitionResult result = engine.analyzeText('AB-123\n-CD');

      expect(result.detectedPlate, 'AB-123-CD');
      expect(result.countryCode, PlateCountry.fr);
    });
  });

  group('OCR confusion corrections', () {
    test('fixes a letter misread as a digit-shaped character (B -> 8)', () {
      final PlateRecognitionResult result = engine.analyzeText('1-A8C-123');

      expect(result.detectedPlate, '1-ABC-123');
      expect(result.countryCode, PlateCountry.be);
      expect(result.confidence, lessThan(0.95));
    });

    test('fixes a digit misread as a letter-shaped character (O -> 0)', () {
      final PlateRecognitionResult result = engine.analyzeText('AB-1O3-CD');

      expect(result.detectedPlate, 'AB-103-CD');
      expect(result.countryCode, PlateCountry.fr);
    });

    test('does not over-correct: an uncorrectable mismatch yields no match', () {
      // 'AB-12X-CD': 'X' is not a digit and has no digit-confusion mapping.
      final PlateRecognitionResult result = engine.analyzeText('AB-12X-CD');

      expect(result.countryCode, PlateCountry.unknown);
    });
  });
}
