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
    debugPrint('[PawlyDeepLink][stream] init supports=$_supportsDeepLinks');
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
    debugPrint('[PawlyDeepLink][stream] subscribe');
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (error, stackTrace) {
        debugPrint('[PawlyDeepLink][stream] error=$error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  bool get _supportsDeepLinks {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  void _handleUri(Uri? uri) {
    debugPrint('[PawlyDeepLink][stream] uri=${describeInviteUri(uri)}');
    if (!mounted || uri == null) {
      debugPrint('[PawlyDeepLink][stream] skip: not mounted or null uri');
      return;
    }

    final token = extractInviteToken(uri);
    if (token == null || token.isEmpty) {
      debugPrint('[PawlyDeepLink][stream] skip: no invite token');
      return;
    }

    final target = Uri(
      path: AppRoutes.aclInvitePreview,
      queryParameters: <String, String>{'token': token},
    ).toString();
    debugPrint('[PawlyDeepLink][stream] token=${_maskToken(token)}');
    debugPrint('[PawlyDeepLink][stream] target=$target');
    ref.read(pendingDeepLinkTargetProvider.notifier).setPendingTarget(target);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        debugPrint('[PawlyDeepLink][stream] skip go: unmounted');
        return;
      }

      final currentUri = widget.router.routeInformationProvider.value.uri;
      if (currentUri.path == AppRoutes.splash) {
        debugPrint('[PawlyDeepLink][stream] defer: app is on splash');
        return;
      }

      if (currentUri.path == AppRoutes.aclInvitePreview) {
        debugPrint('[PawlyDeepLink][stream] replace preview target=$target');
        widget.router.go(target);
      } else {
        debugPrint('[PawlyDeepLink][stream] push preview target=$target');
        unawaited(widget.router.push(target));
      }
      ref.read(pendingDeepLinkTargetProvider.notifier).clear();
    });
  }
}

String _maskToken(String token) {
  if (token.length <= 8) {
    return '${token.length} chars';
  }
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}
