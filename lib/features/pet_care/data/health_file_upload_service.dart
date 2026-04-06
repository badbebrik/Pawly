import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/models/common_models.dart';
import 'health_repository.dart';
import 'health_repository_models.dart';

class HealthFileUploadService {
  HealthFileUploadService({
    required HealthRepository healthRepository,
    required Dio uploadDio,
  })  : _healthRepository = healthRepository,
        _uploadDio = uploadDio;

  final HealthRepository _healthRepository;
  final Dio _uploadDio;

  static const supportedExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'pdf',
  ];

  Future<UploadedHealthAttachmentRef> uploadFile(
    String petId, {
    required PlatformFile file,
  }) async {
    final uploadData = await _readUploadData(file);
    final initResponse = await _healthRepository.initAttachmentUpload(
      petId,
      input: UploadHealthAttachmentInput(
        mimeType: uploadData.mimeType,
        originalFilename: uploadData.fileName,
        expectedSizeBytes: uploadData.sizeBytes,
      ),
    );

    await _uploadBinary(
      upload: initResponse.upload,
      data: uploadData.bytes,
      mimeType: uploadData.mimeType,
    );

    final confirmedFile = await _healthRepository.confirmAttachmentUpload(
      petId,
      fileId: initResponse.fileId,
      sizeBytes: uploadData.sizeBytes,
    );

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
  }) async {
    final uploaded = <UploadedHealthAttachmentRef>[];
    for (final file in files) {
      uploaded.add(await uploadFile(petId, file: file));
    }
    return uploaded;
  }

  Future<UploadedHealthAttachmentRef> uploadXFile(
    String petId, {
    required XFile file,
  }) async {
    final uploadData = await _readXFileUploadData(file);
    final initResponse = await _healthRepository.initAttachmentUpload(
      petId,
      input: UploadHealthAttachmentInput(
        mimeType: uploadData.mimeType,
        originalFilename: uploadData.fileName,
        expectedSizeBytes: uploadData.sizeBytes,
      ),
    );

    await _uploadBinary(
      upload: initResponse.upload,
      data: uploadData.bytes,
      mimeType: uploadData.mimeType,
    );

    final confirmedFile = await _healthRepository.confirmAttachmentUpload(
      petId,
      fileId: initResponse.fileId,
      sizeBytes: uploadData.sizeBytes,
    );

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
  }) async {
    final uploaded = <UploadedHealthAttachmentRef>[];
    for (final file in files) {
      uploaded.add(await uploadXFile(petId, file: file));
    }
    return uploaded;
  }

  Future<_UploadData> _readUploadData(PlatformFile file) async {
    final fileName = file.name.trim().isEmpty ? 'attachment' : file.name.trim();
    final mimeType = _resolveMimeType(fileName);
    if (mimeType == null) {
      throw StateError(
        'Поддерживаются файлы JPG, PNG, WEBP, HEIC, HEIF и PDF.',
      );
    }

    if (file.bytes != null) {
      return _UploadData(
        fileName: fileName,
        mimeType: mimeType,
        bytes: file.bytes!,
        sizeBytes: file.bytes!.length,
      );
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      throw StateError('Не удалось прочитать выбранный файл.');
    }

    final bytes = await File(path).readAsBytes();
    return _UploadData(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      sizeBytes: bytes.length,
    );
  }

  Future<_UploadData> _readXFileUploadData(XFile file) async {
    final fileName = _fileNameFromPath(file.path);
    final mimeType = _resolveMimeType(fileName);
    if (mimeType == null) {
      throw StateError(
        'Поддерживаются файлы JPG, PNG, WEBP, HEIC, HEIF и PDF.',
      );
    }

    final bytes = await file.readAsBytes();
    return _UploadData(
      fileName: fileName,
      mimeType: mimeType,
      bytes: bytes,
      sizeBytes: bytes.length,
    );
  }

  Future<void> _uploadBinary({
    required UploadInfo upload,
    required List<int> data,
    required String mimeType,
  }) {
    return _uploadDio.request<Object?>(
      _normalizeStorageUrl(upload.url),
      data: data,
      options: Options(
        method: upload.method,
        contentType: mimeType,
        headers: <String, dynamic>{
          ...upload.headers,
          Headers.contentLengthHeader: data.length,
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
    final segments = path.split(RegExp(r'[\\/]'));
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
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic')) {
      return 'image/heic';
    }
    if (lower.endsWith('.heif')) {
      return 'image/heif';
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
    required this.bytes,
    required this.sizeBytes,
  });

  final String fileName;
  final String mimeType;
  final List<int> bytes;
  final int sizeBytes;
}
