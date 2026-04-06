AttachmentKind detectAttachmentKind({
  required String fileType,
  String? fileName,
  String? fileUrl,
}) {
  final normalizedType = fileType.trim().toLowerCase();
  final normalizedName = (fileName ?? '').trim().toLowerCase();
  final normalizedUrl = (fileUrl ?? '').trim().toLowerCase();

  const imageMarkers = <String>[
    'image/',
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  ];

  if (imageMarkers.any(
    (marker) =>
        normalizedType.contains(marker) ||
        normalizedName.endsWith(marker) ||
        normalizedUrl.contains(marker),
  )) {
    return AttachmentKind.image;
  }

  if (normalizedType.contains('pdf') ||
      normalizedName.endsWith('.pdf') ||
      normalizedUrl.contains('.pdf')) {
    return AttachmentKind.pdf;
  }

  return AttachmentKind.other;
}

enum AttachmentKind { image, pdf, other }
