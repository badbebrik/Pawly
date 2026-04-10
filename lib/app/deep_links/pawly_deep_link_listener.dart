import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';

class PawlyDeepLinkListener extends StatefulWidget {
  const PawlyDeepLinkListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<PawlyDeepLinkListener> createState() => _PawlyDeepLinkListenerState();
}

class _PawlyDeepLinkListenerState extends State<PawlyDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri?>? _subscription;
  bool _didHandleInitialUri = false;

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
    await _handleInitialUri();
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );
  }

  Future<void> _handleInitialUri() async {
    if (_didHandleInitialUri) {
      return;
    }
    _didHandleInitialUri = true;

    try {
      final uri = await _appLinks.getInitialLink();
      if (!mounted) {
        return;
      }
      _handleUri(uri);
    } catch (_) {
      return;
    }
  }

  bool get _supportsDeepLinks {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  void _handleUri(Uri? uri) {
    if (!mounted || uri == null) {
      return;
    }

    final token = _extractInviteToken(uri);
    if (token == null || token.isEmpty) {
      return;
    }

    final target = Uri(
      path: AppRoutes.aclInvitePreview,
      queryParameters: <String, String>{'token': token},
    ).toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      GoRouter.of(context).go(target);
    });
  }

  String? _extractInviteToken(Uri uri) {
    if (uri.scheme != 'pawly') {
      return null;
    }

    final host = uri.host.toLowerCase();
    final firstPath =
        uri.pathSegments.isEmpty ? '' : uri.pathSegments.first.toLowerCase();
    final isInviteLink = host == 'invite' || firstPath == 'invite';
    if (!isInviteLink) {
      return null;
    }

    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }
}
