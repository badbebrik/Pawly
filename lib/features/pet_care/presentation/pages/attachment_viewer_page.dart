import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../design_system/design_system.dart';
import '../models/attachment_kind.dart';
import '../models/attachment_viewer_item.dart';

class AttachmentViewerPage extends StatelessWidget {
  const AttachmentViewerPage({
    required this.title,
    required this.url,
    required this.kind,
    super.key,
  });

  final String title;
  final String url;
  final AttachmentKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind == AttachmentKind.image) {
      return AttachmentGalleryPage(
        items: <AttachmentViewerItem>[
          AttachmentViewerItem(
            title: title,
            url: url,
            kind: AttachmentKind.image,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (kind) {
        AttachmentKind.image => const SizedBox.shrink(),
        AttachmentKind.pdf => SfPdfViewer.network(url),
        AttachmentKind.other => const _AttachmentViewerError(),
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
    final frameBackground = isDark ? const Color(0xFF17232C) : PawlyColors.white;

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
                            child: Image.network(
                              item.url ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const _AttachmentViewerError(),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
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
                          borderRadius: BorderRadius.circular(PawlyRadius.lg - 1),
                          child: Image.network(
                            item.url ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: PawlySpacing.sm),
                  itemCount: widget.items.length,
                ),
              ),
          ],
        ),
      ),
    );
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
