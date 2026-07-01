import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/error_messages.dart';
import '../../../domain/entities/capture_record.dart';
import '../../../domain/entities/draft_capture.dart';
import '../../../domain/repositories/capture_repository.dart';
import '../../../domain/services/camera_service.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/service_providers.dart';
import '../../validation/presentation/validation_screen.dart';
import 'analyzing_screen.dart';
import 'capture_screen.dart';

/// Pushes the capture screen and, once a photo is confirmed, chains the
/// analysis step (location + plate recognition), the validation screen and
/// finally persistence. Kept outside the widgets so [CaptureScreen] and
/// [ValidationScreen] stay free of navigation/business logic.
///
/// The [NavigatorState] is captured once, up front, and reused for every
/// step of the flow (capture -> analyzing -> validation -> retake ->
/// capture...) instead of re-deriving it from short-lived screen
/// [BuildContext]s, which would be unsafe once earlier screens are
/// replaced/disposed.
void openCaptureFlow(BuildContext context, WidgetRef ref) {
  _pushCapture(Navigator.of(context), ref);
}

void _pushCapture(NavigatorState navigator, WidgetRef ref) {
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => CaptureScreen(
        onPhotoConfirmed: (BuildContext ctx, String imagePath) async {
          _replaceWithAnalyzing(navigator, ref, imagePath);
        },
      ),
    ),
  );
}

void _replaceWithCapture(NavigatorState navigator, WidgetRef ref) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => CaptureScreen(
        onPhotoConfirmed: (BuildContext ctx, String imagePath) async {
          _replaceWithAnalyzing(navigator, ref, imagePath);
        },
      ),
    ),
  );
}

void _replaceWithAnalyzing(NavigatorState navigator, WidgetRef ref, String imagePath) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => AnalyzingScreen(
        imagePath: imagePath,
        onComplete: (DraftCapture draft) => _replaceWithValidation(navigator, ref, draft),
      ),
    ),
  );
}

void _replaceWithValidation(NavigatorState navigator, WidgetRef ref, DraftCapture draft) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ValidationScreen(
        draft: draft,
        onSave: (BuildContext ctx, String correctedPlate) => _saveCapture(ctx, navigator, ref, draft, correctedPlate),
        onCancel: () => navigator.popUntil((Route<dynamic> route) => route.isFirst),
        onRetake: () => _replaceWithCapture(navigator, ref),
      ),
    ),
  );
}

Future<void> _saveCapture(
  BuildContext context,
  NavigatorState navigator,
  WidgetRef ref,
  DraftCapture draft,
  String correctedPlate,
) async {
  try {
    final CameraService cameraService = ref.read(cameraServiceProvider);
    final CaptureRepository repository = ref.read(captureRepositoryProvider);
    final String thumbnailPath = await cameraService.generateThumbnail(draft.imagePath);

    final String? detectedPlate = draft.recognition?.detectedPlate;
    final String? finalCorrection =
        (correctedPlate.isEmpty || correctedPlate == detectedPlate) ? null : correctedPlate;

    final DateTime now = DateTime.now();
    final CaptureRecord record = CaptureRecord(
      id: const Uuid().v4(),
      imagePath: draft.imagePath,
      thumbnailPath: thumbnailPath,
      detectedPlate: detectedPlate ?? '',
      correctedPlate: finalCorrection,
      rawOcrText: draft.recognition?.rawOcrText ?? '',
      countryCode: draft.recognition?.countryCode ?? PlateCountry.unknown,
      confidence: draft.recognition?.confidence,
      latitude: draft.gpsPosition?.latitude,
      longitude: draft.gpsPosition?.longitude,
      gpsAccuracy: draft.gpsPosition?.accuracyMeters,
      capturedAt: draft.capturedAt,
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(record);
    navigator.popUntil((Route<dynamic> route) => route.isFirst);
  } on AppException catch (e) {
    if (context.mounted) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
    }
  }
}
