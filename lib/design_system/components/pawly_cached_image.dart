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
      errorWidget: (_, __, ___) => _PawlyNetworkImageFallback(
        imageUrl: imageUrl,
        fit: fit,
        alignment: alignment,
        cacheWidth: pixelSize,
        cacheHeight: pixelSize,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }
}

class _PawlyNetworkImageFallback extends StatelessWidget {
  const _PawlyNetworkImageFallback({
    required this.imageUrl,
    required this.fit,
    required this.alignment,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.placeholder,
    required this.errorWidget,
  });

  final String imageUrl;
  final BoxFit? fit;
  final Alignment alignment;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget Function(BuildContext context)? placeholder;
  final Widget Function(BuildContext context)? errorWidget;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      loadingBuilder: placeholder == null
          ? null
          : (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return placeholder!(context);
            },
      errorBuilder: (context, _, __) {
        return errorWidget?.call(context) ?? const SizedBox.shrink();
      },
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
