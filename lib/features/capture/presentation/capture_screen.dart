import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../domain/services/camera_service.dart';
import '../../../presentation/providers/service_providers.dart';

enum _CaptureStage { checkingPermission, permissionDenied, previewing, reviewing }

/// Lets the user grant camera access, frame the plate and take a photo,
/// then review it (retake or confirm) before it moves on to the next step
/// of the capture pipeline (location + recognition, wired in later
/// branches via [onPhotoConfirmed]).
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key, required this.onPhotoConfirmed});

  /// Called with the persisted photo path once the user confirms it.
  final Future<void> Function(BuildContext context, String imagePath) onPhotoConfirmed;

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  _CaptureStage _stage = _CaptureStage.checkingPermission;
  String? _reviewImagePath;
  String? _errorMessage;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _stage == _CaptureStage.previewing) {
      _initializeCamera();
    }
  }

  Future<void> _bootstrap() async {
    final CameraService cameraService = ref.read(cameraServiceProvider);
    final bool granted = await cameraService.hasCameraPermission() || await cameraService.requestCameraPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() => _stage = _CaptureStage.permissionDenied);
      return;
    }
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'no_camera_available';
          _stage = _CaptureStage.permissionDenied;
        });
        return;
      }
      final CameraDescription camera = cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _stage = _CaptureStage.previewing;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.description ?? e.code;
        _stage = _CaptureStage.permissionDenied;
      });
    }
  }

  Future<void> _takePhoto() async {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final XFile photo = await controller.takePicture();
      final CameraService cameraService = ref.read(cameraServiceProvider);
      final String persistedPath = await cameraService.persistCapturedImage(photo.path);
      if (!mounted) return;
      setState(() {
        _reviewImagePath = persistedPath;
        _stage = _CaptureStage.reviewing;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showError();
    }
  }

  void _retake() {
    setState(() {
      _reviewImagePath = null;
      _stage = _CaptureStage.previewing;
    });
  }

  void _showError() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCameraCaptureFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureTitle)),
      body: switch (_stage) {
        _CaptureStage.checkingPermission => const Center(child: CircularProgressIndicator()),
        _CaptureStage.permissionDenied => _PermissionDeniedView(errorMessage: _errorMessage, onRetry: _bootstrap),
        _CaptureStage.previewing => _buildPreview(l10n),
        _CaptureStage.reviewing => _buildReview(l10n),
      },
    );
  }

  Widget _buildPreview(AppLocalizations l10n) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        Positioned.fill(child: CameraPreview(controller)),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: FloatingActionButton.large(
            heroTag: 'shutter',
            onPressed: _isCapturing ? null : _takePhoto,
            child: _isCapturing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.camera_alt),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(AppLocalizations l10n) {
    final String? path = _reviewImagePath;
    if (path == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(child: Image.file(File(path), fit: BoxFit.contain)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retake,
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.captureRetake),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onPhotoConfirmed(context, path),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.validationSave),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.errorMessage, required this.onRetry});

  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.no_photography_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.errorCameraPermissionDenied,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: Text(l10n.captureOpenSettings),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}
