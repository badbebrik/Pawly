import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'deep_link_navigation_state.dart';
import 'invite_deep_link_parser.dart';
import '../router/app_routes.dart';

class PawlyDeepLinkListener extends ConsumerStatefulWidget {
  const PawlyDeepLinkListener({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<PawlyDeepLinkListener> createState() =>
      _PawlyDeepLinkListenerState();
}

class _PawlyDeepLinkListenerState extends ConsumerState<PawlyDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri?>? _subscription;

  @override
  void initState() {
    super.initState();
    if (!_supportsDeepLinks) {
      return;
    }
    _appLinks = AppLinks();
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<void> _listenForDeepLinks() async {
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_, __) {},
    );
  }

  bool get _supportsDeepLinks {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  void _handleUri(Uri? uri) {
    if (!mounted || uri == null) {
      return;
    }

    final token = extractInviteToken(uri);
    if (token == null || token.isEmpty) {
      return;
    }

    final target = Uri(
      path: AppRoutes.aclInvitePreview,
      queryParameters: <String, String>{'token': token},
    ).toString();
    ref.read(pendingDeepLinkTargetProvider.notifier).setPendingTarget(target);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final currentUri = widget.router.routeInformationProvider.value.uri;
      if (currentUri.path == AppRoutes.splash) {
        return;
      }

      if (currentUri.path == AppRoutes.aclInvitePreview) {
        widget.router.go(target);
      } else {
        unawaited(widget.router.push(target));
      }
      ref.read(pendingDeepLinkTargetProvider.notifier).clear();
    });
  }
}
