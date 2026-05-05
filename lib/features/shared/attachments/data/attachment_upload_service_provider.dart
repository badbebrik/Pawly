import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import 'attachment_upload_service.dart';

final attachmentUploadServiceProvider =
    Provider<AttachmentUploadService>((ref) {
  final healthApiClient = ref.watch(healthApiClientProvider);
  final uploadDio = ref.watch(uploadDioProvider);
  return AttachmentUploadService(
    healthApiClient: healthApiClient,
    uploadDio: uploadDio,
  );
});
