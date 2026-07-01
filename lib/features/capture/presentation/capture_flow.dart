import 'package:flutter/material.dart';

import '../../../domain/entities/draft_capture.dart';
import '../../validation/presentation/validation_screen.dart';
import 'analyzing_screen.dart';
import 'capture_screen.dart';

/// Pushes the capture screen and, once a photo is confirmed, chains the
/// analysis step (location + plate recognition) and the validation screen.
/// Kept outside the widgets so [CaptureScreen] and [ValidationScreen] stay
/// free of navigation/business logic.
///
/// The [NavigatorState] is captured once, up front, and reused for every
/// step of the flow (capture -> analyzing -> validation -> retake ->
/// capture...) instead of re-deriving it from short-lived screen
/// [BuildContext]s, which would be unsafe once earlier screens are
/// replaced/disposed.
void openCaptureFlow(BuildContext context) {
  _pushCapture(Navigator.of(context));
}

void _pushCapture(NavigatorState navigator) {
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => CaptureScreen(
        onPhotoConfirmed: (BuildContext ctx, String imagePath) async {
          _replaceWithAnalyzing(navigator, imagePath);
        },
      ),
    ),
  );
}

void _replaceWithCapture(NavigatorState navigator) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => CaptureScreen(
        onPhotoConfirmed: (BuildContext ctx, String imagePath) async {
          _replaceWithAnalyzing(navigator, imagePath);
        },
      ),
    ),
  );
}

void _replaceWithAnalyzing(NavigatorState navigator, String imagePath) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => AnalyzingScreen(
        imagePath: imagePath,
        onComplete: (DraftCapture draft) => _replaceWithValidation(navigator, draft),
      ),
    ),
  );
}

void _replaceWithValidation(NavigatorState navigator, DraftCapture draft) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ValidationScreen(
        draft: draft,
        // Persistence is wired in a later branch (local storage); for now,
        // saving simply returns to the home screen.
        onSave: (String correctedPlate) => navigator.popUntil((Route<dynamic> route) => route.isFirst),
        onCancel: () => navigator.popUntil((Route<dynamic> route) => route.isFirst),
        onRetake: () => _replaceWithCapture(navigator),
      ),
    ),
  );
}
