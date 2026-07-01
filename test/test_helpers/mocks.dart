import 'package:mocktail/mocktail.dart';
import 'package:platesnap/domain/repositories/capture_repository.dart';
import 'package:platesnap/domain/services/camera_service.dart';
import 'package:platesnap/domain/services/export_service.dart';
import 'package:platesnap/domain/services/location_service.dart';
import 'package:platesnap/domain/services/plate_recognition_service.dart';
import 'package:platesnap/domain/services/privacy_service.dart';

class MockCaptureRepository extends Mock implements CaptureRepository {}

class MockCameraService extends Mock implements CameraService {}

class MockLocationService extends Mock implements LocationService {}

class MockPlateRecognitionService extends Mock implements PlateRecognitionService {}

class MockPrivacyService extends Mock implements PrivacyService {}

class MockExportService extends Mock implements ExportService {}
