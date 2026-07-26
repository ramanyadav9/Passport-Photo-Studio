import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/source_photo.dart';

/// Raised when picking fails for a reason worth telling the user about, in
/// words they will understand — never a platform error code.
class PhotoPickerException implements Exception {
  const PhotoPickerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps image_picker so the screens never deal with platform exceptions or
/// XFile, only with ready-to-use [SourcePhoto]s.
class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Takes one photo with the camera.
  Future<List<SourcePhoto>> takePhoto(String Function() nextId) async {
    return _guard(() async {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (shot == null) return const [];
      return [await _toSourcePhoto(shot, nextId())];
    }, cameraContext: true);
  }

  /// Picks any number of photos from the gallery, so a studio can lay out
  /// several different people on one sheet in a single step.
  Future<List<SourcePhoto>> pickFromGallery(String Function() nextId) async {
    return _guard(() async {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return const [];
      return [
        for (final file in picked) await _toSourcePhoto(file, nextId()),
      ];
    }, cameraContext: false);
  }

  Future<SourcePhoto> _toSourcePhoto(XFile file, String id) async {
    final bytes = await file.readAsBytes();
    return SourcePhoto.fromBytes(id, bytes);
  }

  Future<List<SourcePhoto>> _guard(
    Future<List<SourcePhoto>> Function() action, {
    required bool cameraContext,
  }) async {
    try {
      return await action();
    } on PlatformException catch (e) {
      throw PhotoPickerException(switch (e.code) {
        'camera_access_denied' =>
          'This app needs permission to use the camera. '
              'Open Settings and allow camera access, then try again.',
        'photo_access_denied' =>
          'This app needs permission to see your photos. '
              'Open Settings and allow photo access, then try again.',
        'no_available_camera' => 'No camera was found on this device.',
        _ => cameraContext
            ? 'Could not take the photo. Please try again.'
            : 'Could not open your photos. Please try again.',
      });
    } catch (_) {
      throw const PhotoPickerException(
        'Something went wrong adding the photo. Please try again.',
      );
    }
  }
}
