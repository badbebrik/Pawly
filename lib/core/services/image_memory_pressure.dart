import 'package:flutter/painting.dart';

void trimDecodedImageMemory({bool includeLiveImages = false}) {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.clear();
  if (includeLiveImages) {
    imageCache.clearLiveImages();
  }
}
