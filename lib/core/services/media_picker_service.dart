import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'image_memory_pressure.dart';

class MediaPickerService {
  MediaPickerService(this._imagePicker);

  final ImagePicker _imagePicker;

  static const int _avatarImageQuality = 85;
  static const double _avatarMaxDimension = 1600;
  static const int _attachmentImageQuality = 72;
  static const double _attachmentMaxDimension = 1280;

  Future<XFile?> pickAvatarFromGallery() {
    return _pickImage(
      source: ImageSource.gallery,
      imageQuality: _avatarImageQuality,
      maxWidth: _avatarMaxDimension,
      maxHeight: _avatarMaxDimension,
      requestFullMetadata: false,
    );
  }

  Future<XFile?> takeAvatarPhoto() {
    return _pickImage(
      source: ImageSource.camera,
      imageQuality: _avatarImageQuality,
      maxWidth: _avatarMaxDimension,
      maxHeight: _avatarMaxDimension,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
  }

  Future<List<XFile>> _pickGalleryImages() {
    return _guardPickerCall(() {
      trimDecodedImageMemory(includeLiveImages: true);
      return _imagePicker.pickMultiImage(
        imageQuality: _attachmentImageQuality,
        maxWidth: _attachmentMaxDimension,
        maxHeight: _attachmentMaxDimension,
        requestFullMetadata: false,
      );
    });
  }

  Future<List<XFile>> pickAttachmentImagesFromGallery() {
    return _pickGalleryImages();
  }

  Future<XFile?> takeAttachmentPhoto() {
    return _pickImage(
      source: ImageSource.camera,
      imageQuality: _attachmentImageQuality,
      maxWidth: _attachmentMaxDimension,
      maxHeight: _attachmentMaxDimension,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
  }

  Future<PlatformFile?> pickFile() async {
    trimDecodedImageMemory(includeLiveImages: true);
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
    trimDecodedImageMemory(includeLiveImages: true);
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
    bool requestFullMetadata = true,
  }) {
    return _guardPickerCall(() {
      trimDecodedImageMemory(includeLiveImages: true);
      return _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCameraDevice,
        requestFullMetadata: requestFullMetadata,
      );
    });
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
      _ =>
        error.message?.trim().isNotEmpty == true
            ? error.message!
            : 'Не удалось открыть камеру или галерею.',
    };
  }
}
