import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PawlyCachedImage extends StatelessWidget {
  const PawlyCachedImage({
    required this.imageUrl,
    this.fit,
    this.cacheKey,
    this.targetLogicalSize,
    this.errorWidget,
    this.placeholder,
    this.alignment = Alignment.center,
    super.key,
  });

  final String imageUrl;
  final BoxFit? fit;
  final String? cacheKey;
  final double? targetLogicalSize;
  final Widget Function(BuildContext context)? errorWidget;
  final Widget Function(BuildContext context)? placeholder;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final pixelSize = targetLogicalSize == null
        ? null
        : (targetLogicalSize! * MediaQuery.devicePixelRatioOf(context)).round();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      fit: fit,
      alignment: alignment,
      memCacheWidth: pixelSize,
      memCacheHeight: pixelSize,
      maxWidthDiskCache: pixelSize,
      maxHeightDiskCache: pixelSize,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder:
          placeholder == null ? null : (_, __) => placeholder!(context),
      errorWidget: (_, __, ___) =>
          errorWidget?.call(context) ?? const SizedBox.shrink(),
    );
  }
}

String pawlyStableImageCacheKey({
  required String scope,
  required String entityId,
  required String imageUrl,
}) {
  final uri = Uri.tryParse(imageUrl);
  final normalizedUrl = uri == null
      ? imageUrl
      : uri.replace(query: null, fragment: null).toString();
  return '$scope:$entityId:$normalizedUrl';
}
