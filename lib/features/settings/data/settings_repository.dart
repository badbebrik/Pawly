import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/clients/profile_api_client.dart';
import '../../../core/network/models/profile_models.dart';

class SettingsRepository {
  SettingsRepository({
    required ProfileApiClient profileApiClient,
    required Dio uploadDio,
  })  : _profileApiClient = profileApiClient,
        _uploadDio = uploadDio;

  final ProfileApiClient _profileApiClient;
  final Dio _uploadDio;

  Future<ProfileResponse> getProfile() {
    return _profileApiClient.getMe();
  }

  Future<ProfileResponse> uploadAvatar({required XFile file}) async {
    final mimeType = _resolveImageMimeType(file.path);
    if (mimeType == null) {
      throw StateError('Поддерживаются только JPG и PNG изображения.');
    }

    final bytes = await file.readAsBytes();
    final initResponse = await _profileApiClient.initAvatarUpload(
      InitAvatarUploadPayload(
        mimeType: mimeType,
        expectedSizeBytes: bytes.length,
      ),
    );

    await _uploadDio.request<Object?>(
      _normalizeStorageUrl(initResponse.upload.url),
      data: bytes,
      options: Options(
        method: initResponse.upload.method,
        headers: <String, dynamic>{
          ...initResponse.upload.headers,
          if (!initResponse.upload.headers.containsKey('Content-Type'))
            'Content-Type': mimeType,
        },
        responseType: ResponseType.plain,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final confirmResponse = await _profileApiClient.confirmAvatarUpload(
      ConfirmAvatarUploadPayload(
        fileId: initResponse.fileId,
        sizeBytes: bytes.length,
      ),
    );

    return confirmResponse.profile;
  }

  String _normalizeStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (uri == null || apiUri == null || uri.host != 'minio') {
      return url;
    }

    return uri.replace(host: apiUri.host).toString();
  }

  String? _resolveImageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    return null;
  }
}
