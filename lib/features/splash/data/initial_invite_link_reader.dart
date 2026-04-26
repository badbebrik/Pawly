import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../../app/deep_links/invite_deep_link_parser.dart';

const _initialLinkTimeout = Duration(seconds: 5);

class InitialInviteLinkReader {
  const InitialInviteLinkReader();

  Future<String?> readToken() async {
    if (!_supportsDeepLinks) {
      return null;
    }

    try {
      final uri = await AppLinks()
          .getInitialLink()
          .timeout(_initialLinkTimeout, onTimeout: () => null);
      return extractInviteToken(uri);
    } catch (_) {
      return null;
    }
  }

  bool get _supportsDeepLinks {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }
}
