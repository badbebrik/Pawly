import 'common_models.dart';
import 'json_map.dart';
import 'json_parsers.dart';

class ProfileResponse {
  const ProfileResponse({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.avatarFileId,
    required this.avatarDownloadUrl,
    required this.locale,
    required this.timeZone,
    required this.dateFormat,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarFileId;
  final String? avatarDownloadUrl;
  final String locale;
  final String timeZone;
  final String dateFormat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileResponse.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ProfileResponse(
      userId: asString(json['user_id']),
      firstName: asNullableString(json['first_name']),
      lastName: asNullableString(json['last_name']),
      phone: asNullableString(json['phone']),
      avatarFileId: asNullableString(json['avatar_file_id']),
      avatarDownloadUrl: asNullableString(json['avatar_download_url']),
      locale: asString(json['locale']),
      timeZone: asString(json['time_zone']),
      dateFormat: asString(json['date_format']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

class UpdateProfilePayload {
  const UpdateProfilePayload({
    this.firstName,
    this.lastName,
    this.phone,
    this.locale,
    this.timeZone,
    this.dateFormat,
  });

  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? locale;
  final String? timeZone;
  final String? dateFormat;

  JsonMap toJson() {
    return <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'locale': locale,
      'time_zone': timeZone,
      'date_format': dateFormat,
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class InitAvatarUploadPayload {
  const InitAvatarUploadPayload({
    required this.mimeType,
    this.expectedSizeBytes,
  });

  final String mimeType;
  final int? expectedSizeBytes;

  JsonMap toJson() {
    return <String, dynamic>{
      'mime_type': mimeType,
      'expected_size_bytes': expectedSizeBytes,
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class ConfirmAvatarUploadPayload {
  const ConfirmAvatarUploadPayload({
    required this.fileId,
    required this.sizeBytes,
  });

  final String fileId;
  final int sizeBytes;

  JsonMap toJson() => <String, dynamic>{
        'file_id': fileId,
        'size_bytes': sizeBytes,
      };
}

class ConfirmAvatarUploadResponse {
  const ConfirmAvatarUploadResponse({required this.profile});

  final ProfileResponse profile;

  factory ConfirmAvatarUploadResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ConfirmAvatarUploadResponse(
      profile: ProfileResponse.fromJson(json['profile']),
    );
  }
}

class ProfileWithUploadResponse {
  const ProfileWithUploadResponse({
    required this.upload,
    required this.profile,
  });

  final UploadInfo upload;
  final ProfileResponse profile;
}
