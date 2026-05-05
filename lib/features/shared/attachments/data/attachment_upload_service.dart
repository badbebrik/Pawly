import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/common_models.dart';
import '../../../../core/network/models/health_models.dart';

class AttachmentUploadService {
  AttachmentUploadService({
    required HealthApiClient healthApiClient,
    required Dio uploadDio,
  })  : _healthApiClient = healthApiClient,
        _uploadDio = uploadDio;

  final HealthApiClient _healthApiClient;
  final Dio _uploadDio;

  static const supportedExtensions = <String>['jpg', 'jpeg', 'png', 'pdf'];

  Future<UploadedHealthAttachmentRef> uploadFile(
    String petId, {
    required PlatformFile file,
    required String entityType,
  }) async {
    final uploadData = await _readUploadData(file);
    final initResponse = await _healthApiClient.initAttachmentUpload(
      petId,
      InitHealthAttachmentUploadPayload(
        mimeType: uploadData.mimeType,
        originalFilename: uploadData.fileName,
        expectedSizeBytes: uploadData.sizeBytes,
        entityType: entityType,
      ),
    );

    await _uploadBinary(
      upload: initResponse.upload,
      data: uploadData.openRead(),
      mimeType: uploadData.mimeType,
      sizeBytes: uploadData.sizeBytes,
    );

    final confirmedResponse = await _healthApiClient.confirmAttachmentUpload(
      petId,
      ConfirmHealthAttachmentUploadPayload(
        fileId: initResponse.fileId,
        sizeBytes: uploadData.sizeBytes,
      ),
    );
    final confirmedFile = confirmedResponse.file;

    return UploadedHealthAttachmentRef(
      fileId: confirmedFile.id,
      fileName: confirmedFile.originalFilename ?? uploadData.fileName,
      mimeType: confirmedFile.mimeType,
      sizeBytes: confirmedFile.sizeBytes,
    );
  }

  Future<List<UploadedHealthAttachmentRef>> uploadFiles(
    String petId, {
    required List<PlatformFile> files,
    required String entityType,
  }) async {
    final uploaded = <UploadedHealthAttachmentRef>[];
    for (final file in files) {
      uploaded.add(await uploadFile(
        petId,
        file: file,
        entityType: entityType,
      ));
    }
    return uploaded;
  }

  Future<UploadedHealthAttachmentRef> uploadXFile(
    String petId, {
    required XFile file,
    required String entityType,
  }) async {
    final uploadData = await _readXFileUploadData(file);
    final initResponse = await _healthApiClient.initAttachmentUpload(
      petId,
      InitHealthAttachmentUploadPayload(
        mimeType: uploadData.mimeType,
        originalFilename: uploadData.fileName,
        expectedSizeBytes: uploadData.sizeBytes,
        entityType: entityType,
      ),
    );

    await _uploadBinary(
      upload: initResponse.upload,
      data: uploadData.openRead(),
      mimeType: uploadData.mimeType,
      sizeBytes: uploadData.sizeBytes,
    );

    final confirmedResponse = await _healthApiClient.confirmAttachmentUpload(
      petId,
      ConfirmHealthAttachmentUploadPayload(
        fileId: initResponse.fileId,
        sizeBytes: uploadData.sizeBytes,
      ),
    );
    final confirmedFile = confirmedResponse.file;

    return UploadedHealthAttachmentRef(
      fileId: confirmedFile.id,
      fileName: confirmedFile.originalFilename ?? uploadData.fileName,
      mimeType: confirmedFile.mimeType,
      sizeBytes: confirmedFile.sizeBytes,
    );
  }

  Future<List<UploadedHealthAttachmentRef>> uploadXFiles(
    String petId, {
    required List<XFile> files,
    required String entityType,
  }) async {
    final uploaded = <UploadedHealthAttachmentRef>[];
    for (final file in files) {
      uploaded.add(await uploadXFile(
        petId,
        file: file,
        entityType: entityType,
      ));
    }
    return uploaded;
  }

  Future<_UploadData> _readUploadData(PlatformFile file) async {
    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final mimeType = _resolveMimeType(fileName);
    if (mimeType == null) {
      throw StateError('Поддерживаются файлы PNG, JPEG и PDF.');
    }

    if (file.bytes != null) {
      return _UploadData(
        fileName: fileName,
        mimeType: mimeType,
        openRead: () => Stream<List<int>>.value(file.bytes!),
        sizeBytes: file.bytes!.length,
      );
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      throw StateError('Не удалось прочитать выбранный файл.');
    }

    final ioFile = File(path);
    final sizeBytes = file.size > 0 ? file.size : await ioFile.length();
    return _UploadData(
      fileName: fileName,
      mimeType: mimeType,
      openRead: ioFile.openRead,
      sizeBytes: sizeBytes,
    );
  }

  Future<_UploadData> _readXFileUploadData(XFile file) async {
    final fileName = _fileNameFromPath(file.path);
    final mimeType = _resolveMimeType(fileName);
    if (mimeType == null) {
      throw StateError('Поддерживаются файлы PNG, JPEG и PDF.');
    }

    final sizeBytes = await file.length();
    return _UploadData(
      fileName: fileName,
      mimeType: mimeType,
      openRead: file.openRead,
      sizeBytes: sizeBytes,
    );
  }

  Future<void> _uploadBinary({
    required UploadInfo upload,
    required Stream<List<int>> data,
    required String mimeType,
    required int sizeBytes,
  }) {
    return _uploadDio.request<Object?>(
      _normalizeStorageUrl(upload.url),
      data: data,
      options: Options(
        method: upload.method,
        contentType: mimeType,
        headers: <String, dynamic>{
          ...upload.headers,
          Headers.contentLengthHeader: sizeBytes,
          if (!upload.headers.containsKey('Content-Type'))
            'Content-Type': mimeType,
        },
        responseType: ResponseType.plain,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
  }

  String _normalizeStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (uri == null || apiUri == null || uri.host != 'minio') {
      return url;
    }

    return uri.replace(host: apiUri.host).toString();
  }

  String _fileNameFromPath(String path) {
    final segments = path.replaceAll('\\', '/').split('/');
    return segments.isEmpty ? 'attachment' : segments.last;
  }

  String? _resolveMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return null;
  }
}

class UploadedHealthAttachmentRef {
  const UploadedHealthAttachmentRef({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String fileId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
}

class _UploadData {
  const _UploadData({
    required this.fileName,
    required this.mimeType,
    required this.openRead,
    required this.sizeBytes,
  });

  final String fileName;
  final String mimeType;
  final Stream<List<int>> Function() openRead;
  final int sizeBytes;
}
