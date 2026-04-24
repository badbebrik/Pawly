import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  MediaPickerService(this._imagePicker);

  final ImagePicker _imagePicker;

  Future<XFile?> pickAvatarFromGallery() {
    return _pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
  }

  Future<XFile?> takeAvatarPhoto() {
    return _pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  Future<List<XFile>> _pickGalleryImages() {
    return _guardPickerCall(
      () => _imagePicker.pickMultiImage(imageQuality: 85),
    );
  }

  Future<List<XFile>> pickAttachmentImagesFromGallery() {
    return _pickGalleryImages();
  }

  Future<XFile?> takeAttachmentPhoto() {
    return _pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first;
  }

  Future<List<PlatformFile>> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      withData: false,
      allowMultiple: allowMultiple,
      type: allowedExtensions == null || allowedExtensions.isEmpty
          ? FileType.any
          : FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.isEmpty) {
      return const <PlatformFile>[];
    }

    return result.files;
  }

  Future<XFile?> _pickImage({
    required ImageSource source,
    required int imageQuality,
    double? maxWidth,
    double? maxHeight,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    return _guardPickerCall(
      () => _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCameraDevice,
      ),
    );
  }

  Future<T> _guardPickerCall<T>(Future<T> Function() pick) async {
    try {
      return await pick();
    } on PlatformException catch (error) {
      throw StateError(_pickerErrorMessage(error));
    }
  }

  String _pickerErrorMessage(PlatformException error) {
    return switch (error.code) {
      'camera_access_denied' =>
        'Нет доступа к камере. Разрешите доступ к камере в настройках телефона.',
      'camera_access_restricted' =>
        'Доступ к камере ограничен настройками устройства.',
      'photo_access_denied' =>
        'Нет доступа к галерее. Разрешите доступ к фото в настройках телефона.',
      'photo_access_restricted' =>
        'Доступ к галерее ограничен настройками устройства.',
      _ => error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'Не удалось открыть камеру или галерею.',
    };
  }
}
