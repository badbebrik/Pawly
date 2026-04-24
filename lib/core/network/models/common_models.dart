import 'json_parsers.dart';

class EmptyResponse {
  const EmptyResponse();

  static EmptyResponse fromJson(Object? _) => const EmptyResponse();
}

class StatusResponse {
  const StatusResponse({required this.status});

  final String status;

  factory StatusResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return StatusResponse(status: asString(json['status'], fallback: 'ok'));
  }
}

class UploadInfo {
  const UploadInfo({
    required this.method,
    required this.url,
    required this.headers,
    required this.expiresAt,
  });

  final String method;
  final String url;
  final Map<String, String> headers;
  final DateTime? expiresAt;

  factory UploadInfo.fromJson(Object? data) {
    final json = asJsonMap(data);

    return UploadInfo(
      method: asString(json['method']),
      url: asString(json['url']),
      headers: asStringMap(json['headers']),
      expiresAt: asDateTime(json['expires_at']),
    );
  }
}

class InitUploadResponse {
  const InitUploadResponse({required this.fileId, required this.upload});

  final String fileId;
  final UploadInfo upload;

  factory InitUploadResponse.fromJson(Object? data) {
    final json = asJsonMap(data);

    return InitUploadResponse(
      fileId: asString(json['file_id']),
      upload: UploadInfo.fromJson(json['upload']),
    );
  }
}

class AttachmentPayload {
  const AttachmentPayload({
    required this.fileId,
    this.fileName,
  });

  final String fileId;
  final String? fileName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'file_id': fileId,
        'file_name': fileName,
      }..removeWhere((_, dynamic value) => value == null);
}

class PagedItemsResponse<T> {
  const PagedItemsResponse({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int offset;
  final int limit;

  factory PagedItemsResponse.fromJson(
    Object? data,
    T Function(Object? item) itemDecoder,
  ) {
    final json = asJsonMap(data);
    final itemList = json['items'];

    final parsedItems = itemList is List
        ? itemList.map(itemDecoder).toList(growable: false)
        : <T>[];

    return PagedItemsResponse<T>(
      items: parsedItems,
      total: asInt(json['total']),
      offset: asInt(json['offset']),
      limit: asInt(json['limit']),
    );
  }
}
