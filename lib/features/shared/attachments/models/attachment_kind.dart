AttachmentKind detectAttachmentKind({
  required String fileType,
  String? fileName,
  String? fileUrl,
}) {
  final normalizedType = fileType.trim().toLowerCase();
  final normalizedName = (fileName ?? '').trim().toLowerCase();
  final normalizedUrl = (fileUrl ?? '').trim().toLowerCase();

  const imageMimeTypes = <String>['image/jpeg', 'image/png'];
  const imageExtensions = <String>['.jpg', '.jpeg', '.png'];

  if (imageMimeTypes.contains(normalizedType) ||
      imageExtensions.any(
        (extension) =>
            normalizedName.endsWith(extension) ||
            normalizedUrl.endsWith(extension),
      )) {
    return AttachmentKind.image;
  }

  if (normalizedType == 'application/pdf' ||
      normalizedName.endsWith('.pdf') ||
      normalizedUrl.endsWith('.pdf')) {
    return AttachmentKind.pdf;
  }

  return AttachmentKind.other;
}

enum AttachmentKind { image, pdf, other }
