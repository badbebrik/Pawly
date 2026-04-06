import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  MediaPickerService(this._imagePicker);

  final ImagePicker _imagePicker;

  Future<XFile?> pickImage({required ImageSource source}) {
    return _imagePicker.pickImage(source: source, imageQuality: 85);
  }

  Future<List<XFile>> pickGalleryImages() {
    return _imagePicker.pickMultiImage(imageQuality: 85);
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
}
