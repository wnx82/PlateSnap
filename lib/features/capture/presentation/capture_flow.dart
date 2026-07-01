import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/draft_capture.dart';
import '../../../domain/services/location_service.dart';
import '../../../presentation/providers/service_providers.dart';
import '../../validation/presentation/validation_screen.dart';
import 'capture_screen.dart';

/// Pushes the capture screen and, once a photo is confirmed, chains the
/// location lookup and the validation screen. Kept outside the widgets so
/// [CaptureScreen] and [ValidationScreen] stay free of navigation/business
/// logic.
///
/// The [NavigatorState] is captured once, up front, and reused for every
/// step of the flow (capture -> validation -> retake -> capture...) instead
/// of re-deriving it from short-lived screen [BuildContext]s, which would be
/// unsafe once earlier screens are replaced/disposed.
void openCaptureFlow(BuildContext context, WidgetRef ref) {
  _pushCapture(Navigator.of(context), ref);
}

void _pushCapture(NavigatorState navigator, WidgetRef ref) {
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => CaptureScreen(
        onPhotoConfirmed: (BuildContext ctx, String imagePath) => _onPhotoConfirmed(navigator, ref, imagePath),
      ),
    ),
  );
}

void _replaceWithCapture(NavigatorState navigator, WidgetRef ref) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => CaptureScreen(
        onPhotoConfirmed: (BuildContext ctx, String imagePath) => _onPhotoConfirmed(navigator, ref, imagePath),
      ),
    ),
  );
}

Future<void> _onPhotoConfirmed(NavigatorState navigator, WidgetRef ref, String imagePath) async {
  final DraftCapture draft = await _buildDraftCapture(ref, imagePath);
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => ValidationScreen(
        draft: draft,
        onSave: () => navigator.popUntil((Route<dynamic> route) => route.isFirst),
        onCancel: () => navigator.popUntil((Route<dynamic> route) => route.isFirst),
        onRetake: () => _replaceWithCapture(navigator, ref),
      ),
    ),
  );
}

Future<DraftCapture> _buildDraftCapture(WidgetRef ref, String imagePath) async {
  final LocationService locationService = ref.read(locationServiceProvider);
  final DateTime capturedAt = DateTime.now();

  bool permissionDenied = false;
  String? locationError;
  GpsPosition? position;

  try {
    bool granted = await locationService.hasLocationPermission();
    if (!granted) {
      granted = await locationService.requestLocationPermission();
    }
    if (!granted) {
      permissionDenied = true;
    } else {
      position = await locationService.getCurrentPosition();
    }
  } on AppException catch (e) {
    locationError = e.details ?? e.messageKey;
  }

  return DraftCapture(
    imagePath: imagePath,
    capturedAt: capturedAt,
    gpsPosition: position,
    locationPermissionDenied: permissionDenied,
    locationError: locationError,
  );
}
