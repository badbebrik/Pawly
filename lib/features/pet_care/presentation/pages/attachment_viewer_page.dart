import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../design_system/design_system.dart';
import '../models/attachment_kind.dart';
import '../models/attachment_viewer_item.dart';

class AttachmentViewerPage extends StatelessWidget {
  const AttachmentViewerPage({
    this.fileId,
    required this.title,
    required this.url,
    this.downloadUrl,
    required this.kind,
    super.key,
  });

  final String? fileId;
  final String title;
  final String url;
  final String? downloadUrl;
  final AttachmentKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind == AttachmentKind.image) {
      return AttachmentGalleryPage(
        items: <AttachmentViewerItem>[
          AttachmentViewerItem(
            fileId: fileId,
            title: title,
            url: url,
            downloadUrl: downloadUrl ?? url,
            kind: AttachmentKind.image,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          _DownloadAttachmentButton(
            url: downloadUrl ?? url,
            title: title,
            kind: kind,
            cacheKey: fileId == null ? null : 'pdf:$fileId',
          ),
        ],
      ),
      body: switch (kind) {
        AttachmentKind.image => const SizedBox.shrink(),
        AttachmentKind.pdf => _CachedPdfViewer(fileId: fileId, url: url),
        AttachmentKind.other => const _AttachmentViewerError(),
      },
    );
  }
}

class _CachedPdfViewer extends StatefulWidget {
  const _CachedPdfViewer({required this.fileId, required this.url});

  final String? fileId;
  final String url;

  @override
  State<_CachedPdfViewer> createState() => _CachedPdfViewerState();
}

class _CachedPdfViewerState extends State<_CachedPdfViewer> {
  late final Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = DefaultCacheManager().getSingleFile(
      widget.url,
      key: widget.fileId == null ? widget.url : 'pdf:${widget.fileId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          if (kDebugMode && snapshot.hasError) {
            debugPrint('Failed to cache PDF: ${snapshot.error}');
          }
          return const _AttachmentViewerError();
        }

        return SfPdfViewer.file(snapshot.data!);
      },
    );
  }
}

class AttachmentGalleryPage extends StatefulWidget {
  const AttachmentGalleryPage({
    required this.items,
    this.initialIndex = 0,
    super.key,
  }) : assert(items.length > 0, 'Gallery items must not be empty');

  final List<AttachmentViewerItem> items;
  final int initialIndex;

  @override
  State<AttachmentGalleryPage> createState() => _AttachmentGalleryPageState();
}

class _AttachmentGalleryPageState extends State<AttachmentGalleryPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentItem = widget.items[_currentIndex];
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark ? PawlyColors.gray900 : PawlyColors.gray100;
    final frameBackground =
        isDark ? const Color(0xFF17232C) : PawlyColors.white;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: PawlySpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              currentItem.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.items.length > 1)
              Text(
                '${_currentIndex + 1} из ${widget.items.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          _DownloadAttachmentButton(
            url: currentItem.downloadUrl ?? currentItem.url,
            title: currentItem.title,
            kind: currentItem.kind,
            cacheKey: currentItem.cacheKeyFor('download'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PawlySpacing.md,
                      PawlySpacing.xs,
                      PawlySpacing.md,
                      PawlySpacing.md,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: frameBackground,
                        borderRadius: BorderRadius.circular(PawlyRadius.xl),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.18 : 0.06,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(PawlyRadius.xl),
                        child: InteractiveViewer(
                          minScale: 0.9,
                          maxScale: 4,
                          child: Center(
                            child: PawlyCachedImage(
                              imageUrl: item.url ?? '',
                              cacheKey: item.cacheKeyFor('viewer'),
                              fit: BoxFit.contain,
                              errorWidget: (_) =>
                                  const _AttachmentViewerError(),
                              placeholder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.items.length > 1)
              SizedBox(
                height: 88,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    PawlySpacing.md,
                    0,
                    PawlySpacing.md,
                    PawlySpacing.md,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(PawlyRadius.lg),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                          color: frameBackground,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            PawlyRadius.lg - 1,
                          ),
                          child: PawlyCachedImage(
                            imageUrl: item.url ?? '',
                            cacheKey: item.cacheKeyFor('thumb'),
                            fit: BoxFit.cover,
                            errorWidget: (_) => Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: PawlySpacing.sm),
                  itemCount: widget.items.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DownloadAttachmentButton extends StatelessWidget {
  const _DownloadAttachmentButton({
    required this.url,
    required this.title,
    required this.kind,
    this.cacheKey,
  });

  final String? url;
  final String title;
  final AttachmentKind kind;
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Скачать',
      icon: const Icon(Icons.file_download_outlined),
      onPressed: () => _downloadAttachment(context),
    );
  }

  Future<void> _downloadAttachment(BuildContext context) async {
    final candidate = url?.trim();
    final uri =
        candidate == null || candidate.isEmpty ? null : Uri.tryParse(candidate);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для этого файла нет ссылки на скачивание.'),
        ),
      );
      return;
    }

    try {
      final file = await DefaultCacheManager().getSingleFile(
        candidate!,
        key: cacheKey,
      );
      if (!context.mounted) {
        return;
      }

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        <XFile>[XFile(file.path, name: title, mimeType: _shareMimeType(kind))],
        fileNameOverrides: <String>[title],
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to share attachment: $error');
      }

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось подготовить файл.')),
      );
    }
  }

  String? _shareMimeType(AttachmentKind kind) {
    return switch (kind) {
      AttachmentKind.image => 'image/*',
      AttachmentKind.pdf => 'application/pdf',
      AttachmentKind.other => null,
    };
  }
}

class _AttachmentViewerError extends StatelessWidget {
  const _AttachmentViewerError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: Text(
          'Не удалось показать вложение.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
