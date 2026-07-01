import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../domain/entities/draft_capture.dart';
import '../../../domain/services/location_service.dart';
import '../../../domain/services/plate_recognition_service.dart';
import '../../../presentation/providers/service_providers.dart';

/// Transitional screen shown right after a photo is confirmed: runs the GPS
/// lookup and the on-device plate recognition concurrently, then hands the
/// resulting [DraftCapture] back to [onComplete].
class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key, required this.imagePath, required this.onComplete});

  final String imagePath;
  final void Function(DraftCapture draft) onComplete;

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final DateTime capturedAt = DateTime.now();
    final LocationService locationService = ref.read(locationServiceProvider);
    final PlateRecognitionService plateService = ref.read(plateRecognitionServiceProvider);

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchLocation(locationService),
      _runRecognition(plateService),
    ]);

    if (!mounted) return;

    final _LocationOutcome locationOutcome = results[0] as _LocationOutcome;
    final _RecognitionOutcome recognitionOutcome = results[1] as _RecognitionOutcome;

    widget.onComplete(
      DraftCapture(
        imagePath: widget.imagePath,
        capturedAt: capturedAt,
        gpsPosition: locationOutcome.position,
        locationPermissionDenied: locationOutcome.permissionDenied,
        locationError: locationOutcome.error,
        recognition: recognitionOutcome.result,
        recognitionFailed: recognitionOutcome.failed,
      ),
    );
  }

  Future<_LocationOutcome> _fetchLocation(LocationService locationService) async {
    try {
      bool granted = await locationService.hasLocationPermission();
      if (!granted) {
        granted = await locationService.requestLocationPermission();
      }
      if (!granted) {
        return const _LocationOutcome(permissionDenied: true);
      }
      final GpsPosition? position = await locationService.getCurrentPosition();
      return _LocationOutcome(position: position);
    } on AppException catch (e) {
      return _LocationOutcome(error: e.details ?? e.messageKey);
    }
  }

  Future<_RecognitionOutcome> _runRecognition(PlateRecognitionService plateService) async {
    try {
      final PlateRecognitionResult result = await plateService.recognize(widget.imagePath);
      return _RecognitionOutcome(result: result);
    } on AppException {
      return const _RecognitionOutcome(failed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(l10n.captureAnalyzing, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.captureLocating, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LocationOutcome {
  const _LocationOutcome({this.position, this.permissionDenied = false, this.error});

  final GpsPosition? position;
  final bool permissionDenied;
  final String? error;
}

class _RecognitionOutcome {
  const _RecognitionOutcome({this.result, this.failed = false});

  final PlateRecognitionResult? result;
  final bool failed;
}
