import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  MediaPickerService(this._imagePicker);

  final ImagePicker _imagePicker;

  Future<XFile?> pickImage({required ImageSource source}) {
    return _imagePicker.pickImage(source: source, imageQuality: 85);
  }

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);

    if (result == null || result.files.isEmpty) {
      return null;
    }

    return result.files.first;
  }
}
